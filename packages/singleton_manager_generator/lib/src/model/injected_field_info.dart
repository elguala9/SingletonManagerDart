/// Information about a field annotated with @isInjected or @isMandatoryParameter.
class InjectedFieldInfo {
  /// The name of the field.
  final String fieldName;

  /// The type of the field (e.g., "SomeService").
  final String fieldType;

  /// Whether this field was annotated with @isMandatoryParameter (true)
  /// or @isInjected (false).
  ///
  /// Mandatory fields are injected via [initializeDI] AND also exposed as
  /// explicit parameters in [initializeWithParametersDI].
  final bool isMandatory;

  /// Create an instance of [InjectedFieldInfo].
  InjectedFieldInfo({
    required this.fieldName,
    required this.fieldType,
    this.isMandatory = false,
  });

  @override
  String toString() =>
      'InjectedFieldInfo(fieldName: $fieldName, fieldType: $fieldType, isMandatory: $isMandatory)';
}
