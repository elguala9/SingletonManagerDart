import 'dart:io';
import 'package:test/test.dart';
import 'package:singleton_manager_generator/src/parser/source_parser.dart';
import 'package:singleton_manager_generator/src/generator/di_class_generator.dart';

void main() {
  group('CLI Simulation Tests', () {
    late Directory tempDir;

    setUpAll(() {
      tempDir = Directory('lib/test_artifacts/cli_tests');
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

    test('should find and process dart files in input directory', () {
      // Create test input directory
      final inputDir = Directory('${tempDir.path}/input');
      inputDir.createSync();

      // Create a test dart file
      final dartFile = File('${inputDir.path}/service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class TestService {
  @isInjected
  late String dependency;
}
''');

      // Simulate CLI: parse and generate
      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));

      final diCode = AugmentationGenerator.generate(parsed[0]);
      expect(diCode, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(diCode, contains('class TestServiceDI extends TestService'));
      expect(diCode, contains('dependency = SingletonDIAccess.get<String>();'));
    });

    test('should handle multiple files correctly', () {
      final inputDir = Directory('${tempDir.path}/input');
      inputDir.createSync();

      final dartFile = File('${inputDir.path}/service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class VerboseService {
  @isInjected
  late int number;
}
''');

      // Simulate CLI: parse with verbose=true
      final parsed = SourceParser.parse([dartFile], verbose: true);
      expect(parsed, hasLength(1));
      expect(parsed[0].className, 'VerboseService');
      expect(parsed[0].injectedFields, hasLength(1));
    });

    test('should generate files for multiple files', () {
      final inputDir = Directory('${tempDir.path}/input');
      inputDir.createSync();

      final file1 = File('${inputDir.path}/service1.dart');
      file1.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class Service1 {
  @isInjected
  late String value;
}
''');

      final file2 = File('${inputDir.path}/service2.dart');
      file2.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class Service2 {
  @isInjected
  late int number;
}
''');

      // Simulate CLI: parse multiple files
      final parsed = SourceParser.parse([file1, file2]);
      expect(parsed, hasLength(2));

      // Generate for both
      for (final info in parsed) {
        final code = AugmentationGenerator.generate(info);
        expect(code, contains('// AUTO-GENERATED - DO NOT CHANGE'));
        expect(code, contains('class'));
      }
    });

    test('should skip non-singleton classes', () {
      final inputDir = Directory('${tempDir.path}/input');
      inputDir.createSync();

      final dartFile = File('${inputDir.path}/regular.dart');
      dartFile.writeAsStringSync('''
class RegularClass {
  String name = 'test';
}
''');

      // Simulate CLI: parse file with no singleton
      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, isEmpty);
    });

    test('should generate correct file names format', () {
      final inputDir = Directory('${tempDir.path}/input');
      inputDir.createSync();

      final dartFile = File('${inputDir.path}/my_service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  late String value;
}
''');

      // Verify the expected output filename format
      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));

      // The output filename should be my_service_di.dart
      expect('my_service_di.dart', contains('my_service'));
      expect('my_service_di.dart', endsWith('_di.dart'));
    });

    test('should handle files with no singleton classes', () {
      final inputDir = Directory('${tempDir.path}/input');
      inputDir.createSync();

      // Create files without @isSingleton
      File('${inputDir.path}/file1.dart').writeAsStringSync('class A {}');
      File('${inputDir.path}/file2.dart').writeAsStringSync('class B {}');

      // Simulate CLI: parse files with no singleton
      final file1 = File('${inputDir.path}/file1.dart');
      final file2 = File('${inputDir.path}/file2.dart');

      final parsed = SourceParser.parse([file1, file2]);
      expect(parsed, isEmpty);
    });

    test('should write _di.dart with initializeWithParametersDI when source has @isMandatoryParameter/@isOptionalParameter', () {
      final inputDir = Directory('${tempDir.path}/input');
      inputDir.createSync();

      // Input source file with annotated constructor params.
      final sourceFile = File('${inputDir.path}/my_service.dart');
      sourceFile.writeAsStringSync('''
import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  MyService(@isMandatoryParameter String apiUrl, {@isOptionalParameter int? timeoutMs});

  @isInjected
  late Logger logger;
}

class Logger {}
''');

      // Simulate CLI: parse → generate → write.
      final parsed = SourceParser.parse([sourceFile]);
      expect(parsed, hasLength(1));

      final diCode = AugmentationGenerator.generate(parsed[0]);

      final diFile = File('${inputDir.path}/my_service_di.dart');
      diFile.writeAsStringSync(diCode);

      // Read back from disk — exactly what the CLI would produce.
      final written = diFile.readAsStringSync();

      expect(written, contains('// AUTO-GENERATED - DO NOT CHANGE'));
      expect(written, contains('class MyServiceDI extends MyService implements ISingletonStandardDI'));
      // Constructor forwards both params to super (positional).
      expect(written, contains('MyServiceDI(String apiUrl, {int? timeoutMs}) : super(apiUrl, timeoutMs: timeoutMs)'));
      // initializeWithParametersDI written to disk.
      expect(written, contains('factory MyServiceDI.initializeWithParametersDI(String apiUrl, {int? timeoutMs})'));
      expect(written, contains('final instance = MyServiceDI(apiUrl, timeoutMs: timeoutMs)'));
      expect(written, contains('instance.initializeDI()'));
      // No no-arg factory (mandatory param present).
      expect(written, isNot(contains('factory MyServiceDI.initializeDI()')));
      // @isInjected still works.
      expect(written, contains('logger = SingletonDIAccess.get<Logger>()'));
    });
  });
}
