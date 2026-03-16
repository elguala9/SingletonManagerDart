import 'dart:io';
import 'package:test/test.dart';
import 'package:singleton_manager_generator/src/parser/source_parser.dart';
import 'package:singleton_manager_generator/src/generator/augmentation_generator.dart';
import 'package:singleton_manager_generator/src/model/singleton_class_info.dart';

void main() {
  group('Integration Tests', () {
    late Directory tempDir;

    setUpAll(() {
      tempDir = Directory('test_artifacts/integration_tests');
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      tempDir.createSync(recursive: true);
    });

    setUp(() {
      // Each test creates its own subdirectories for isolation
    });

    tearDown(() {
      // Keep test_artifacts folder for inspection after tests run
    });

    test('should generate augmentation file for single singleton class', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/user_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class UserService {
  @isInjected
  late DatabaseConnection db;
}

class DatabaseConnection {}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));

      // Create corrected info with proper relative path
      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/user_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      final outputFile = File('${dir.path}/user_service_augment.dart');
      outputFile.writeAsStringSync(augmentationCode);

      expect(augmentationCode, contains("augment class UserService implements ISingletonStandardDI {"));
      expect(augmentationCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
    });

    test('should process and generate for multiple files', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final file1 = File('${dir.path}/user_service.dart');
      file1.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class UserService {
  @isInjected
  late DatabaseConnection db;
}

class DatabaseConnection {}
''');

      final file2 = File('${dir.path}/auth_service.dart');
      file2.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class AuthService {
  @isInjected
  late UserService userService;

  @isInjected
  late Logger logger;
}

class Logger {}
''');

      final parsed = SourceParser.parse([file1, file2]);
      expect(parsed, hasLength(2));

      final info0 = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/user_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final info1 = SingletonClassInfo(
        className: parsed[1].className,
        sourceFilePath: 'lib/src/auth_service.dart',
        injectedFields: parsed[1].injectedFields,
        sourceFileContent: parsed[1].sourceFileContent,
      );

      final userServiceCode = AugmentationGenerator.generate(info0);
      final authServiceCode = AugmentationGenerator.generate(info1);

      // Save generated code to files for inspection
      File('${dir.path}/user_service_augment.dart').writeAsStringSync(userServiceCode);
      File('${dir.path}/auth_service_augment.dart').writeAsStringSync(authServiceCode);

      expect(userServiceCode, contains("augment class UserService"));
      expect(userServiceCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));

      expect(authServiceCode, contains("augment class AuthService"));
      expect(authServiceCode, contains("userService = SingletonDIAccess.get<UserService>();"));
      expect(authServiceCode, contains("logger = SingletonDIAccess.get<Logger>();"));
    });

    test('should generate correct augmentation with nested directory structure', () {
      final dir = Directory('${tempDir.path}/lib/src/services');
      dir.createSync(recursive: true);

      final dartFile = File('${dir.path}/user_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class UserService {
  @isInjected
  late RepositoryService repository;
}

class RepositoryService {}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/services/user_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      final outputFile = File('${dir.path}/user_service_augment.dart');
      outputFile.writeAsStringSync(augmentationCode);

      expect(augmentationCode, contains("augment library"));
      expect(augmentationCode, contains("augment class UserService"));
    });

    test('should handle class with no injected dependencies', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/simple_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class SimpleService {
  void doWork() {}
}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));

      final info = parsed[0];
      expect(info.injectedFields, isEmpty);

      final correctedInfo = SingletonClassInfo(
        className: info.className,
        sourceFilePath: 'lib/src/simple_service.dart',
        injectedFields: info.injectedFields,
        sourceFileContent: info.sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(correctedInfo);

      // Save generated code to file for inspection
      File('${dir.path}/simple_service_augment.dart').writeAsStringSync(augmentationCode);

      expect(augmentationCode, contains("augment class SimpleService implements ISingletonStandardDI {"));
      expect(augmentationCode, contains("void initializeDI() {"));
      // Should not have any field assignments
      expect(augmentationCode, isNot(contains("SingletonDIAccess.get")));
    });

    test('should handle complex dependency chain', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final fileA = File('${dir.path}/service_a.dart');
      fileA.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class ServiceA {
  @isInjected
  late ServiceB serviceB;
}

class ServiceB {}
''');

      final fileB = File('${dir.path}/service_b.dart');
      fileB.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class ServiceB {
  @isInjected
  late ServiceC serviceC;
}

class ServiceC {}
''');

      final fileC = File('${dir.path}/service_c.dart');
      fileC.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class ServiceC {
  @isInjected
  late DatabaseConnection db;
}

class DatabaseConnection {}
''');

      final parsed = SourceParser.parse([fileA, fileB, fileC]);
      expect(parsed, hasLength(3));

      final infoA = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/service_a.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final infoB = SingletonClassInfo(
        className: parsed[1].className,
        sourceFilePath: 'lib/src/service_b.dart',
        injectedFields: parsed[1].injectedFields,
        sourceFileContent: parsed[1].sourceFileContent,
      );
      final infoC = SingletonClassInfo(
        className: parsed[2].className,
        sourceFilePath: 'lib/src/service_c.dart',
        injectedFields: parsed[2].injectedFields,
        sourceFileContent: parsed[2].sourceFileContent,
      );

      // Generate for all three
      final codeA = AugmentationGenerator.generate(infoA);
      final codeB = AugmentationGenerator.generate(infoB);
      final codeC = AugmentationGenerator.generate(infoC);

      // Save generated code to files for inspection
      File('${dir.path}/service_a_augment.dart').writeAsStringSync(codeA);
      File('${dir.path}/service_b_augment.dart').writeAsStringSync(codeB);
      File('${dir.path}/service_c_augment.dart').writeAsStringSync(codeC);

      expect(codeA, contains("serviceB = SingletonDIAccess.get<ServiceB>();"));
      expect(codeB, contains("serviceC = SingletonDIAccess.get<ServiceC>();"));
      expect(codeC, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
    });

    test('should handle class with many injected fields (10+)', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/heavy_service.dart');
      final injectedFields = <String>[];
      for (int i = 1; i <= 15; i++) {
        injectedFields.add('  @isInjected\n  late Service$i service$i;');
      }

      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class HeavyService {
${injectedFields.join('\n\n')}
}

${List.generate(15, (i) => 'class Service${i + 1} {}').join('\n')}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));
      expect(parsed[0].injectedFields, hasLength(15));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/heavy_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/heavy_service_augment.dart').writeAsStringSync(augmentationCode);

      for (int i = 1; i <= 15; i++) {
        expect(
          augmentationCode,
          contains("service$i = SingletonDIAccess.get<Service$i>();"),
        );
      }
    });

    test('should handle files with multiple classes (some singleton, some not)', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/mixed_services.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

class RegularService {
  @isInjected
  late String value; // Should be ignored
}

@isSingleton
class SingletonService {
  @isInjected
  late RegularService regular;
}

class AnotherRegular {
  void doWork() {}
}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));
      expect(parsed[0].className, 'SingletonService');
      expect(parsed[0].injectedFields, hasLength(1));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/mixed_services.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/mixed_services_augment.dart').writeAsStringSync(augmentationCode);

      expect(augmentationCode, contains("augment class SingletonService"));
      expect(augmentationCode, contains("regular = SingletonDIAccess.get<RegularService>();"));
    });

    test('should preserve source file path in augmentation', () {
      final dir = Directory('${tempDir.path}/lib/src/features/auth/services');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/my_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class MyService {
  @isInjected
  late String dependency;
}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/features/auth/services/my_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/my_service_augment.dart').writeAsStringSync(augmentationCode);

      // The augment library path should contain the original file path
      expect(augmentationCode, contains("augment library"));
    });

    test('should handle class with constructor and methods', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/complex_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class ComplexService {
  String name;

  ComplexService(this.name);

  @isInjected
  late DatabaseConnection db;

  @isInjected
  late Logger logger;

  void doWork() {
    logger.log('Working...');
  }

  Future<void> fetchData() async {
    // Uses injected dependencies
  }
}

class DatabaseConnection {}
class Logger {}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));
      expect(parsed[0].injectedFields, hasLength(2));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/complex_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/complex_service_augment.dart').writeAsStringSync(augmentationCode);

      expect(augmentationCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
      expect(augmentationCode, contains("logger = SingletonDIAccess.get<Logger>();"));
    });

    test('should generate valid augmentation for inheritance scenario', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/concrete_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

abstract class BaseService {
  void initializeDI();
}

@isSingleton
class ConcreteService extends BaseService {
  @isInjected
  late String configuration;

  @override
  void initializeDI() {
    // Might have other logic here
  }
}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/concrete_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/concrete_service_augment.dart').writeAsStringSync(augmentationCode);

      expect(augmentationCode, contains("augment class ConcreteService"));
      expect(augmentationCode, contains("configuration = SingletonDIAccess.get<String>();"));
    });

    test('should generate correct augmentation for late final fields', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/late_final_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class LateFinalService {
  @isInjected
  late final DatabaseConnection db;

  @isInjected
  late final Logger logger;
}

class DatabaseConnection {}
class Logger {}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));
      expect(parsed[0].injectedFields, hasLength(2));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/late_final_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/late_final_service_augment.dart').writeAsStringSync(augmentationCode);

      expect(augmentationCode, contains("augment class LateFinalService implements ISingletonStandardDI {"));
      expect(augmentationCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
      expect(augmentationCode, contains("logger = SingletonDIAccess.get<Logger>();"));
    });

    test('should generate augmentation for class with mixed late and late final fields', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/mixed_field_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class MixedFieldService {
  @isInjected
  late DatabaseConnection db;

  @isInjected
  late final Logger logger;

  @isInjected
  late ConfigManager config;

  @isInjected
  late final CacheService cache;
}

class DatabaseConnection {}
class Logger {}
class ConfigManager {}
class CacheService {}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));
      expect(parsed[0].injectedFields, hasLength(4));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/mixed_field_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/mixed_field_service_augment.dart').writeAsStringSync(augmentationCode);

      expect(augmentationCode, contains("augment class MixedFieldService implements ISingletonStandardDI {"));
      expect(augmentationCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
      expect(augmentationCode, contains("logger = SingletonDIAccess.get<Logger>();"));
      expect(augmentationCode, contains("config = SingletonDIAccess.get<ConfigManager>();"));
      expect(augmentationCode, contains("cache = SingletonDIAccess.get<CacheService>();"));
    });

    test('should generate correct augmentation for plain final fields', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/final_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class FinalService {
  @isInjected
  final DatabaseConnection db;

  @isInjected
  final Logger logger;
}

class DatabaseConnection {}
class Logger {}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));
      expect(parsed[0].injectedFields, hasLength(2));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/final_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/final_service_augment.dart').writeAsStringSync(augmentationCode);

      expect(augmentationCode, contains("augment class FinalService implements ISingletonStandardDI {"));
      expect(augmentationCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
      expect(augmentationCode, contains("logger = SingletonDIAccess.get<Logger>();"));
    });

    test('should generate augmentation for class with mixed late, late final, and final fields', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/all_modifiers_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class AllModifiersService {
  @isInjected
  late DatabaseConnection db;

  @isInjected
  final Logger logger;

  @isInjected
  late final ConfigManager config;

  @isInjected
  final CacheService cache;
}

class DatabaseConnection {}
class Logger {}
class ConfigManager {}
class CacheService {}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));
      expect(parsed[0].injectedFields, hasLength(4));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/all_modifiers_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final augmentationCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/all_modifiers_service_augment.dart').writeAsStringSync(augmentationCode);

      expect(augmentationCode, contains("augment class AllModifiersService implements ISingletonStandardDI {"));
      expect(augmentationCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
      expect(augmentationCode, contains("logger = SingletonDIAccess.get<Logger>();"));
      expect(augmentationCode, contains("config = SingletonDIAccess.get<ConfigManager>();"));
      expect(augmentationCode, contains("cache = SingletonDIAccess.get<CacheService>();"));
    });
  });
}
