import 'package:singleton_manager/src/interfaces/i_value_for_registry.dart';
import 'package:singleton_manager/src/singleton/singleton_di_ext.dart';
import 'package:singleton_manager/src/singleton/singleton_manager.dart';

/// Static convenience methods for accessing the global singleton manager.
///
/// Provides static methods that delegate to [SingletonManager.instance]
/// for simplified API access without needing to explicitly access the
/// singleton instance.
///
/// Example:
/// ```dart
/// // Register factories first
/// SingletonDI.registerFactory<MyService>(() => MyService());
///
/// // Use static access methods directly
/// await SingletonDIAccess.add<MyService>();
/// final service = SingletonDIAccess.get<MyService>();
/// SingletonDIAccess.remove<MyService>();
/// ```
class SingletonDIAccess {
  // Private constructor - use static methods only
  SingletonDIAccess._();

  /// Registers a singleton by type with automatic initialization via
  /// [SingletonManager.instance].
  ///
  /// This is a static convenience method that delegates to
  /// [SingletonManager.instance.add<T>()].
  ///
  /// Requires that a factory for T has been registered via the
  /// registerFactory static method.
  ///
  /// Example:
  /// ```dart
  /// SingletonDI.registerFactory<MyService>(() => MyService());
  /// await SingletonDIAccess.add<MyService>();
  /// ```
  static Future<void> add<T extends Object>() =>
      SingletonManager.instance.add<T>();

  /// Registers a singleton by interface with a concrete implementation via
  /// [SingletonManager.instance].
  ///
  /// This is a static convenience method that delegates to
  /// [SingletonManager.instance.addAs<I, T>()].
  ///
  /// Registers [I] as the key but stores an instance of [T].
  ///
  /// Example:
  /// ```dart
  /// SingletonDI.registerFactory<RepositoryImpl>(() => RepositoryImpl());
  /// await SingletonDIAccess.addAs<IRepository, RepositoryImpl>();
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
  /// final service = SingletonDIAccess.get<MyService>();
  /// ```
  static T get<T extends Object>() => SingletonManager.instance.get<T>();

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
  /// SingletonDIAccess.remove<MyService>();
  /// ```
  static void remove<T extends Object>() =>
      SingletonManager.instance.remove<T>();
}
