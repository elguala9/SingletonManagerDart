/// Information about a field annotated with @isInjected, @isMandatoryParameter,
/// or @isOptionalParameter.
class InjectedFieldInfo {
  /// The name of the field.
  final String fieldName;

  /// The type of the field (e.g., "SomeService").
  final String fieldType;

  /// Whether this field was annotated with @isMandatoryParameter.
  ///
  /// Mandatory fields are injected via [initializeDI] AND exposed as required
  /// positional parameters in [initializeWithParametersDI] (overriding the
  /// container value).
  final bool isMandatory;

  /// Whether this field was annotated with @isOptionalParameter (without
  /// @isMandatoryParameter).
  ///
  /// Optional fields are injected via [initializeDI] AND exposed as optional
  /// named parameters in [initializeWithParametersDI]. If the caller provides
  /// a value, it is used; otherwise the container is queried as fallback.
  final bool isOptional;

  /// Create an instance of [InjectedFieldInfo].
  InjectedFieldInfo({
    required this.fieldName,
    required this.fieldType,
    this.isMandatory = false,
    this.isOptional = false,
  });

  @override
  String toString() =>
      'InjectedFieldInfo(fieldName: $fieldName, fieldType: $fieldType, isMandatory: $isMandatory, isOptional: $isOptional)';
}
