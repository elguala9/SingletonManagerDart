import 'dart:io';
import 'package:test/test.dart';
import 'package:singleton_manager_generator/src/parser/source_parser.dart';
import 'package:singleton_manager_generator/src/generator/di_class_generator.dart';
import 'package:singleton_manager_generator/src/model/singleton_class_info.dart';

void main() {
  group('Functional Tests - DI Code Generation', () {
    late Directory tempDir;

    setUpAll(() {
      tempDir = Directory('lib/test_artifacts/functional_tests');
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
      tempDir.createSync(recursive: true);
    });

    tearDown(() {
      // Keep test_artifacts folder for inspection after tests run
    });

    test('generated DI file is valid Dart syntax', () {
      final dir = Directory('${tempDir.path}/lib');
      dir.createSync(recursive: true);

      final dartFile = File('${dir.path}/user_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class UserService {
  @isInjected
  late String apiKey;
}
''');

      // Parse and generate
      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));

      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/user_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );

      final diCode = AugmentationGenerator.generate(info);
      final augmentFile = File('${dir.path}/user_service_di.dart');
      augmentFile.writeAsStringSync(diCode);

      // Verify file exists
      expect(augmentFile.existsSync(), true);

      // Verify it's valid Dart by checking syntax
      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains('// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import'));
      expect(diCode, contains('class UserServiceDI'));
      expect(diCode, contains('factory UserServiceDI.initializeDI()'));
      expect(diCode, contains('implements ISingletonStandardDI'));
    });

    test('generated factory method has correct signature', () {
      final dir = Directory('${tempDir.path}/lib/src');
      dir.createSync(recursive: true);

      final dartFile = File('${dir.path}/config_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class ConfigService {
  @isInjected
  late String environment;

  @isInjected
  late int timeout;
}
''');

      final parsed = SourceParser.parse([dartFile]);
      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/src/config_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );

      final diCode = AugmentationGenerator.generate(info);
      final augmentFile = File('${dir.path}/config_service_di.dart');
      augmentFile.writeAsStringSync(diCode);

      // Verify factory signature
      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains('factory ConfigServiceDI.initializeDI() {'));
      expect(diCode, contains('final instance = ConfigServiceDI();'));
      expect(diCode, contains('instance.initializeDI();'));
      expect(diCode, contains('return instance;'));
    });

    test('generated initializeDI method initializes all fields', () {
      final dir = Directory('${tempDir.path}/lib/services');
      dir.createSync(recursive: true);

      final dartFile = File('${dir.path}/payment_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class PaymentService {
  @isInjected
  late String gatewayKey;

  @isInjected
  late String merchantId;

  @isInjected
  late int port;

  @isInjected
  late bool debugMode;
}
''');

      final parsed = SourceParser.parse([dartFile]);
      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/services/payment_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );

      final diCode = AugmentationGenerator.generate(info);

      // Verify all fields are initialized
      expect(diCode, contains('gatewayKey = SingletonDIAccess.get<String>()'));
      expect(diCode, contains('merchantId = SingletonDIAccess.get<String>()'));
      expect(diCode, contains('port = SingletonDIAccess.get<int>()'));
      expect(diCode, contains('debugMode = SingletonDIAccess.get<bool>()'));
    });

    test('multiple classes generate separate augment files with correct names', () {
      final dir = Directory('${tempDir.path}/lib/multi');
      dir.createSync(recursive: true);

      final file1 = File('${dir.path}/service_one.dart');
      file1.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class ServiceOne {
  @isInjected
  late String value;
}
''');

      final file2 = File('${dir.path}/service_two.dart');
      file2.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class ServiceTwo {
  @isInjected
  late int number;
}
''');

      final parsed = SourceParser.parse([file1, file2]);
      expect(parsed, hasLength(2));

      // Generate augment files
      for (final info in parsed) {
        final baseName = info.sourceFilePath.split('/').last.split('.dart')[0];
        final diCode = AugmentationGenerator.generate(info);
        final augmentFile = File('${dir.path}/${baseName}_di.dart');
        augmentFile.writeAsStringSync(diCode);

        expect(augmentFile.existsSync(), true);
        expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
        expect(diCode, contains('class'));
      }

      // Verify both files exist with correct names
      expect(File('${dir.path}/service_one_di.dart').existsSync(), true);
      expect(File('${dir.path}/service_two_di.dart').existsSync(), true);
    });

    test('generated code has correct imports', () {
      final dir = Directory('${tempDir.path}/lib/imports');
      dir.createSync(recursive: true);

      final dartFile = File('${dir.path}/database_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class DatabaseService {
  @isInjected
  late String connectionString;
}
''');

      final parsed = SourceParser.parse([dartFile]);
      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/imports/database_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );

      final diCode = AugmentationGenerator.generate(info);

      // Verify required imports are present
      expect(diCode, contains("// AUTO-GENERATED - DO NOT CHANGE"));
      expect(diCode, contains("import 'package:singleton_manager/singleton_manager.dart';"));
      // Verify no duplicate imports (should appear only once)
      expect(diCode.split("import 'package:singleton_manager/singleton_manager.dart';"), hasLength(2));
    });

    test('generated augment library path is correct', () {
      final dir = Directory('${tempDir.path}/lib/paths');
      dir.createSync(recursive: true);

      final dartFile = File('${dir.path}/path_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class PathService {
  @isInjected
  late String basePath;
}
''');

      final parsed = SourceParser.parse([dartFile]);
      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/paths/path_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );

      final diCode = AugmentationGenerator.generate(info);

      // Verify source file is imported
      expect(diCode, contains("import 'path_service.dart';"));
    });

    test('generated code structure is complete and valid', () {
      final dir = Directory('${tempDir.path}/lib/complete');
      dir.createSync(recursive: true);

      final dartFile = File('${dir.path}/complete_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class CompleteService {
  @isInjected
  late String param1;

  @isInjected
  late String param2;
}
''');

      final parsed = SourceParser.parse([dartFile]);
      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/complete/complete_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );

      final diCode = AugmentationGenerator.generate(info);
      final augmentFile = File('${dir.path}/complete_service_di.dart');
      augmentFile.writeAsStringSync(diCode);

      // Verify all required components are present
      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains('// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import'));
      expect(diCode, contains("import 'package:singleton_manager/singleton_manager.dart';"));
      expect(diCode, contains("import 'complete_service.dart';"));
      expect(diCode,
          contains('class CompleteServiceDI extends CompleteService implements ISingletonStandardDI {'));
      expect(diCode, contains('factory CompleteServiceDI.initializeDI() {'));
      expect(diCode, contains('final instance = CompleteServiceDI();'));
      expect(diCode, contains('instance.initializeDI();'));
      expect(diCode, contains('return instance;'));
      expect(diCode, contains('@override'));
      expect(diCode, contains('void initializeDI() {'));
      expect(diCode, contains('param1 = SingletonDIAccess.get<String>();'));
      expect(diCode, contains('param2 = SingletonDIAccess.get<String>();'));

      // Verify file was written successfully
      expect(augmentFile.existsSync(), true);
      final content = augmentFile.readAsStringSync();
      expect(content, equals(diCode));
    });

    test('class with @isMandatoryParameter and @isOptionalParameter generates initializeWithParametersDI', () {
      final dir = Directory('${tempDir.path}/lib/params');
      dir.createSync(recursive: true);

      // Source file with annotated constructor params AND injected fields.
      final dartFile = File('${dir.path}/payment_gateway.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class PaymentGateway {
  PaymentGateway({
    @isMandatoryParameter required String apiKey,
    @isOptionalParameter String? currency,
  });

  @isInjected
  late Logger logger;

  @isInjected
  late AuditRepository audit;
}

class Logger {}
class AuditRepository {}
''');

      // Parse — constructorParameters must come through.
      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));
      expect(parsed[0].constructorParameters, hasLength(2));
      expect(parsed[0].constructorParameters[0].name, 'apiKey');
      expect(parsed[0].constructorParameters[0].isMandatory, isTrue);
      expect(parsed[0].constructorParameters[1].name, 'currency');
      expect(parsed[0].constructorParameters[1].isMandatory, isFalse);
      expect(parsed[0].injectedFields, hasLength(2));

      // Generate — pass parsed[0] directly so constructorParameters is preserved.
      final diCode = AugmentationGenerator.generate(parsed[0]);
      final diFile = File('${dir.path}/payment_gateway_di.dart');
      diFile.writeAsStringSync(diCode);

      // -- structural checks --
      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains('class PaymentGatewayDI extends PaymentGateway implements ISingletonStandardDI'));

      // DI constructor mirrors original named params.
      expect(diCode, contains('PaymentGatewayDI({required String apiKey, String? currency}) : super(apiKey: apiKey, currency: currency)'));

      // No no-arg initializeDI factory (mandatory param present).
      expect(diCode, isNot(contains('factory PaymentGatewayDI.initializeDI()')));

      // initializeWithParametersDI: mandatory=positional, optional=named.
      expect(diCode, contains('factory PaymentGatewayDI.initializeWithParametersDI(String apiKey, {String? currency})'));
      expect(diCode, contains('final instance = PaymentGatewayDI(apiKey: apiKey, currency: currency)'));
      // @isInjected fields injected explicitly (no initializeDI() call).
      expect(diCode, contains('instance.logger = SingletonDIAccess.get<Logger>()'));
      expect(diCode, contains('instance.audit = SingletonDIAccess.get<AuditRepository>()'));
      expect(diCode, contains('return instance'));

      // Blank line between constructor and factory.
      expect(diCode, contains('super(apiKey: apiKey, currency: currency);\n\n  factory PaymentGatewayDI.initializeWithParametersDI'));

      // @isInjected fields still injected in initializeDI method.
      expect(diCode, contains('void initializeDI()'));
      expect(diCode, contains('logger = SingletonDIAccess.get<Logger>()'));
      expect(diCode, contains('audit = SingletonDIAccess.get<AuditRepository>()'));

      // File written correctly.
      expect(diFile.existsSync(), isTrue);
      expect(diFile.readAsStringSync(), equals(diCode));
    });

    test('empty class (no injections) generates valid code', () {
      final dir = Directory('${tempDir.path}/lib/empty');
      dir.createSync(recursive: true);

      final dartFile = File('${dir.path}/empty_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class EmptyService {
  void doSomething() {}
}
''');

      final parsed = SourceParser.parse([dartFile]);
      final info = SingletonClassInfo(
        className: parsed[0].className,
        sourceFilePath: 'lib/empty/empty_service.dart',
        injectedFields: parsed[0].injectedFields,
        sourceFileContent: parsed[0].sourceFileContent,
      );

      final diCode = AugmentationGenerator.generate(info);

      // Verify factory and initializeDI are still present even with no fields
      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains('factory EmptyServiceDI.initializeDI() {'));
      expect(diCode, contains('void initializeDI() {'));
      // But no field assignments
      expect(diCode, isNot(contains('SingletonDIAccess.get')));
    });

    test('@isMandatoryParameter on late field + optional ctor param + @isInjected — generates initializeWithParametersDI with explicit injection then mandatory field assignment', () {
      final dir = Directory('${tempDir.path}/lib/params');
      dir.createSync(recursive: true);

      final dartFile = File('${dir.path}/id_handler_storage_repository.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

abstract class IIdHandlerStorageRepository {}
abstract class IWorkDb {}
abstract class ILogger {}

@isSingleton
class IdHandlerStorageRepository implements IIdHandlerStorageRepository {
  IdHandlerStorageRepository({@isOptionalParameter String? collection});
  IdHandlerStorageRepository.fromDb(this.db, [this._collection = _defaultCollection]);

  static const String _defaultCollection = 'id_handler';

  @isMandatoryParameter
  @protected
  late IWorkDb db;

  @isInjected
  late ILogger logger;

  late String _collection = _defaultCollection;
}
''');

      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));
      expect(parsed[0].injectedFields, hasLength(2));
      expect(parsed[0].injectedFields[0].fieldName, 'db');
      expect(parsed[0].injectedFields[0].fieldType, 'IWorkDb');
      expect(parsed[0].injectedFields[0].isMandatory, isTrue);
      expect(parsed[0].injectedFields[1].fieldName, 'logger');
      expect(parsed[0].injectedFields[1].fieldType, 'ILogger');
      expect(parsed[0].injectedFields[1].isMandatory, isFalse);
      expect(parsed[0].constructorParameters, hasLength(1));
      expect(parsed[0].constructorParameters[0].name, 'collection');
      expect(parsed[0].constructorParameters[0].isMandatory, isFalse);

      final diCode = AugmentationGenerator.generate(parsed[0]);
      File('${dir.path}/id_handler_storage_repository_di.dart').writeAsStringSync(diCode);

      expect(diCode, contains('class IdHandlerStorageRepositoryDI extends IdHandlerStorageRepository implements ISingletonStandardDI'));
      expect(diCode, contains('IdHandlerStorageRepositoryDI({String? collection}) : super(collection: collection)'));
      expect(diCode, contains('factory IdHandlerStorageRepositoryDI.initializeDI()'));
      // initializeDI() injects ALL annotated fields (mandatory + non-mandatory)
      expect(diCode, contains('db = SingletonDIAccess.get<IWorkDb>()'));
      expect(diCode, contains('logger = SingletonDIAccess.get<ILogger>()'));
      // initializeWithParametersDI: mandatory field as positional, optional ctor param as named
      expect(diCode, contains('factory IdHandlerStorageRepositoryDI.initializeWithParametersDI(IWorkDb db, {String? collection})'));
      // factory injects @isInjected fields explicitly, then sets mandatory field from parameter
      expect(diCode, contains('instance.logger = SingletonDIAccess.get<ILogger>()'));
      expect(diCode, contains('instance.db = db'));
      expect(diCode, isNot(contains('_collection')));
    });
  });
}
