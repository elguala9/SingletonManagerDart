/// Factory function that creates instances of type T.
typedef FactoryFn<T> = T Function();

/// Global registry for factory functions used by [SingletonDI].
final _factoryRegistry = <Type, FactoryFn<Object>>{};

/// Dependency Injection factory registration utilities.
///
/// Manages factory registration for automatic singleton instantiation.
/// Use this class to register factories before using extension methods like
/// `add` or `addAs` on SingletonManager.
///
/// Example:
/// ```dart
/// // Setup (register factories once)
/// SingletonDI.registerFactory<MyService>(() => MyService());
/// SingletonDI.registerFactory<RepositoryImpl>(() => RepositoryImpl());
///
/// // Usage via extension methods
/// await manager.add<MyService>();
/// await manager.addAs<IRepository, RepositoryImpl>();
/// final service = manager.get<MyService>();
/// manager.remove<MyService>();
/// ```
class SingletonDI {
  // Private constructor - use static methods only
  SingletonDI._();

  /// Registers a factory function for type T.
  ///
  /// This must be called before using extension methods to provide the factory
  /// for instantiation.
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
  static FactoryFn<T>? getFactory<T extends Object>() =>
      _factoryRegistry[T] as FactoryFn<T>?;

  /// Clears all registered factory functions.
  static void clearFactories() => _factoryRegistry.clear();

  /// Returns the number of registered factories.
  static int get factoryCount => _factoryRegistry.length;
}
