import 'package:path/path.dart' as p;

import '../model/injected_field_info.dart';
import '../model/singleton_class_info.dart';

/// Generator for DI (Dependency Injection) files from [SingletonClassInfo].
class AugmentationGenerator {
  static const _singletonManagerImport =
      'package:singleton_manager/singleton_manager.dart';

  /// Generate the DI code for a [SingletonClassInfo].
  ///
  /// [outputFilePath] is the path where the generated file will be written.
  /// When provided, the import path is computed relative to that location,
  /// and relative imports from the source file are re-based accordingly.
  /// Falls back to basename when omitted.
  ///
  /// Returns the complete DI file content as a string.
  static String generate(SingletonClassInfo info, {String? outputFilePath}) {
    final String sourceImport;
    if (outputFilePath != null) {
      final relative = p.relative(
        info.sourceFilePath,
        from: p.dirname(outputFilePath),
      );
      sourceImport = relative.replaceAll(r'\', '/');
    } else {
      sourceImport = p.basename(info.sourceFilePath);
    }

    final extraImports = _buildExtraImports(info, outputFilePath);
    final extraImportsBlock =
        extraImports.isEmpty ? '' : '${extraImports.join('\n')}\n';
    final injectionCode = _generateInjectionCode(info);

    final params = info.constructorParameters;
    final hasMandatoryCtorParams = params.any((p) => p.isMandatory);
    final mandatoryFields = info.injectedFields.where((f) => f.isMandatory).toList();

    final diConstructor = _buildDIConstructorLine(info);

    // Omit the no-arg factory when mandatory ctor params exist (would be a compile error).
    final initializeDIFactory = hasMandatoryCtorParams
        ? ''
        : '  factory ${info.className}DI.initializeDI() {\n'
            '    final instance = ${info.className}DI();\n'
            '    instance.initializeDI();\n'
            '    return instance;\n'
            '  }\n';

    final initializeWithParamsFactory = (params.isNotEmpty || mandatoryFields.isNotEmpty)
        ? _buildInitializeWithParamsFactory(info, mandatoryFields)
        : '';

    // Each non-empty block is preceded by a blank line.
    final factoriesBlock = [initializeDIFactory, initializeWithParamsFactory]
        .where((b) => b.isNotEmpty)
        .map((b) => '\n$b')
        .join();

    return '''// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations
import '$_singletonManagerImport';
import '$sourceImport';
$extraImportsBlock
class ${info.className}DI extends ${info.className} implements ISingletonStandardDI {

  $diConstructor;
$factoriesBlock
  @override
  void initializeDI() {
$injectionCode  }
}
''';
  }

  /// Build the DI constructor declaration line (without trailing semicolon).
  ///
  /// If no constructor parameters are annotated, produces the classic no-arg form.
  /// Otherwise mirrors the original parameter structure so the super() call is valid.
  static String _buildDIConstructorLine(SingletonClassInfo info) {
    final params = info.constructorParameters;
    if (params.isEmpty) {
      return '${info.className}DI() : super()';
    }

    final positional = params.where((p) => !p.isNamed).toList();
    final named = params.where((p) => p.isNamed).toList();

    final sigParts = <String>[];
    for (final p in positional) {
      sigParts.add('${p.type} ${p.name}');
    }
    if (named.isNotEmpty) {
      final namedParts = named.map((p) {
        return p.isMandatory ? 'required ${p.type} ${p.name}' : '${p.type} ${p.name}';
      }).join(', ');
      sigParts.add('{$namedParts}');
    }

    final superParts = params.map((p) {
      return p.isNamed ? '${p.name}: ${p.name}' : p.name;
    }).join(', ');

    return '${info.className}DI(${sigParts.join(', ')}) : super($superParts)';
  }

  /// Build the [initializeWithParametersDI] factory.
  ///
  /// Constructor mandatory params become required positional arguments.
  /// Constructor optional params become named optional arguments.
  /// Mandatory fields (@isMandatoryParameter on field) are appended as
  /// required positional arguments and assigned directly on the instance.
  static String _buildInitializeWithParamsFactory(
    SingletonClassInfo info,
    List<InjectedFieldInfo> mandatoryFields,
  ) {
    final mandatory = info.constructorParameters.where((p) => p.isMandatory).toList();
    final optional = info.constructorParameters.where((p) => !p.isMandatory).toList();

    final sigParts = <String>[];
    for (final p in mandatory) {
      sigParts.add('${p.type} ${p.name}');
    }
    // Mandatory fields come after mandatory ctor params, before optional.
    for (final f in mandatoryFields) {
      sigParts.add('${f.fieldType} ${f.fieldName}');
    }
    if (optional.isNotEmpty) {
      final optParts = optional.map((p) => '${p.type} ${p.name}').join(', ');
      sigParts.add('{$optParts}');
    }

    // Build the call to the DI constructor using original named/positional style.
    final ctorCallParts = info.constructorParameters.map((p) {
      return p.isNamed ? '${p.name}: ${p.name}' : p.name;
    }).join(', ');

    final fieldAssignments = mandatoryFields
        .map((f) => '    instance.${f.fieldName} = ${f.fieldName};')
        .join('\n');
    final fieldAssignmentsBlock =
        fieldAssignments.isNotEmpty ? '$fieldAssignments\n' : '';

    // Call initializeDI() only when there are no mandatory fields being set
    // directly — otherwise it would overwrite them via SingletonDIAccess.get().
    final callInitialize =
        mandatoryFields.isEmpty ? '    instance.initializeDI();\n' : '';

    return '  factory ${info.className}DI.initializeWithParametersDI(${sigParts.join(', ')}) {\n'
        '    final instance = ${info.className}DI($ctorCallParts);\n'
        '$fieldAssignmentsBlock'
        '$callInitialize'
        '    return instance;\n'
        '  }\n';
  }

  /// Build the list of extra import statements derived from the source file's
  /// own imports, excluding imports already present in the generated file.
  static List<String> _buildExtraImports(
    SingletonClassInfo info,
    String? outputFilePath,
  ) {
    if (info.sourceFileImports.isEmpty) return [];

    final result = <String>[];

    for (final uri in info.sourceFileImports) {
      // Skip the singleton_manager import (already emitted above).
      if (uri == _singletonManagerImport) continue;

      if (uri.startsWith('dart:') || uri.startsWith('package:')) {
        result.add("import '$uri';");
      } else {
        // Relative import — resolve to absolute then rebase to output dir.
        final sourceDir = p.dirname(info.sourceFilePath);
        final absolute = p.normalize(p.join(sourceDir, uri));

        final String rebased;
        if (outputFilePath != null) {
          rebased = p
              .relative(absolute, from: p.dirname(outputFilePath))
              .replaceAll(r'\', '/');
        } else {
          // No output path: keep the path relative to source (best effort).
          rebased = uri;
        }
        result.add("import '$rebased';");
      }
    }

    return result;
  }

  /// Generate the field injection statements.
  static String _generateInjectionCode(SingletonClassInfo info) {
    if (info.injectedFields.isEmpty) {
      return '';
    }

    final lines = info.injectedFields.map((field) {
      return '    ${field.fieldName} = SingletonDIAccess.get<${field.fieldType}>();';
    }).join('\n');

    return '$lines\n';
  }
}
