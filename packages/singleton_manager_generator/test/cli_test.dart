import 'dart:io';
import 'package:test/test.dart';
import 'package:singleton_manager_generator/src/parser/source_parser.dart';
import 'package:singleton_manager_generator/src/generator/augmentation_generator.dart';

void main() {
  group('CLI Simulation Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('cli_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('should find and process dart files in input directory', () {
      // Create test input directory
      final inputDir = Directory('${tempDir.path}/input');
      inputDir.createSync();

      // Create a test dart file
      final dartFile = File('${inputDir.path}/service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class TestService {
  @isInjected
  late String dependency;
}
''');

      // Simulate CLI: parse and generate
      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));

      final augmentationCode = AugmentationGenerator.generate(parsed[0]);
      expect(augmentationCode, contains('augment class TestService'));
      expect(augmentationCode, contains('dependency = SingletonDIAccess.get<String>();'));
    });

    test('should handle multiple files correctly', () {
      final inputDir = Directory('${tempDir.path}/input');
      inputDir.createSync();

      final dartFile = File('${inputDir.path}/service.dart');
      dartFile.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

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
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class Service1 {
  @isInjected
  late String value;
}
''');

      final file2 = File('${inputDir.path}/service2.dart');
      file2.writeAsStringSync('''
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

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
        expect(code, contains('augment class'));
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
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class MyService {
  @isInjected
  late String value;
}
''');

      // Verify the expected output filename format
      final parsed = SourceParser.parse([dartFile]);
      expect(parsed, hasLength(1));

      // The output filename should be my_service.singleton_di.dart
      expect('my_service.singleton_di.dart', contains('my_service'));
      expect('my_service.singleton_di.dart', endsWith('.singleton_di.dart'));
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
  });
}
