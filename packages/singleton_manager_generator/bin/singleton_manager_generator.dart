import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:singleton_manager_generator/src/generator/augmentation_generator.dart';
import 'package:singleton_manager_generator/src/parser/source_parser.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'input',
      abbr: 'i',
      defaultsTo: 'lib',
      help: 'Input directory containing source Dart files',
    )
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output directory for generated DI files (default: same as input)',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      negatable: false,
      help: 'Enable verbose logging',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Show this help message',
    );

  late ArgResults results;
  try {
    results = parser.parse(arguments);
  } catch (e) {
    stderr.writeln('Error parsing arguments: $e');
    _printUsage(parser);
    exit(1);
  }

  if (results['help'] as bool) {
    _printUsage(parser);
    exit(0);
  }

  final inputDir = Directory(results['input'] as String);
  final outputDir = Directory(results['output'] as String? ?? (results['input'] as String));
  final verbose = results['verbose'] as bool;

  if (!inputDir.existsSync()) {
    stderr.writeln('Error: Input directory does not exist: ${inputDir.path}');
    exit(1);
  }

  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  if (verbose) {
    print('Input directory: ${inputDir.path}');
    print('Output directory: ${outputDir.path}');
  }

  // Find all .dart files recursively
  final dartFiles = _findDartFiles(inputDir);
  if (verbose) {
    print('Found ${dartFiles.length} Dart files');
  }

  if (dartFiles.isEmpty) {
    print('No Dart files found in ${inputDir.path}');
    exit(0);
  }

  // Parse files to find @isSingleton classes
  final singletonInfos = SourceParser.parse(dartFiles, verbose: verbose);

  if (singletonInfos.isEmpty) {
    print('No @isSingleton classes found');
    exit(0);
  }

  // Generate DI files
  var generatedCount = 0;
  for (final info in singletonInfos) {
    final sourceFileName = p.basename(info.sourceFilePath);
    final outputFileName = '${p.withoutExtension(sourceFileName)}_di.dart';
    final outputPath = p.join(outputDir.path, outputFileName);

    final diCode = AugmentationGenerator.generate(info);

    File(outputPath).writeAsStringSync(diCode);
    if (verbose) {
      print('Generated: $outputPath');
    }
    generatedCount++;
  }

  print('✓ Generated $generatedCount DI file(s) in ${outputDir.path}');
}

/// Find all .dart files in a directory recursively.
List<File> _findDartFiles(Directory dir) {
  final dartFiles = <File>[];

  try {
    final entities = dir.listSync(recursive: true, followLinks: false);
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        dartFiles.add(entity);
      }
    }
  } catch (e) {
    stderr.writeln('Error listing directory: $e');
  }

  return dartFiles;
}

void _printUsage(ArgParser parser) {
  print('Generate Dart DI files for @isSingleton classes');
  print('');
  print('Usage: dart run singleton_manager_generator [options]');
  print('');
  print('Options:');
  print(parser.usage);
}
