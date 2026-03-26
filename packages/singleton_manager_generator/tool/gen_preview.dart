import 'dart:io';
import 'package:singleton_manager_generator/src/parser/source_parser.dart';
import 'package:singleton_manager_generator/src/generator/di_class_generator.dart';

void main() {
  final src = File('lib/test_artifacts/exact_pattern_tests/id_handler_storage_repository_no_ctor_params.dart');
  final parsed = SourceParser.parse([src], verbose: true);
  for (final info in parsed) {
    final outPath = 'lib/test_artifacts/exact_pattern_tests/id_handler_storage_repository_no_ctor_params_di.dart';
    final diCode = AugmentationGenerator.generate(info, outputFilePath: outPath);
    print(diCode);
    File(outPath).writeAsStringSync(diCode);
  }
}
