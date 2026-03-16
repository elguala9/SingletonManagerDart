import 'package:path/path.dart' as p;

import '../model/singleton_class_info.dart';

/// Generator for DI (Dependency Injection) files from [SingletonClassInfo].
class AugmentationGenerator {
  /// Generate the DI code for a [SingletonClassInfo].
  ///
  /// Returns the complete DI file content as a string.
  static String generate(SingletonClassInfo info) {
    final sourceFileName = p.basename(info.sourceFilePath);
    final injectionCode = _generateInjectionCode(info);

    return '''// AUTO-GENERATED - DO NOT CHANGE
// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import

import 'package:singleton_manager/singleton_manager.dart';
import '$sourceFileName';

class ${info.className}DI extends ${info.className} implements ISingletonStandardDI {
  factory ${info.className}DI.initializeDI() {
    final instance = ${info.className}DI();
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

}
