/// Core singleton manager implementation.
library singleton_manager.src.singleton_manager;

/// A type-safe singleton manager for managing application singletons.
///
/// Provides O(1) registration and retrieval of singleton instances with
/// support for lazy loading and optional lifecycle management.
///
/// Example:
/// ```dart
/// final manager = SingletonManager<String>();
///
/// // Register eager singleton
/// manager.register('config', () => Config());
///
/// // Register lazy singleton (created on first access)
/// manager.registerLazy('database', () => Database());
///
/// // Retrieve singleton
/// final config = manager.get('config');
/// ```
class SingletonManager<K> {
  final Map<K, dynamic> _singletons = {};
  final Map<K, Function> _factories = {};
  final Set<K> _lazyKeys = {};

  /// Registers an eager singleton that is created immediately.
  ///
  /// Throws [StateError] if a singleton with the same key already exists.
  void register(K key, dynamic Function() factory) {
    if (_singletons.containsKey(key) || _factories.containsKey(key)) {
      throw StateError('Singleton with key $key already registered');
    }
    _singletons[key] = factory();
  }

  /// Registers a lazy singleton that is created on first access.
  ///
  /// Throws [StateError] if a singleton with the same key already exists.
  void registerLazy(K key, dynamic Function() factory) {
    if (_singletons.containsKey(key) || _factories.containsKey(key)) {
      throw StateError('Singleton with key $key already registered');
    }
    _factories[key] = factory;
    _lazyKeys.add(key);
  }

  /// Retrieves a singleton by key.
  ///
  /// For lazy singletons, creates the instance on first access.
  /// Returns the same instance for subsequent calls.
  ///
  /// Throws [StateError] if no singleton with the given key exists.
  dynamic get(K key) {
    if (_singletons.containsKey(key)) {
      return _singletons[key];
    }

    if (_factories.containsKey(key)) {
      final factory = _factories[key]!;
      final instance = factory();
      _singletons[key] = instance;
      _factories.remove(key);
      _lazyKeys.remove(key);
      return instance;
    }

    throw StateError('Singleton with key $key not found');
  }

  /// Checks if a singleton exists (eager) or is registered (lazy).
  bool contains(K key) => _singletons.containsKey(key) || _factories.containsKey(key);

  /// Removes a singleton by key.
  ///
  /// Throws [StateError] if no singleton with the given key exists.
  void remove(K key) {
    if (_singletons.containsKey(key)) {
      _singletons.remove(key);
      return;
    }

    if (_factories.containsKey(key)) {
      _factories.remove(key);
      _lazyKeys.remove(key);
      return;
    }

    throw StateError('Singleton with key $key not found');
  }

  /// Removes all singletons and clears the manager.
  void clear() {
    _singletons.clear();
    _factories.clear();
    _lazyKeys.clear();
  }

  /// Returns the number of registered singletons (eager and lazy combined).
  int get length => _singletons.length + _factories.length;

  /// Checks if the manager is empty.
  bool get isEmpty => length == 0;

  /// Returns an unmodifiable view of registered singleton keys.
  Iterable<K> get keys => <K>[..._singletons.keys, ..._factories.keys];
}
