import 'constructor_parameter_info.dart';
import 'injected_field_info.dart';

/// Information about a class annotated with @isSingleton.
class SingletonClassInfo {
  /// The name of the class.
  final String className;

  /// The relative path to the source file containing the class.
  final String sourceFilePath;

  /// The list of fields annotated with @isInjected in this class.
  final List<InjectedFieldInfo> injectedFields;

  /// The source code content of the file containing this class.
  final String sourceFileContent;

  /// All import URIs found in the source file.
  final List<String> sourceFileImports;

  /// Constructor parameters annotated with @isMandatoryParameter or
  /// @isOptionalParameter. When non-empty, [initializeWithParametersDI] is
  /// generated instead of (or alongside) the no-arg [initializeDI] factory.
  final List<ConstructorParameterInfo> constructorParameters;

  /// Create an instance of [SingletonClassInfo].
  SingletonClassInfo({
    required this.className,
    required this.sourceFilePath,
    required this.injectedFields,
    required this.sourceFileContent,
    this.sourceFileImports = const [],
    this.constructorParameters = const [],
  });

  @override
  String toString() =>
      'SingletonClassInfo(className: $className, sourceFilePath: $sourceFilePath, '
      'injectedFields: $injectedFields, constructorParameters: $constructorParameters)';
}
