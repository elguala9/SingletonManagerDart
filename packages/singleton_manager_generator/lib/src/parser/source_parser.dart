import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import '../model/injected_field_info.dart';
import '../model/singleton_class_info.dart';

/// Parser for Dart source files to extract @isSingleton and @isInjected annotations.
class SourceParser {
  /// Parse all Dart files in the given directory recursively.
  ///
  /// Returns a list of [SingletonClassInfo] for each class found with the
  /// @isSingleton annotation.
  static List<SingletonClassInfo> parse(
    List<File> files, {
    bool verbose = false,
  }) {
    final results = <SingletonClassInfo>[];

    for (final file in files) {
      if (verbose) {
        print('Parsing: ${file.path}');
      }

      try {
        final content = file.readAsStringSync();
        final result = parseString(content: content);
        final unit = result.unit;

        for (final declaration in unit.declarations) {
          if (declaration is ClassDeclaration) {
            final singleton = _extractSingletonInfo(declaration, file, content);
            if (singleton != null) {
              results.add(singleton);
              if (verbose) {
                print('  Found @isSingleton class: ${singleton.className}');
                for (final field in singleton.injectedFields) {
                  print('    - @isInjected field: ${field.fieldName} (${field.fieldType})');
                }
              }
            }
          }
        }
      } catch (e) {
        print('Error parsing ${file.path}: $e');
      }
    }

    return results;
  }

  /// Extract [SingletonClassInfo] from a class declaration if it has @isSingleton.
  static SingletonClassInfo? _extractSingletonInfo(
    ClassDeclaration classDecl,
    File sourceFile,
    String sourceFileContent,
  ) {
    final isSingletonAnnotation = _findAnnotation(classDecl, 'isSingleton');
    if (isSingletonAnnotation == null) {
      return null;
    }

    final injectedFields = <InjectedFieldInfo>[];

    for (final member in classDecl.members) {
      if (member is FieldDeclaration) {
        final isInjectedAnnotation = _findAnnotation(member, 'isInjected');
        if (isInjectedAnnotation != null) {
          for (final variable in member.fields.variables) {
            final fieldName = variable.name.lexeme;
            final fieldType = _extractFieldType(member.fields.type);
            if (fieldType != null) {
              injectedFields.add(
                InjectedFieldInfo(
                  fieldName: fieldName,
                  fieldType: fieldType,
                ),
              );
            }
          }
        }
      }
    }

    return SingletonClassInfo(
      className: classDecl.name.lexeme,
      sourceFilePath: sourceFile.path,
      injectedFields: injectedFields,
      sourceFileContent: sourceFileContent,
    );
  }

  /// Find an annotation by name in a declaration.
  static Annotation? _findAnnotation(
    AnnotatedNode node,
    String annotationName,
  ) {
    for (final annotation in node.metadata) {
      final element = annotation.name;
      if (element is SimpleIdentifier && element.name == annotationName) {
        return annotation;
      }
    }
    return null;
  }

  /// Extract the type name from a field type.
  static String? _extractFieldType(TypeAnnotation? typeAnnotation) {
    if (typeAnnotation == null) return null;

    if (typeAnnotation is NamedType) {
      return typeAnnotation.name2.lexeme;
    }

    return null;
  }
}
