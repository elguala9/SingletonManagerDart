/// Singleton manager that uses Type as the key for registration.
/// Provides a simple, zero-dependency singleton pattern in Dart.
class SingletonManager {
  // Factory constructor for backwards compatibility
  factory SingletonManager() => instance;

  // Private constructor
  SingletonManager._();

  static final SingletonManager _instance = SingletonManager._();

  final Map<Type, Object> _registry = {};

  /// Static getter for the singleton instance
  static SingletonManager get instance => _instance;

  /// Registers a value using its Type as the key.
  /// If a value of the same type is already registered, it will be replaced.
  void register<T>(T value) {
    // Use the generic type T as the key
    _registry[T] = value as Object;
  }

  /// Unregisters a value by its Type.
  void unregister<T>() {
    _registry.remove(T);
  }

  /// Retrieves a value by its Type.
  /// Throws [StateError] if no instance of type T is found.
  T getInstance<T>() {
    final value = _registry[T];
    if (value is T) {
      return value;
    }
    throw StateError('Instance of type $T not found');
  }

  /// Clears all registered values.
  void clearRegistry() => _registry.clear();

  /// Returns the number of registered entries.
  int get registrySize => _registry.length;
}
