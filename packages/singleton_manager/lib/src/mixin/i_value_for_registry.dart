// ignore: one_member_abstracts
abstract interface class IValueForRegistry {
  /// Lifecycle method called when this value is being destroyed.
  /// Implementations should clean up resources here.
  void destroy();
}
