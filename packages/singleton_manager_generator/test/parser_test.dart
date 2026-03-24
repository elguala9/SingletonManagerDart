import 'dart:io';
import 'package:test/test.dart';
import 'package:singleton_manager_generator/src/parser/source_parser.dart';

void main() {
  group('SourceParser', () {
    late Directory tempDir;

    setUpAll(() {
      tempDir = Directory('lib/test_artifacts/parser_tests');
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

    group('parse()', () {
      test('should find @isSingleton class with single @isInjected field', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  late DatabaseConnection db;
}

class DatabaseConnection {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].className, 'MyService');
        expect(results[0].injectedFields, hasLength(1));
        expect(results[0].injectedFields[0].fieldName, 'db');
        expect(results[0].injectedFields[0].fieldType, 'DatabaseConnection');
      });

      test('should find @isSingleton class with multiple @isInjected fields', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  late DatabaseConnection db;

  @isInjected
  late Logger logger;

  @isInjected
  late ConfigManager config;
}

class DatabaseConnection {}
class Logger {}
class ConfigManager {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].className, 'MyService');
        expect(results[0].injectedFields, hasLength(3));
        expect(results[0].injectedFields[0].fieldName, 'db');
        expect(results[0].injectedFields[0].fieldType, 'DatabaseConnection');
        expect(results[0].injectedFields[1].fieldName, 'logger');
        expect(results[0].injectedFields[1].fieldType, 'Logger');
        expect(results[0].injectedFields[2].fieldName, 'config');
        expect(results[0].injectedFields[2].fieldType, 'ConfigManager');
      });

      test('should find @isSingleton class with no @isInjected fields', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  String name = 'service';

  void doSomething() {}
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].className, 'MyService');
        expect(results[0].injectedFields, isEmpty);
      });

      test('should handle multiple @isSingleton classes in single file', () {
        final dartFile = File('${tempDir.path}/services.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class ServiceA {
  @isInjected
  late ServiceB serviceB;
}

@isSingleton
class ServiceB {
  @isInjected
  late ServiceC serviceC;
}

class ServiceC {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(2));
        expect(results[0].className, 'ServiceA');
        expect(results[0].injectedFields, hasLength(1));
        expect(results[1].className, 'ServiceB');
        expect(results[1].injectedFields, hasLength(1));
      });

      test('should ignore classes without @isSingleton annotation', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

class RegularClass {
  @isInjected
  late String value;
}

@isSingleton
class SingletonClass {
  @isInjected
  late String injected;
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].className, 'SingletonClass');
      });

      test('should ignore @isInjected fields in non-singleton classes', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

class RegularClass {
  @isInjected
  late String value;
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, isEmpty);
      });

      test('should handle generic field types', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  late List<String> items;
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].injectedFields, hasLength(1));
        // Note: Generic types may be simplified to base type depending on parser
        final fieldType = results[0].injectedFields[0].fieldType;
        expect(fieldType, isNotEmpty);
      });

      test('should handle nullable field types', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  late String? optionalString;
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].injectedFields, hasLength(1));
        expect(results[0].injectedFields[0].fieldType, isNotEmpty);
      });

      test('should parse multiple files recursively', () {
        final file1 = File('${tempDir.path}/service1.dart');
        file1.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class Service1 {
  @isInjected
  late String value;
}
''');

        final dir = Directory('${tempDir.path}/subdir');
        dir.createSync();
        final file2 = File('${dir.path}/service2.dart');
        file2.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class Service2 {
  @isInjected
  late int number;
}
''');

        final results = SourceParser.parse([file1, file2]);

        expect(results, hasLength(2));
        expect(results.map((r) => r.className), contains('Service1'));
        expect(results.map((r) => r.className), contains('Service2'));
      });

      test('should handle syntax errors gracefully', () {
        final dartFile = File('${tempDir.path}/broken.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class BrokenService {
  @isInjected
  late String value  // Missing semicolon - intentional error
}
''');

        // Should not throw, just log error
        final results = SourceParser.parse([dartFile]);
        expect(results, isEmpty);
      });

      test('should handle field with late modifier', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  late DatabaseConnection db;

  @isInjected
  late Logger logger;
}

class DatabaseConnection {}
class Logger {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results[0].injectedFields, hasLength(2));
        expect(results[0].injectedFields[0].fieldName, 'db');
        expect(results[0].injectedFields[1].fieldName, 'logger');
      });

      test('should ignore field with final modifier (not late)', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  final String configValue = '';
}
''');

        final results = SourceParser.parse([dartFile]);

        // Plain final fields cannot be injected (they're not late)
        expect(results[0].injectedFields, hasLength(0));
      });

      test('should handle field with late final modifier', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  late final DatabaseConnection db;
}

class DatabaseConnection {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].className, 'MyService');
        expect(results[0].injectedFields, hasLength(1));
        expect(results[0].injectedFields[0].fieldName, 'db');
        expect(results[0].injectedFields[0].fieldType, 'DatabaseConnection');
      });

      test('should handle mix of late and late final fields', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
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

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].className, 'MyService');
        expect(results[0].injectedFields, hasLength(4));
        expect(results[0].injectedFields[0].fieldName, 'db');
        expect(results[0].injectedFields[0].fieldType, 'DatabaseConnection');
        expect(results[0].injectedFields[1].fieldName, 'logger');
        expect(results[0].injectedFields[1].fieldType, 'Logger');
        expect(results[0].injectedFields[2].fieldName, 'config');
        expect(results[0].injectedFields[2].fieldType, 'ConfigManager');
        expect(results[0].injectedFields[3].fieldName, 'cache');
        expect(results[0].injectedFields[3].fieldType, 'CacheService');
      });

      test('should handle late final fields with multiple classes', () {
        final dartFile = File('${tempDir.path}/services.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class ServiceA {
  @isInjected
  late final ServiceB serviceB;

  @isInjected
  late final Logger logger;
}

@isSingleton
class ServiceB {
  @isInjected
  late final ServiceC serviceC;
}

class ServiceC {}
class Logger {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(2));
        expect(results[0].className, 'ServiceA');
        expect(results[0].injectedFields, hasLength(2));
        expect(results[0].injectedFields[0].fieldName, 'serviceB');
        expect(results[0].injectedFields[0].fieldType, 'ServiceB');
        expect(results[0].injectedFields[1].fieldName, 'logger');
        expect(results[0].injectedFields[1].fieldType, 'Logger');
        expect(results[1].className, 'ServiceB');
        expect(results[1].injectedFields, hasLength(1));
        expect(results[1].injectedFields[0].fieldName, 'serviceC');
        expect(results[1].injectedFields[0].fieldType, 'ServiceC');
      });

      test('should ignore plain final fields', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  final DatabaseConnection db;

  @isInjected
  final Logger logger;
}

class DatabaseConnection {}
class Logger {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].className, 'MyService');
        // Plain final fields cannot be injected (they're not late)
        expect(results[0].injectedFields, hasLength(0));
      });

      test('should handle mix of late, late final, and final fields', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
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

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].className, 'MyService');
        // Only 'late' and 'late final' fields are injected, not plain 'final'
        expect(results[0].injectedFields, hasLength(2));
        expect(results[0].injectedFields[0].fieldName, 'db');
        expect(results[0].injectedFields[0].fieldType, 'DatabaseConnection');
        expect(results[0].injectedFields[1].fieldName, 'config');
        expect(results[0].injectedFields[1].fieldType, 'ConfigManager');
      });

      test('should set sourceFilePath correctly', () {
        final dartFile = File('${tempDir.path}/my_service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  late String value;
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results[0].sourceFilePath, dartFile.path);
      });
    });

    group('@isMandatoryParameter / @isOptionalParameter', () {
      test('should extract mandatory positional constructor parameter', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService(@isMandatoryParameter String apiUrl);
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].constructorParameters, hasLength(1));
        expect(results[0].constructorParameters[0].name, 'apiUrl');
        expect(results[0].constructorParameters[0].type, 'String');
        expect(results[0].constructorParameters[0].isMandatory, isTrue);
        expect(results[0].constructorParameters[0].isNamed, isFalse);
      });

      test('should extract mandatory named constructor parameter', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService({@isMandatoryParameter required String apiUrl});
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].constructorParameters, hasLength(1));
        expect(results[0].constructorParameters[0].name, 'apiUrl');
        expect(results[0].constructorParameters[0].isMandatory, isTrue);
        expect(results[0].constructorParameters[0].isNamed, isTrue);
      });

      test('should extract optional named constructor parameter', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService({@isOptionalParameter String? timeout});
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].constructorParameters, hasLength(1));
        expect(results[0].constructorParameters[0].name, 'timeout');
        expect(results[0].constructorParameters[0].type, 'String?');
        expect(results[0].constructorParameters[0].isMandatory, isFalse);
        expect(results[0].constructorParameters[0].isNamed, isTrue);
      });

      test('should extract both mandatory and optional params', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService({@isMandatoryParameter required String apiUrl, @isOptionalParameter String? timeout});
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].constructorParameters, hasLength(2));
        expect(results[0].constructorParameters[0].name, 'apiUrl');
        expect(results[0].constructorParameters[0].type, 'String');
        expect(results[0].constructorParameters[0].isMandatory, isTrue);
        expect(results[0].constructorParameters[1].name, 'timeout');
        expect(results[0].constructorParameters[1].type, 'String?');
        expect(results[0].constructorParameters[1].isMandatory, isFalse);
      });

      test('should ignore unannotated constructor parameters', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService(String name, {@isMandatoryParameter required String apiUrl});
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        // Only apiUrl has the annotation, name does not
        expect(results[0].constructorParameters, hasLength(1));
        expect(results[0].constructorParameters[0].name, 'apiUrl');
      });

      test('should return empty constructorParameters when no annotated params', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService(String name);
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].constructorParameters, isEmpty);
      });

      test('should extract multiple mandatory positional params preserving order', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService(@isMandatoryParameter String host, @isMandatoryParameter int port);
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].constructorParameters, hasLength(2));
        expect(results[0].constructorParameters[0].name, 'host');
        expect(results[0].constructorParameters[0].type, 'String');
        expect(results[0].constructorParameters[0].isMandatory, isTrue);
        expect(results[0].constructorParameters[0].isNamed, isFalse);
        expect(results[0].constructorParameters[1].name, 'port');
        expect(results[0].constructorParameters[1].type, 'int');
        expect(results[0].constructorParameters[1].isMandatory, isTrue);
        expect(results[0].constructorParameters[1].isNamed, isFalse);
      });

      test('should extract multiple optional params', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService({@isOptionalParameter String? timeout, @isOptionalParameter int? retries});
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].constructorParameters, hasLength(2));
        expect(results[0].constructorParameters[0].name, 'timeout');
        expect(results[0].constructorParameters[0].type, 'String?');
        expect(results[0].constructorParameters[0].isMandatory, isFalse);
        expect(results[0].constructorParameters[1].name, 'retries');
        expect(results[0].constructorParameters[1].type, 'int?');
        expect(results[0].constructorParameters[1].isMandatory, isFalse);
      });

      test('should not extract params from named constructors', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService();
  MyService.withUrl(@isMandatoryParameter String url);
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        // Named constructor params should be ignored — only the default constructor counts
        expect(results[0].constructorParameters, isEmpty);
      });

      test('should return empty constructorParameters for class with no constructor', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  late String value;
}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].constructorParameters, isEmpty);
        expect(results[0].injectedFields, hasLength(1));
      });

      test('should handle custom type as mandatory param', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService(@isMandatoryParameter DatabaseConfig config);
}

class DatabaseConfig {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].constructorParameters, hasLength(1));
        expect(results[0].constructorParameters[0].name, 'config');
        expect(results[0].constructorParameters[0].type, 'DatabaseConfig');
        expect(results[0].constructorParameters[0].isMandatory, isTrue);
      });

      test('should co-exist with @isInjected fields', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService({@isMandatoryParameter required String apiUrl, @isOptionalParameter String? timeout});

  @isInjected
  late Logger logger;
}

class Logger {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].constructorParameters, hasLength(2));
        expect(results[0].injectedFields, hasLength(1));
        expect(results[0].injectedFields[0].fieldName, 'logger');
      });
    });

    group('repository-like pattern', () {
      // Pattern from IdHandlerStorageRepository:
      //   - empty default constructor + named constructor with this. params
      //   - @isMandatoryParameter on a late field (not constructor param)
      //   - private late field
      //   - interface implementation

      test('should find singleton with empty default constructor and named constructor', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

abstract class IMyRepo {}

@isSingleton
class MyRepo implements IMyRepo {
  MyRepo();
  MyRepo.fromDb(this.db);

  late IWorkDb db;
}

abstract class IWorkDb {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].className, 'MyRepo');
        // Default constructor has no annotated params
        expect(results[0].constructorParameters, isEmpty);
        // No @isInjected fields
        expect(results[0].injectedFields, isEmpty);
      });

      test('should treat @isMandatoryParameter on a late field like @isInjected', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyRepo {
  MyRepo();
  MyRepo.fromDb(this.db);

  @isMandatoryParameter
  late IWorkDb db;
}

abstract class IWorkDb {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].injectedFields, hasLength(1));
        expect(results[0].injectedFields[0].fieldName, 'db');
        expect(results[0].injectedFields[0].fieldType, 'IWorkDb');
        expect(results[0].constructorParameters, isEmpty);
      });

      test('should skip private late field annotated with @isMandatoryParameter', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyRepo {
  MyRepo();

  @isMandatoryParameter
  late IWorkDb db;

  late String _collection = 'default';
}

abstract class IWorkDb {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].injectedFields, hasLength(1));
        expect(results[0].injectedFields[0].fieldName, 'db');
      });

      test('should handle full repository-like class', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

abstract class IStorageRepo {}

@isSingleton
class StorageRepo implements IStorageRepo {
  StorageRepo();
  StorageRepo.fromDb(this.db, [this._collection = _defaultCollection]);

  static const String _defaultCollection = 'items';

  @isMandatoryParameter
  late IWorkDb db;

  late String _collection = _defaultCollection;
}

abstract class IWorkDb {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        expect(results[0].className, 'StorageRepo');
        expect(results[0].injectedFields, hasLength(1));
        expect(results[0].injectedFields[0].fieldName, 'db');
        expect(results[0].injectedFields[0].fieldType, 'IWorkDb');
        // _collection is private, must be skipped
        expect(results[0].injectedFields.map((f) => f.fieldName), isNot(contains('_collection')));
        expect(results[0].constructorParameters, isEmpty);
      });

      test('should not extract params from named fromDb constructor', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyRepo {
  MyRepo();
  MyRepo.fromDb(@isMandatoryParameter this.db);

  late IWorkDb db;
}

abstract class IWorkDb {}
''');

        final results = SourceParser.parse([dartFile]);

        expect(results, hasLength(1));
        // Named constructor params are always ignored
        expect(results[0].constructorParameters, isEmpty);
      });
    });

    group('verbose output', () {
      test('should log parsed classes when verbose is true', () {
        final dartFile = File('${tempDir.path}/service.dart');
        dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  late String value;
}
''');

        // This test verifies that parsing doesn't crash with verbose=true
        // Actual log output would need to be captured with a test runner
        final results = SourceParser.parse([dartFile], verbose: true);

        expect(results, hasLength(1));
      });
    });
  });
}
