import 'package:singleton_manager/src/interfaces/i_value_for_registry.dart';

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

  /// Private helper: destroys a value if it implements IValueForRegistry.
  void _destroyIfNeeded(Object? value) {
    if (value is IValueForRegistry) {
      value.destroy();
    }
  }

  /// Registers a value using its Type as the key.
  /// If a value of the same type is already registered, it will be replaced.
  /// The previous value will be destroyed if it implements [IValueForRegistry].
  void register<T extends Object>(T value) {
    _destroyIfNeeded(_registry[T]);
    _registry[T] = value;
  }

  /// Unregisters a value by its Type.
  /// If the value implements [IValueForRegistry], calls destroy before removal.
  /// If no value is registered for type T, this call is silently ignored.
  void unregister<T extends Object>() {
    _destroyIfNeeded(_registry[T]);
    _registry.remove(T);
  }

  /// Retrieves a value by its Type.
  /// Throws [StateError] if no instance of type T is found.
  T getInstance<T extends Object>() {
    final value = _registry[T];
    if (value is T) {
      return value;
    }
    throw StateError('Instance of type $T not found');
  }

  /// Clears all registered values without calling destroy.
  void clearRegistry() => _registry.clear();

  /// Destroys all values and clears the registry.
  /// If values implement [IValueForRegistry], calls destroy on each.
  void destroyAll() {
    _registry.values.forEach(_destroyIfNeeded);
    _registry.clear();
  }

  /// Returns the number of registered entries.
  int get registrySize => _registry.length;
}
