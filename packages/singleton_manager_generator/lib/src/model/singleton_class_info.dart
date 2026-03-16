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

  /// Create an instance of [SingletonClassInfo].
  SingletonClassInfo({
    required this.className,
    required this.sourceFilePath,
    required this.injectedFields,
    required this.sourceFileContent,
  });

  @override
  String toString() => 'SingletonClassInfo(className: $className, sourceFilePath: $sourceFilePath, injectedFields: $injectedFields)';
}
