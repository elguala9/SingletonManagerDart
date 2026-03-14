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
  Future<void> add<T extends ISingletonDI<dynamic>>() async {
    final factory = SingletonDI.getFactory<T>();
    if (factory == null) {
      throw StateError(
        'No factory registered for type $T. '
        'Call SingletonDI.registerFactory<$T>(...) first.',
      );
    }

    final instance = factory();
    await instance.initializeDI();

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
  /// // IRepository extends ISingleton<dynamic, dynamic>
  /// // RepositoryImpl implements IRepository
  /// SingletonDI.registerFactory<RepositoryImpl>(
  ///   () => RepositoryImpl(),
  /// );
  /// await manager.addAs<IRepository, RepositoryImpl>();
  /// ```
  Future<void> addAs<I extends ISingletonDI<dynamic>,
      T extends I>() async {
    final factory = SingletonDI.getFactory<T>();
    if (factory == null) {
      throw StateError(
        'No factory registered for type $T. '
        'Call SingletonDI.registerFactory<$T>(...) first.',
      );
    }

    final instance = factory();
    await instance.initializeDI();

    // Unregister previous instance if exists
    unregister<I>();

    // Register with interface as key, but store the T instance
    register<I>(instance);
  }

  /// Registers an existing singleton instance of type [T].
  ///
  /// If the instance implements [ISingleton], the initializeDI method is
  /// called after registration.
  ///
  /// Example:
  /// ```dart
  /// final service = MyService(); // MyService implements ISingleton
  /// await manager.addInstance<MyService>(service);
  /// ```
  Future<void> addInstance<T extends Object>(
      T instance) async {

    register<T>(instance);
  }

  /// Registers an existing singleton instance of type [T] under interface [I].
  ///
  /// Registers [I] as the key but stores the [instance]. Useful for
  /// polymorphism: you pass a concrete implementation but register it as an
  /// interface type. If the instance implements [ISingleton], the
  /// initializeDI method is called before registration.
  /// Any previous registration for [I] is unregistered first.
  ///
  /// Example:
  /// ```dart
  /// final repo = RepositoryImpl(); // RepositoryImpl implements IRepository
  /// await manager.addInstanceAs<IRepository, RepositoryImpl>(repo);
  /// // IRepository extends ISingleton<dynamic, dynamic>
  /// ```
  Future<void> addInstanceAs<I extends Object,
      T extends I>(T instance) async {
    // Unregister previous instance if exists
    unregister<I>();
    // Register with interface as key, but store the T instance
    register<I>(instance);
  }

  /// Retrieves a singleton by its type.
  ///
  /// Works with any registered type, not just [ISingletonDI] implementations.
  /// Throws [StateError] if no instance of type T is found.
  T get<T extends Object>() => getInstance<T>();

  /// Removes a singleton by its type.
  ///
  /// Works with any registered type. If the instance implements
  /// [IValueForRegistry], calls destroy before removal.
  void remove<T extends Object>() {
    unregister<T>();
  }
}
