import 'dart:io';
import 'package:test/test.dart';
import 'package:singleton_manager_generator/src/parser/source_parser.dart';
import 'package:singleton_manager_generator/src/generator/di_class_generator.dart';
import 'package:singleton_manager_generator/src/model/singleton_class_info.dart';

void main() {
  group('Integration Tests', () {
    late Directory tempDir;

    setUpAll(() {
      tempDir = Directory('lib/test_artifacts/integration_tests');
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

    test('should generate DI code file for single singleton class', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/user_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

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
      final diCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      final outputFile = File('${dir.path}/user_service_di.dart');
      outputFile.writeAsStringSync(diCode);

      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains('// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import'));
      expect(diCode, contains("class UserServiceDI extends UserService implements ISingletonStandardDI {"));
      expect(diCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
    });

    test('should process and generate for multiple files', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final file1 = File('${dir.path}/user_service.dart');
      file1.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class UserService {
  @isInjected
  late DatabaseConnection db;
}

class DatabaseConnection {}
''');

      final file2 = File('${dir.path}/auth_service.dart');
      file2.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

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
      File('${dir.path}/user_service_di.dart').writeAsStringSync(userServiceCode);
      File('${dir.path}/auth_service_di.dart').writeAsStringSync(authServiceCode);

      expect(userServiceCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(userServiceCode, contains("class UserServiceDI extends UserService"));
      expect(userServiceCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));

      expect(authServiceCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(authServiceCode, contains("class AuthServiceDI extends AuthService"));
      expect(authServiceCode, contains("userService = SingletonDIAccess.get<UserService>();"));
      expect(authServiceCode, contains("logger = SingletonDIAccess.get<Logger>();"));
    });

    test('should generate correct augmentation with nested directory structure', () {
      final dir = Directory('${tempDir.path}/lib/src/services');
      dir.createSync(recursive: true);

      final dartFile = File('${dir.path}/user_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

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
      final diCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      final outputFile = File('${dir.path}/user_service_di.dart');
      outputFile.writeAsStringSync(diCode);

      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains("class UserServiceDI extends UserService"));
    });

    test('should handle class with no injected dependencies', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/simple_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

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
      final diCode = AugmentationGenerator.generate(correctedInfo);

      // Save generated code to file for inspection
      File('${dir.path}/simple_service_di.dart').writeAsStringSync(diCode);

      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains("class SimpleServiceDI extends SimpleService implements ISingletonStandardDI {"));
      expect(diCode, contains("void initializeDI() {"));
      // Should not have any field assignments
      expect(diCode, isNot(contains("SingletonDIAccess.get")));
    });

    test('should handle complex dependency chain', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final fileA = File('${dir.path}/service_a.dart');
      fileA.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class ServiceA {
  @isInjected
  late ServiceB serviceB;
}

class ServiceB {}
''');

      final fileB = File('${dir.path}/service_b.dart');
      fileB.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class ServiceB {
  @isInjected
  late ServiceC serviceC;
}

class ServiceC {}
''');

      final fileC = File('${dir.path}/service_c.dart');
      fileC.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

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
      File('${dir.path}/service_a_di.dart').writeAsStringSync(codeA);
      File('${dir.path}/service_b_di.dart').writeAsStringSync(codeB);
      File('${dir.path}/service_c_di.dart').writeAsStringSync(codeC);

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
import 'package:singleton_manager/singleton_manager.dart';

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
      final diCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/heavy_service_di.dart').writeAsStringSync(diCode);

      for (int i = 1; i <= 15; i++) {
        expect(
          diCode,
          contains("service$i = SingletonDIAccess.get<Service$i>();"),
        );
      }
    });

    test('should handle files with multiple classes (some singleton, some not)', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/mixed_services.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

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
      final diCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/mixed_services_di.dart').writeAsStringSync(diCode);

      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains("class SingletonServiceDI extends SingletonService"));
      expect(diCode, contains("regular = SingletonDIAccess.get<RegularService>();"));
    });

    test('should preserve source file path in augmentation', () {
      final dir = Directory('${tempDir.path}/lib/src/features/auth/services');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/my_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

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
      final diCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/my_service_di.dart').writeAsStringSync(diCode);

      // The source file should be imported
      expect(diCode, contains("import 'my_service.dart';"));
    });

    test('should handle class with constructor and methods', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/complex_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

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
      final diCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/complex_service_di.dart').writeAsStringSync(diCode);

      expect(diCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
      expect(diCode, contains("logger = SingletonDIAccess.get<Logger>();"));
    });

    test('should generate valid augmentation for inheritance scenario', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/concrete_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

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
      final diCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/concrete_service_di.dart').writeAsStringSync(diCode);

      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains("class ConcreteServiceDI extends ConcreteService"));
      expect(diCode, contains("configuration = SingletonDIAccess.get<String>();"));
    });

    test('should generate correct augmentation for late final fields', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/late_final_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

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
      final diCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/late_final_service_di.dart').writeAsStringSync(diCode);

      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains("class LateFinalServiceDI extends LateFinalService implements ISingletonStandardDI {"));
      expect(diCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
      expect(diCode, contains("logger = SingletonDIAccess.get<Logger>();"));
    });

    test('should generate DI code for class with mixed late and late final fields', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/mixed_field_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

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
      final diCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/mixed_field_service_di.dart').writeAsStringSync(diCode);

      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains("class MixedFieldServiceDI extends MixedFieldService implements ISingletonStandardDI {"));
      expect(diCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
      expect(diCode, contains("logger = SingletonDIAccess.get<Logger>();"));
      expect(diCode, contains("config = SingletonDIAccess.get<ConfigManager>();"));
      expect(diCode, contains("cache = SingletonDIAccess.get<CacheService>();"));
    });

    test('should inject late final fields', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/final_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class FinalService {
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
      // late final fields ARE injected
      expect(parsed[0].injectedFields, hasLength(2));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/final_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final diCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/final_service_di.dart').writeAsStringSync(diCode);

      // late final fields should be injected
      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains("class FinalServiceDI extends FinalService implements ISingletonStandardDI {"));
      expect(diCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
      expect(diCode, contains("logger = SingletonDIAccess.get<Logger>();"));
    });

    test('should generate DI code for class with mixed late and late final fields', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);
      final dartFile = File('${dir.path}/all_modifiers_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class AllModifiersService {
  @isInjected
  late DatabaseConnection db;

  @isInjected
  late final ConfigManager config;

  void doSomething() {}
}

class DatabaseConnection {}
class ConfigManager {}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));
      // Both 'late' and 'late final' fields are injected
      expect(parsed[0].injectedFields, hasLength(2));
      expect(parsed[0].injectedFields[0].fieldName, 'db');
      expect(parsed[0].injectedFields[1].fieldName, 'config');

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/all_modifiers_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );
      final diCode = AugmentationGenerator.generate(info);

      // Save generated code to file for inspection
      File('${dir.path}/all_modifiers_service_di.dart').writeAsStringSync(diCode);

      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains("class AllModifiersServiceDI extends AllModifiersService implements ISingletonStandardDI {"));
      expect(diCode, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
      expect(diCode, contains("config = SingletonDIAccess.get<ConfigManager>();"));
    });

    // -----------------------------------------------------------------------
    // End-to-end: @isMandatoryParameter / @isOptionalParameter
    // -----------------------------------------------------------------------

    group('constructor parameter annotations — parse → generate', () {
      test('mandatory positional param: parser extracts it and generator emits initializeWithParametersDI', () {
        final dir = Directory('${tempDir.path}/lib/src/params');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/api_service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class ApiService {
  ApiService(@isMandatoryParameter String baseUrl);
}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        expect(parsed[0].constructorParameters, hasLength(1));
        expect(parsed[0].constructorParameters[0].name, 'baseUrl');
        expect(parsed[0].constructorParameters[0].isMandatory, isTrue);
        expect(parsed[0].constructorParameters[0].isNamed, isFalse);

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/api_service_di.dart').writeAsStringSync(diCode);

        // DI constructor forwards the param to super
        expect(diCode, contains('ApiServiceDI(String baseUrl) : super(baseUrl)'));
        // blank line before factory
        expect(diCode, contains('ApiServiceDI(String baseUrl) : super(baseUrl);\n\n  factory ApiServiceDI.initializeWithParametersDI'));
        // initializeWithParametersDI with mandatory as positional
        expect(diCode, contains('factory ApiServiceDI.initializeWithParametersDI(String baseUrl)'));
        expect(diCode, contains('final instance = ApiServiceDI(baseUrl)'));
        // No no-arg factory (would fail to compile without baseUrl)
        expect(diCode, isNot(contains('factory ApiServiceDI.initializeDI()')));
      });

      test('mandatory named param: super call uses named syntax', () {
        final dir = Directory('${tempDir.path}/lib/src/params');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/db_service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class DbService {
  DbService({@isMandatoryParameter required String connectionString});
}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        expect(parsed[0].constructorParameters[0].isNamed, isTrue);
        expect(parsed[0].constructorParameters[0].isMandatory, isTrue);

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/db_service_di.dart').writeAsStringSync(diCode);

        expect(diCode, contains('DbServiceDI({required String connectionString}) : super(connectionString: connectionString)'));
        expect(diCode, contains('factory DbServiceDI.initializeWithParametersDI(String connectionString)'));
        expect(diCode, contains('final instance = DbServiceDI(connectionString: connectionString)'));
        expect(diCode, isNot(contains('factory DbServiceDI.initializeDI()')));
      });

      test('optional named param: both initializeDI and initializeWithParametersDI are generated', () {
        final dir = Directory('${tempDir.path}/lib/src/params');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/cache_service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class CacheService {
  CacheService({@isOptionalParameter int? ttlSeconds});
}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        expect(parsed[0].constructorParameters[0].name, 'ttlSeconds');
        expect(parsed[0].constructorParameters[0].type, 'int?');
        expect(parsed[0].constructorParameters[0].isMandatory, isFalse);

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/cache_service_di.dart').writeAsStringSync(diCode);

        // No-arg factory is kept (no mandatory params)
        expect(diCode, contains('factory CacheServiceDI.initializeDI()'));
        // initializeWithParametersDI with optional as named
        expect(diCode, contains('factory CacheServiceDI.initializeWithParametersDI({int? ttlSeconds})'));
        expect(diCode, contains('CacheServiceDI({int? ttlSeconds}) : super(ttlSeconds: ttlSeconds)'));
      });

      test('mandatory + optional: correct factory signature and super call', () {
        final dir = Directory('${tempDir.path}/lib/src/params');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/http_client.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class HttpClient {
  HttpClient({
    @isMandatoryParameter required String baseUrl,
    @isOptionalParameter int? timeoutMs,
  });
}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        expect(parsed[0].constructorParameters, hasLength(2));
        expect(parsed[0].constructorParameters[0].name, 'baseUrl');
        expect(parsed[0].constructorParameters[0].type, 'String');
        expect(parsed[0].constructorParameters[0].isMandatory, isTrue);
        expect(parsed[0].constructorParameters[1].name, 'timeoutMs');
        expect(parsed[0].constructorParameters[1].type, 'int?');
        expect(parsed[0].constructorParameters[1].isMandatory, isFalse);

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/http_client_di.dart').writeAsStringSync(diCode);

        // DI constructor: named params (mirrors original)
        expect(diCode, contains('HttpClientDI({required String baseUrl, int? timeoutMs}) : super(baseUrl: baseUrl, timeoutMs: timeoutMs)'));
        // factory: mandatory=positional, optional=named
        expect(diCode, contains('factory HttpClientDI.initializeWithParametersDI(String baseUrl, {int? timeoutMs})'));
        expect(diCode, contains('final instance = HttpClientDI(baseUrl: baseUrl, timeoutMs: timeoutMs)'));
        expect(diCode, isNot(contains('factory HttpClientDI.initializeDI()')));
      });

      test('mandatory + optional + @isInjected: complete generated class', () {
        final dir = Directory('${tempDir.path}/lib/src/params');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/payment_service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class PaymentService {
  PaymentService(@isMandatoryParameter String apiKey, [@isOptionalParameter String? currency]);

  @isInjected
  late Logger logger;

  @isInjected
  late AuditRepository audit;
}

class Logger {}
class AuditRepository {}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        expect(parsed[0].constructorParameters, hasLength(2));
        expect(parsed[0].constructorParameters[0].name, 'apiKey');
        expect(parsed[0].constructorParameters[0].isMandatory, isTrue);
        expect(parsed[0].constructorParameters[1].name, 'currency');
        expect(parsed[0].constructorParameters[1].isMandatory, isFalse);
        expect(parsed[0].injectedFields, hasLength(2));

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/payment_service_di.dart').writeAsStringSync(diCode);

        // Constructor: positional mandatory + positional optional (mirrors original)
        expect(diCode, contains('PaymentServiceDI(String apiKey, String? currency) : super(apiKey, currency)'));
        // factory: mandatory=positional, optional=named
        expect(diCode, contains('factory PaymentServiceDI.initializeWithParametersDI(String apiKey, {String? currency})'));
        expect(diCode, contains('final instance = PaymentServiceDI(apiKey, currency)'));
        // @isInjected fields still injected
        expect(diCode, contains('logger = SingletonDIAccess.get<Logger>()'));
        expect(diCode, contains('audit = SingletonDIAccess.get<AuditRepository>()'));
        // No no-arg factory
        expect(diCode, isNot(contains('factory PaymentServiceDI.initializeDI()')));
      });

      // -----------------------------------------------------------------------
      // @isMandatoryParameter on late FIELDS (repository pattern)
      // -----------------------------------------------------------------------

      test('repository pattern: @isMandatoryParameter field + @isOptionalParameter ctor param + @isInjected field — initializeWithParametersDI calls initializeDI() then assigns mandatory fields', () {
        final dir = Directory('${tempDir.path}/lib/src/params');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/id_handler_storage_repository.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

abstract class IIdHandlerStorageRepository {}
abstract class IWorkDb {}
abstract class ILogger {}
abstract class IOptionalField {}
abstract class IOptionalInjected {}

@isSingleton
class IdHandlerStorageRepository implements IIdHandlerStorageRepository {
  IdHandlerStorageRepository({@isOptionalParameter String? collection});
  IdHandlerStorageRepository.fromDb(this.db);

  @isMandatoryParameter
  late IWorkDb db;

  @isInjected
  late ILogger logger;

  @isMandatoryParameter
  @isInjected
  late int test;

  @isOptionalParameter
  late IOptionalField optionalField;

  @isOptionalParameter
  @isInjected
  late IOptionalInjected optionalInjected;

  late String _collection = 'id_handler';
}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        // @isOptionalParameter on field → treated as @isInjected (isMandatory=false)
        expect(parsed[0].injectedFields, hasLength(5));
        expect(parsed[0].injectedFields[0].fieldName, 'db');
        expect(parsed[0].injectedFields[0].fieldType, 'IWorkDb');
        expect(parsed[0].injectedFields[0].isMandatory, isTrue);
        expect(parsed[0].injectedFields[1].fieldName, 'logger');
        expect(parsed[0].injectedFields[1].fieldType, 'ILogger');
        expect(parsed[0].injectedFields[1].isMandatory, isFalse);
        expect(parsed[0].injectedFields[2].fieldName, 'test');
        expect(parsed[0].injectedFields[2].fieldType, 'int');
        expect(parsed[0].injectedFields[2].isMandatory, isTrue);
        // @isOptionalParameter on field → isOptional=true
        expect(parsed[0].injectedFields[3].fieldName, 'optionalField');
        expect(parsed[0].injectedFields[3].fieldType, 'IOptionalField');
        expect(parsed[0].injectedFields[3].isMandatory, isFalse);
        expect(parsed[0].injectedFields[3].isOptional, isTrue);
        // @isOptionalParameter @isInjected on field → isOptional=true
        expect(parsed[0].injectedFields[4].fieldName, 'optionalInjected');
        expect(parsed[0].injectedFields[4].fieldType, 'IOptionalInjected');
        expect(parsed[0].injectedFields[4].isMandatory, isFalse);
        expect(parsed[0].injectedFields[4].isOptional, isTrue);
        expect(parsed[0].constructorParameters, hasLength(1));
        expect(parsed[0].constructorParameters[0].name, 'collection');
        expect(parsed[0].constructorParameters[0].isMandatory, isFalse);

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/id_handler_storage_repository_di.dart').writeAsStringSync(diCode);

        // Header
        expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
        // Class declaration
        expect(diCode, contains('class IdHandlerStorageRepositoryDI extends IdHandlerStorageRepository implements ISingletonStandardDI'));
        // Constructor mirrors optional ctor param
        expect(diCode, contains('IdHandlerStorageRepositoryDI({String? collection}) : super(collection: collection)'));
        // No-arg factory present (no mandatory ctor params, only optional)
        expect(diCode, contains('factory IdHandlerStorageRepositoryDI.initializeDI()'));
        // initializeDI injects ALL annotated fields (mandatory + non-mandatory)
        expect(diCode, contains('db = SingletonDIAccess.get<IWorkDb>()'));
        expect(diCode, contains('test = SingletonDIAccess.get<int>()'));
        expect(diCode, contains('logger = SingletonDIAccess.get<ILogger>()'));
        expect(diCode, contains('if (SingletonDIAccess.exists<IOptionalField>()) optionalField = SingletonDIAccess.get<IOptionalField>()'));
        expect(diCode, contains('if (SingletonDIAccess.exists<IOptionalInjected>()) optionalInjected = SingletonDIAccess.get<IOptionalInjected>()'));
        // Private field _collection must NOT be injected
        expect(diCode, isNot(contains('_collection')));
        // initializeWithParametersDI: mandatory positional + optional named (ctor + fields)
        expect(diCode, contains('factory IdHandlerStorageRepositoryDI.initializeWithParametersDI(IWorkDb db, int test, {String? collection, IOptionalField? optionalField, IOptionalInjected? optionalInjected})'));
        // pure @isInjected → always from container
        expect(diCode, contains('instance.logger = SingletonDIAccess.get<ILogger>()'));
        // @isOptionalParameter fields → direct assignment from parameter
        expect(diCode, contains('instance.optionalField = optionalField'));
        expect(diCode, contains('instance.optionalInjected = optionalInjected'));
        // mandatory fields from parameters
        expect(diCode, contains('instance.db = db'));
        expect(diCode, contains('instance.test = test'));
      });

      test('repository pattern: @isMandatoryParameter field + @isOptionalParameter ctor param — correct combined output', () {
        final dir = Directory('${tempDir.path}/lib/src/params');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/storage_repo.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

abstract class IWorkDb {}

@isSingleton
class StorageRepo {
  StorageRepo({@isOptionalParameter String? collection});
  StorageRepo.fromDb(this.db);

  @isMandatoryParameter
  late IWorkDb db;

  late String _collection = 'default';
}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        expect(parsed[0].injectedFields, hasLength(1));
        expect(parsed[0].injectedFields[0].fieldName, 'db');
        expect(parsed[0].constructorParameters, hasLength(1));
        expect(parsed[0].constructorParameters[0].name, 'collection');
        expect(parsed[0].constructorParameters[0].isMandatory, isFalse);

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/storage_repo_di.dart').writeAsStringSync(diCode);

        // Optional ctor param → both factories generated
        expect(diCode, contains('factory StorageRepoDI.initializeDI()'));
        // mandatory field comes before optional ctor param in factory signature
        expect(diCode, contains('factory StorageRepoDI.initializeWithParametersDI(IWorkDb db, {String? collection})'));
        expect(diCode, contains('instance.db = db'));
        // db is mandatory — also injected in initializeDI() (full singleton mode)
        expect(diCode, contains('db = SingletonDIAccess.get<IWorkDb>()'));
        expect(diCode, isNot(contains('_collection')));
      });

      test('multiple mandatory positional params end-to-end', () {
        final dir = Directory('${tempDir.path}/lib/src/params');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/smtp_service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class SmtpService {
  SmtpService(
    @isMandatoryParameter String host,
    @isMandatoryParameter int port,
    @isOptionalParameter bool? useTls,
  );
}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        expect(parsed[0].constructorParameters, hasLength(3));

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/smtp_service_di.dart').writeAsStringSync(diCode);

        expect(diCode, contains('SmtpServiceDI(String host, int port, bool? useTls) : super(host, port, useTls)'));
        expect(diCode, contains('factory SmtpServiceDI.initializeWithParametersDI(String host, int port, {bool? useTls})'));
        expect(diCode, contains('final instance = SmtpServiceDI(host, port, useTls)'));
        expect(diCode, isNot(contains('factory SmtpServiceDI.initializeDI()')));
      });
    });

    group('generic types - parse - generate', () {
      test('single generic: IRepository<BookData> is preserved in get<>', () {
        final dir = Directory('${tempDir.path}/lib/src/generic');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/book_service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class ErmesBookServiceBase {
  ErmesBookServiceBase.emptyForDI();

  @isInjected
  late IErmesBookRepository<BookData> repository;
}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        expect(parsed[0].injectedFields[0].fieldType, 'IErmesBookRepository<BookData>');

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/book_service_di.dart').writeAsStringSync(diCode);

        expect(diCode, contains('repository = SingletonDIAccess.get<IErmesBookRepository<BookData>>();'));
      });

      test('nullable generic: IRepository<BookData>? is preserved in exists<> and get<>', () {
        final dir = Directory('${tempDir.path}/lib/src/generic_nullable');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/nullable_service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class NullableService {
  NullableService.emptyForDI();

  @isOptionalParameter
  late IRepository<BookData>? repo;
}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        expect(parsed[0].injectedFields[0].fieldType, 'IRepository<BookData>?');

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/nullable_service_di.dart').writeAsStringSync(diCode);

        expect(diCode, contains('if (SingletonDIAccess.exists<IRepository<BookData>?>()) repo = SingletonDIAccess.get<IRepository<BookData>?>();'));
      });

      test('nested generic: ICache<Map<String, int>> is preserved', () {
        final dir = Directory('${tempDir.path}/lib/src/generic_nested');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/cache_service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class CacheService {
  CacheService.emptyForDI();

  @isInjected
  late ICache<Map<String, int>> cache;
}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        expect(parsed[0].injectedFields[0].fieldType, 'ICache<Map<String, int>>');

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/cache_service_di.dart').writeAsStringSync(diCode);

        expect(diCode, contains('cache = SingletonDIAccess.get<ICache<Map<String, int>>>();'));
      });

      test('multi-param generic: IMap<String, BookData> is preserved', () {
        final dir = Directory('${tempDir.path}/lib/src/generic_multi');
        dir.createSync(recursive: true);
        final dartFile = File('${dir.path}/map_service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MapService {
  MapService.emptyForDI();

  @isInjected
  late IMap<String, BookData> map;
}
''');

        final parsed = SourceParser.parse([dartFile]);
        expect(parsed, hasLength(1));
        expect(parsed[0].injectedFields[0].fieldType, 'IMap<String, BookData>');

        final diCode = AugmentationGenerator.generate(parsed[0]);
        File('${dir.path}/map_service_di.dart').writeAsStringSync(diCode);

        expect(diCode, contains('map = SingletonDIAccess.get<IMap<String, BookData>>();'));
      });
    });
  });

  group('Integration Tests - generic artifact files', () {
    const paramsDir = 'lib/test_artifacts/integration_tests/lib/src/params';

    setUpAll(() {
      Directory(paramsDir).createSync(recursive: true);
    });

    test('ErmesBookServiceBase with IErmesBookRepository<BookData>: parse → generate → write artifact', () {
      // Write source artifact to disk
      final sourceFile = File('$paramsDir/generic_book_service.dart');
      sourceFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

abstract class IErmesBookRepository<T> {}
abstract class ILogger {}
class BookData {}

@isSingleton
class ErmesBookServiceBase {
  ErmesBookServiceBase();
  ErmesBookServiceBase.emptyForDI();

  @isInjected
  late IErmesBookRepository<BookData> repository;

  @isInjected
  late ILogger logger;
}
''');

      final parsed = SourceParser.parse([sourceFile]);
      expect(parsed, hasLength(1));

      // Parser preserves generic type arguments
      expect(parsed[0].injectedFields[0].fieldName, 'repository');
      expect(parsed[0].injectedFields[0].fieldType, 'IErmesBookRepository<BookData>');
      expect(parsed[0].injectedFields[1].fieldName, 'logger');
      expect(parsed[0].injectedFields[1].fieldType, 'ILogger');

      final outputPath = '$paramsDir/generic_book_service_di.dart';
      final diCode = AugmentationGenerator.generate(parsed[0], outputFilePath: outputPath);

      // Write generated DI artifact to disk for inspection
      File(outputPath).writeAsStringSync(diCode);

      // Verify generic type is preserved end-to-end
      expect(diCode, contains('repository = SingletonDIAccess.get<IErmesBookRepository<BookData>>();'));
      expect(diCode, contains('logger = SingletonDIAccess.get<ILogger>();'));
      expect(diCode, contains("import 'generic_book_service.dart';"));
      expect(diCode, contains('class ErmesBookServiceBaseDI extends ErmesBookServiceBase implements ISingletonStandardDI'));
    });
  });
}
