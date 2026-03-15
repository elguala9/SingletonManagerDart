import 'dart:io';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;
import 'package:singleton_manager_generator/src/parser/source_parser.dart';
import 'package:singleton_manager_generator/src/generator/augmentation_generator.dart';

void main() {
  group('Integration Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('generator_integration_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should generate augmentation file for single singleton class', () {
      final dartFile = File('${tempDir.path}/service.dart');
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

      final info = parsed[0];
      final augmentationCode = AugmentationGenerator.generate(info);

      expect(augmentationCode, contains("augment class UserService implements ISingletonStandardDI {"));
      expect(augmentationCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
    });

    test('should process and generate for multiple files', () {
      final file1 = File('${tempDir.path}/user_service.dart');
      file1.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class UserService {
  @isInjected
  late DatabaseConnection db;
}

class DatabaseConnection {}
''');

      final file2 = File('${tempDir.path}/auth_service.dart');
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

      final userServiceCode = AugmentationGenerator.generate(parsed[0]);
      final authServiceCode = AugmentationGenerator.generate(parsed[1]);

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

      final info = parsed[0];
      final augmentationCode = AugmentationGenerator.generate(info);

      expect(augmentationCode, contains("augment library"));
      expect(augmentationCode, contains("augment class UserService"));
    });

    test('should handle class with no injected dependencies', () {
      final dartFile = File('${tempDir.path}/simple_service.dart');
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

      final augmentationCode = AugmentationGenerator.generate(info);

      expect(augmentationCode, contains("augment class SimpleService implements ISingletonStandardDI {"));
      expect(augmentationCode, contains("Future<void> initializeDI() async {"));
      // Should not have any field assignments
      expect(augmentationCode, isNot(contains("SingletonDIAccess.get")));
    });

    test('should handle complex dependency chain', () {
      final fileA = File('${tempDir.path}/service_a.dart');
      fileA.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class ServiceA {
  @isInjected
  late ServiceB serviceB;
}

class ServiceB {}
''');

      final fileB = File('${tempDir.path}/service_b.dart');
      fileB.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class ServiceB {
  @isInjected
  late ServiceC serviceC;
}

class ServiceC {}
''');

      final fileC = File('${tempDir.path}/service_c.dart');
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

      // Generate for all three
      final codeA = AugmentationGenerator.generate(parsed[0]);
      final codeB = AugmentationGenerator.generate(parsed[1]);
      final codeC = AugmentationGenerator.generate(parsed[2]);

      expect(codeA, contains("serviceB = SingletonDIAccess.get<ServiceB>();"));
      expect(codeB, contains("serviceC = SingletonDIAccess.get<ServiceC>();"));
      expect(codeC, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
    });

    test('should handle class with many injected fields (10+)', () {
      final dartFile = File('${tempDir.path}/service.dart');
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

      final augmentationCode = AugmentationGenerator.generate(parsed[0]);

      for (int i = 1; i <= 15; i++) {
        expect(
          augmentationCode,
          contains("service$i = SingletonDIAccess.get<Service$i>();"),
        );
      }
    });

    test('should handle files with multiple classes (some singleton, some not)', () {
      final dartFile = File('${tempDir.path}/mixed_services.dart');
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

      final augmentationCode = AugmentationGenerator.generate(parsed[0]);
      expect(augmentationCode, contains("augment class SingletonService"));
      expect(augmentationCode, contains("regular = SingletonDIAccess.get<RegularService>();"));
    });

    test('should preserve source file path in augmentation', () {
      final dartFile = File('${tempDir.path}/deep/nested/path/my_service.dart');
      dartFile.parent.createSync(recursive: true);
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

      final augmentationCode = AugmentationGenerator.generate(parsed[0]);

      // The augment library path should contain the original file path
      expect(augmentationCode, contains("augment library"));
    });

    test('should handle class with constructor and methods', () {
      final dartFile = File('${tempDir.path}/service.dart');
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

      final augmentationCode = AugmentationGenerator.generate(parsed[0]);

      expect(augmentationCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
      expect(augmentationCode, contains("logger = SingletonDIAccess.get<Logger>();"));
    });

    test('should generate valid augmentation for inheritance scenario', () {
      final dartFile = File('${tempDir.path}/service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

abstract class BaseService {
  Future<void> initializeDI();
}

@isSingleton
class ConcreteService extends BaseService {
  @isInjected
  late String configuration;

  @override
  Future<void> initializeDI() async {
    // Might have other logic here
  }
}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));

      final augmentationCode = AugmentationGenerator.generate(parsed[0]);

      expect(augmentationCode, contains("augment class ConcreteService"));
      expect(augmentationCode, contains("configuration = SingletonDIAccess.get<String>();"));
    });
  });
}
