import 'package:singleton_manager/src/interfaces/i_value_for_registry.dart';
import 'package:singleton_manager/src/singleton/i_singleton.dart';
import 'package:singleton_manager/src/singleton/singleton_di.dart';
import 'package:singleton_manager/src/singleton/singleton_manager.dart';

/// Extension methods for dependency injection on [SingletonManager].
///
/// Provides type-safe registration, retrieval, and removal of singletons
/// using a factory pattern. Factories must be registered via the
/// registerFactory method before using these methods.
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
    final factory = SingletonDI.getFactory<T>();
    if (factory == null) {
      throw StateError(
        'No factory registered for type $T. '
        'Call SingletonDI.registerFactory<$T>(...) first.',
      );
    }

    final instance = factory();

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
    final factory = SingletonDI.getFactory<T>();
    if (factory == null) {
      throw StateError(
        'No factory registered for type $T. '
        'Call SingletonDI.registerFactory<$T>(...) first.',
      );
    }

    final instance = factory();

    // If instance implements ISingleton, initialize it
    if (instance is ISingleton) {
      // ignore: unnecessary_cast
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
  T get<T extends Object>() => getInstance<T>();

  /// Removes a singleton by its type.
  ///
  /// If the instance implements [IValueForRegistry], calls destroy before
  /// removal.
  void remove<T extends Object>() {
    unregister<T>();
  }
}
