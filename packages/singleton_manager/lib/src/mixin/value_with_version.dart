/// Container for a value associated with a version.
/// The version is preserved through updates of the value in the registry.
class ValueWithVersion<Value> {
  /// Constructor
  ValueWithVersion(this.value, this.version);

  /// The stored value
  final Value value;

  /// The version number of this value
  final int version;
}
