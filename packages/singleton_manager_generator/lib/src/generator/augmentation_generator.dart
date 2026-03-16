import 'package:path/path.dart' as p;

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

    return '''// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import

import '$_singletonManagerImport';
import '$sourceImport';
$extraImportsBlock
class ${info.className}DI extends ${info.className} implements ISingletonStandardDI {
  factory ${info.className}DI.initializeDI() {
    final instance = ${info.className}() as ${info.className}DI;
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
$injectionCode  }
}
''';
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
