/// Information about a constructor parameter annotated with
/// @isMandatoryParameter or @isOptionalParameter.
class ConstructorParameterInfo {
  /// The name of the parameter.
  final String name;

  /// The type of the parameter (e.g., "String", "String?").
  final String type;

  /// Whether this parameter is mandatory (annotated with @isMandatoryParameter).
  /// If false, it is optional (annotated with @isOptionalParameter).
  final bool isMandatory;

  /// Whether this parameter is named in the original constructor.
  final bool isNamed;

  const ConstructorParameterInfo({
    required this.name,
    required this.type,
    required this.isMandatory,
    required this.isNamed,
  });

  @override
  String toString() =>
      'ConstructorParameterInfo(name: $name, type: $type, isMandatory: $isMandatory, isNamed: $isNamed)';
}
