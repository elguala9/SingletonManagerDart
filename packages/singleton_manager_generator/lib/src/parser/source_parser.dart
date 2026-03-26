import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

import '../model/constructor_parameter_info.dart';
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

        final imports = unit.directives
            .whereType<ImportDirective>()
            .map((d) => d.uri.stringValue ?? '')
            .where((s) => s.isNotEmpty)
            .toList();

        for (final declaration in unit.declarations) {
          if (declaration is ClassDeclaration) {
            final singleton = _extractSingletonInfo(declaration, file, content, imports);
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
    List<String> imports,
  ) {
    final isSingletonAnnotation = _findAnnotation(classDecl, 'isSingleton');
    if (isSingletonAnnotation == null) {
      return null;
    }

    final injectedFields = <InjectedFieldInfo>[];
    final constructorParameters = <ConstructorParameterInfo>[];

    // ignore: deprecated_member_use
    for (final member in classDecl.members) {
      if (member is FieldDeclaration) {
        final isMandatoryAnnotation = _findAnnotation(member, 'isMandatoryParameter');
        final isOptionalAnnotation = _findAnnotation(member, 'isOptionalParameter');
        final isInjectedAnnotation = _findAnnotation(member, 'isInjected') ?? isOptionalAnnotation;
        final annotation = isMandatoryAnnotation ?? isInjectedAnnotation;
        if (annotation != null) {
          // Only inject fields that are 'late' or 'late final'
          // Plain 'final' fields cannot be assigned after construction
          final isLate = member.fields.isLate;
          if (isLate) {
            for (final variable in member.fields.variables) {
              final fieldName = variable.name.lexeme;
              if (fieldName.startsWith('_')) {
                print(
                  'WARNING: @isInjected/@isMandatoryParameter on private field "$fieldName" in class '
                  '${classDecl.namePart.typeName.lexeme} is not supported — skipping.',
                );
                continue;
              }
              final fieldType = _extractFieldType(member.fields.type);
              if (fieldType != null) {
                final isOptional = isMandatoryAnnotation == null && isOptionalAnnotation != null;
                if (isOptional && !fieldType.endsWith('?')) {
                  print(
                    'WARNING: @isOptionalParameter field "$fieldName" in class '
                    '${classDecl.namePart.typeName.lexeme} should be nullable (use "$fieldType?" instead of "$fieldType").',
                  );
                }
                injectedFields.add(
                  InjectedFieldInfo(
                    fieldName: fieldName,
                    fieldType: fieldType,
                    isMandatory: isMandatoryAnnotation != null,
                    isOptional: isOptional,
                  ),
                );
              }
            }
          }
        }
      } else if (member is ConstructorDeclaration && member.name == null) {
        // Default (unnamed) constructor — extract annotated parameters.
        for (final param in member.parameters.parameters) {
          final info = _extractConstructorParameterInfo(param);
          if (info != null) constructorParameters.add(info);
        }
      }
    }

    return SingletonClassInfo(
      className: classDecl.namePart.typeName.lexeme,
      sourceFilePath: sourceFile.path,
      injectedFields: injectedFields,
      sourceFileContent: sourceFileContent,
      sourceFileImports: imports,
      constructorParameters: constructorParameters,
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

  /// Extract [ConstructorParameterInfo] from a formal parameter if it carries
  /// @isMandatoryParameter or @isOptionalParameter.
  static ConstructorParameterInfo? _extractConstructorParameterInfo(
    FormalParameter param,
  ) {
    bool isMandatory = false;
    bool hasAnnotation = false;

    for (final annotation in param.metadata) {
      final element = annotation.name;
      if (element is SimpleIdentifier) {
        if (element.name == 'isMandatoryParameter') {
          isMandatory = true;
          hasAnnotation = true;
        } else if (element.name == 'isOptionalParameter') {
          hasAnnotation = true;
        }
      }
    }

    if (!hasAnnotation) return null;

    final isNamed = param.isNamed;

    // Unwrap DefaultFormalParameter to get to the typed parameter.
    final NormalFormalParameter inner;
    if (param is DefaultFormalParameter) {
      inner = param.parameter;
    } else if (param is NormalFormalParameter) {
      inner = param;
    } else {
      return null;
    }

    String? type;
    String? name;

    if (inner is SimpleFormalParameter) {
      type = _extractFieldType(inner.type);
      name = inner.name?.lexeme;
    } else if (inner is FieldFormalParameter) {
      type = inner.type != null ? _extractFieldType(inner.type) : null;
      // ignore: deprecated_member_use
      name = inner.name.lexeme;
    }

    if (name == null || type == null) return null;

    return ConstructorParameterInfo(
      name: name,
      type: type,
      isMandatory: isMandatory,
      isNamed: isNamed,
    );
  }

  /// Extract the type name from a field type, including generic type arguments
  /// and the trailing `?` for nullable types.
  static String? _extractFieldType(TypeAnnotation? typeAnnotation) {
    if (typeAnnotation == null) return null;

    if (typeAnnotation is NamedType) {
      final nullable = typeAnnotation.question != null ? '?' : '';
      final typeArgs = typeAnnotation.typeArguments;
      if (typeArgs != null && typeArgs.arguments.isNotEmpty) {
        final args = typeArgs.arguments
            .map(_extractFieldType)
            .whereType<String>()
            .join(', ');
        return '${typeAnnotation.name.lexeme}<$args>$nullable';
      }
      return '${typeAnnotation.name.lexeme}$nullable';
    }

    return null;
  }
}
