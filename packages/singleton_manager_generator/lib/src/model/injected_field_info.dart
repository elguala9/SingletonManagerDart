/// Information about a field annotated with @isInjected.
class InjectedFieldInfo {
  /// The name of the field.
  final String fieldName;

  /// The type of the field (e.g., "SomeService").
  final String fieldType;

  /// Create an instance of [InjectedFieldInfo].
  InjectedFieldInfo({
    required this.fieldName,
    required this.fieldType,
  });

  @override
  String toString() => 'InjectedFieldInfo(fieldName: $fieldName, fieldType: $fieldType)';
}
