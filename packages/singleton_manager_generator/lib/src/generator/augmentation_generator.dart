import 'package:path/path.dart' as p;

import '../model/singleton_class_info.dart';

/// Generator for augmentation files from [SingletonClassInfo].
class AugmentationGenerator {
  /// Generate the augmentation code for a [SingletonClassInfo].
  ///
  /// Returns the complete augmentation file content as a string.
  static String generate(SingletonClassInfo info) {
    final relativePath = p.relative(info.sourceFilePath).replaceAll('\\', '/');
    final injectionCode = _generateInjectionCode(info);
    final sourceImports = _extractImportsFromSource(info.sourceFileContent);

    return '''augment library '$relativePath';

import 'package:singleton_manager/singleton_manager.dart';
$sourceImports

augment class ${info.className} implements ISingletonStandardDI {
  factory ${info.className}.initializeDI() {
    final instance = ${info.className}();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
$injectionCode  }
}
''';
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

  /// Extract all import statements from the source file content.
  static String _extractImportsFromSource(String sourceContent) {
    final lines = sourceContent.split('\n');
    final imports = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('import ') || trimmed.startsWith('export ')) {
        imports.add(line);
      } else if (trimmed.isNotEmpty && !trimmed.startsWith('//')) {
        // Stop at first non-import/non-comment line
        break;
      }
    }

    return imports.isEmpty ? '' : imports.join('\n');
  }
}
