import 'package:singleton_manager/src/mixin/i_value_for_registry.dart';
import 'package:singleton_manager/src/singleton/i_singleton.dart';
import 'package:singleton_manager/src/singleton/singleton_manager.dart';

/// Factory function that creates instances of type T.
typedef FactoryFn<T> = T Function();

/// Global registry for factory functions used by [SingletonDI].
final _factoryRegistry = <Type, FactoryFn<Object>>{};

/// Dependency Injection utilities for [SingletonManager].
///
/// Provides type-safe registration, retrieval, and removal of singletons
/// using a factory pattern. Factories must be registered before instantiation.
///
/// Example:
/// ```dart
/// // Setup (register factories once)
/// SingletonDI.registerFactory<MyService>(() => MyService());
/// SingletonDI.registerFactory<RepositoryImpl>(() => RepositoryImpl());
///
/// // Usage
/// await manager.add<MyService>();
/// await manager.addAs<IRepository, RepositoryImpl>();
/// final service = manager.get<MyService>();
/// manager.remove<MyService>();
/// ```
extension SingletonDIExt on SingletonManager {
  /// Registers a singleton by type with automatic initialization.
  ///
  /// Requires that a factory for T has been registered via
  /// [SingletonDI.registerFactory].
  /// If T implements [ISingleton], the initializeDI method is
  /// called after instantiation.
  ///
  /// Throws [StateError] if no factory is registered for T.
  Future<void> add<T extends Object>() async {
    final factory = _factoryRegistry[T];
    if (factory == null) {
      throw StateError(
        'No factory registered for type $T. '
        'Call SingletonDI.registerFactory<$T>(...) first.',
      );
    }

    final instance = factory() as T;

    // If instance implements ISingleton, initialize it
    if (instance is ISingleton) {
      await instance.initializeDI();
    }

    register<T>(instance);
  }

  /// Registers a singleton by interface with a concrete implementation.
  ///
  /// Registers [I] as the key but stores an instance of [T].
  /// Requires that a factory for T has been registered via
  /// [SingletonDI.registerFactory].
  /// If T implements [ISingleton], the initializeDI method is called
  /// after instantiation.
  ///
  /// Throws [StateError] if no factory is registered for T.
  ///
  /// Example:
  /// ```dart
  /// SingletonDI.registerFactory<RepositoryImpl>(
  ///   () => RepositoryImpl(),
  /// );
  /// await manager.addAs<IRepository, RepositoryImpl>();
  /// ```
  Future<void> addAs<I extends Object, T extends I>() async {
    final factory = _factoryRegistry[T];
    if (factory == null) {
      throw StateError(
        'No factory registered for type $T. '
        'Call SingletonDI.registerFactory<$T>(...) first.',
      );
    }

    final instance = factory() as T;

    // If instance implements ISingleton, initialize it
    if (instance is ISingleton) {
      await (instance as ISingleton).initializeDI();
    }

    // Unregister previous instance if exists
    unregister<I>();

    // Register with interface as key, but store the T instance
    register<I>(instance as I);
  }

  /// Retrieves a singleton by its type.
  ///
  /// Throws [StateError] if no instance of type T is found.
  T get<T>() => getInstance<T>();

  /// Removes a singleton by its type.
  ///
  /// If the instance implements [IValueForRegistry], calls destroy before
  /// removal.
  void remove<T>() {
    // Try to destroy if exists
    try {
      final value = getInstance<T>();
      if (value is IValueForRegistry) {
        (value as IValueForRegistry).destroy();
      }
      // ignore: avoid_catching_errors
    } on StateError {
      // Instance not found is expected, ignore
    }

    unregister<T>();
  }
}

/// Dependency Injection utilities for [SingletonManager].
///
/// Manages factory registration for automatic singleton instantiation.
class SingletonDI {
  // Private constructor - use static methods only
  SingletonDI._();

  /// Registers a factory function for type T.
  ///
  /// This must be called before [add<T>] to provide the factory for
  /// instantiation.
  ///
  /// Example:
  /// ```dart
  /// SingletonDI.registerFactory<MyService>(() => MyService());
  /// ```
  static void registerFactory<T extends Object>(FactoryFn<T> factory) {
    _factoryRegistry[T] = factory as FactoryFn<Object>;
  }

  /// Retrieves a factory function for type T.
  ///
  /// Returns null if no factory is registered for T.
  static FactoryFn<T>? getFactory<T extends Object>() {
    return _factoryRegistry[T] as FactoryFn<T>?;
  }

  /// Clears all registered factory functions.
  static void clearFactories() {
    _factoryRegistry.clear();
  }

  /// Returns the number of registered factories.
  static int get factoryCount => _factoryRegistry.length;

  /// Registers a singleton by type with automatic initialization via [SingletonManager.instance].
  ///
  /// This is a static convenience method that delegates to
  /// [SingletonManager.instance.add<T>()].
  ///
  /// Requires that a factory for T has been registered via
  /// [SingletonDI.registerFactory].
  ///
  /// Example:
  /// ```dart
  /// SingletonDI.registerFactory<MyService>(() => MyService());
  /// await SingletonDI.add<MyService>();
  /// ```
  static Future<void> add<T extends Object>() =>
      SingletonManager.instance.add<T>();

  /// Registers a singleton by interface with a concrete implementation via [SingletonManager.instance].
  ///
  /// This is a static convenience method that delegates to
  /// [SingletonManager.instance.addAs<I, T>()].
  ///
  /// Registers [I] as the key but stores an instance of [T].
  ///
  /// Example:
  /// ```dart
  /// SingletonDI.registerFactory<RepositoryImpl>(() => RepositoryImpl());
  /// await SingletonDI.addAs<IRepository, RepositoryImpl>();
  /// ```
  static Future<void> addAs<I extends Object, T extends I>() =>
      SingletonManager.instance.addAs<I, T>();

  /// Retrieves a singleton by its type from [SingletonManager.instance].
  ///
  /// This is a static convenience method that delegates to
  /// [SingletonManager.instance.get<T>()].
  ///
  /// Throws [StateError] if no instance of type T is found.
  ///
  /// Example:
  /// ```dart
  /// final service = SingletonDI.get<MyService>();
  /// ```
  static T get<T>() => SingletonManager.instance.get<T>();

  /// Removes a singleton by its type from [SingletonManager.instance].
  ///
  /// This is a static convenience method that delegates to
  /// [SingletonManager.instance.remove<T>()].
  ///
  /// If the instance implements [IValueForRegistry], calls destroy before
  /// removal.
  ///
  /// Example:
  /// ```dart
  /// SingletonDI.remove<MyService>();
  /// ```
  static void remove<T>() => SingletonManager.instance.remove<T>();
}
