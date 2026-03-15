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

    return '''augment library '$relativePath';

import 'package:singleton_manager/singleton_manager.dart';

augment class ${info.className} implements ISingletonStandardDI {
  static Future<${info.className}> create() async {
    final instance = ${info.className}();
    await instance.initializeDI();
    return instance;
  }

  @override
  Future<void> initializeDI() async {
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
}
