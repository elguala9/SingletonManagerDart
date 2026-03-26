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

    final optionalFields = info.injectedFields.where((f) => f.isOptional).toList();
    final initializeWithParamsFactory = (params.isNotEmpty || mandatoryFields.isNotEmpty || optionalFields.isNotEmpty)
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
      return '${info.className}DI() : super.emptyForDI()';
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
  /// Non-mandatory fields (@isInjected) are resolved from the container
  /// explicitly — initializeDI() is NOT called, to avoid fetching mandatory
  /// fields from the container when they are provided as parameters.
  static String _buildInitializeWithParamsFactory(
    SingletonClassInfo info,
    List<InjectedFieldInfo> mandatoryFields,
  ) {
    final mandatory = info.constructorParameters.where((p) => p.isMandatory).toList();
    final optional = info.constructorParameters.where((p) => !p.isMandatory).toList();

    final optionalFields = info.injectedFields.where((f) => f.isOptional).toList();

    final sigParts = <String>[];
    for (final p in mandatory) {
      sigParts.add('${p.type} ${p.name}');
    }
    // Mandatory fields come after mandatory ctor params, before optional block.
    for (final f in mandatoryFields) {
      sigParts.add('${f.fieldType} ${f.fieldName}');
    }
    // Optional ctor params + optional fields share the named block.
    final namedParts = <String>[
      ...optional.map((p) => '${p.type} ${p.name}'),
      ...optionalFields.map((f) => '${f.fieldType}? ${f.fieldName}'),
    ];
    if (namedParts.isNotEmpty) {
      sigParts.add('{${namedParts.join(', ')}}');
    }

    // Build the call to the DI constructor using original named/positional style.
    // When there are no constructor parameters, use the .emptyForDI() named constructor
    // to avoid calling the default constructor and prevent conflicts with the parent class.
    final ctorCallParts = info.constructorParameters.map((p) {
      return p.isNamed ? '${p.name}: ${p.name}' : p.name;
    }).join(', ');
    final ctorCall = info.constructorParameters.isEmpty
        ? '${info.className}DI.emptyForDI()'
        : '${info.className}DI($ctorCallParts)';

    // Inject pure @isInjected fields explicitly from the container.
    final injectedFields = info.injectedFields.where((f) => !f.isMandatory && !f.isOptional).toList();
    final injectionLines = injectedFields
        .map((f) => '    instance.${f.fieldName} = SingletonDIAccess.get<${f.fieldType}>();')
        .join('\n');
    final injectionBlock = injectionLines.isNotEmpty ? '$injectionLines\n' : '';

    // Optional fields: assign directly from parameter.
    final optionalAssignments = optionalFields
        .map((f) => '    instance.${f.fieldName} = ${f.fieldName};')
        .join('\n');
    final optionalAssignmentsBlock = optionalAssignments.isNotEmpty ? '$optionalAssignments\n' : '';

    // Assign mandatory fields from parameters.
    final fieldAssignments = mandatoryFields
        .map((f) => '    instance.${f.fieldName} = ${f.fieldName};')
        .join('\n');
    final fieldAssignmentsBlock =
        fieldAssignments.isNotEmpty ? '$fieldAssignments\n' : '';

    return '  factory ${info.className}DI.initializeWithParametersDI(${sigParts.join(', ')}) {\n'
        '    final instance = $ctorCall;\n'
        '$injectionBlock'
        '$optionalAssignmentsBlock'
        '$fieldAssignmentsBlock'
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
  ///
  /// Injects ALL annotated fields (@isInjected and @isMandatoryParameter) from
  /// the container. Mandatory fields appear here so that [initializeDI] works
  /// as a full singleton factory (all deps from container). In
  /// [initializeWithParametersDI] the mandatory fields are overridden with the
  /// explicit parameters instead.
  static String _generateInjectionCode(SingletonClassInfo info) {
    final injected = info.injectedFields;
    if (injected.isEmpty) {
      return '';
    }

    final lines = injected.map((field) {
      if (field.isOptional) {
        return '    if (SingletonDIAccess.exists<${field.fieldType}>()) ${field.fieldName} = SingletonDIAccess.get<${field.fieldType}>();';
      }
      return '    ${field.fieldName} = SingletonDIAccess.get<${field.fieldType}>();';
    }).join('\n');

    return '$lines\n';
  }
}
