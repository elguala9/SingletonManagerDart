import 'package:singleton_manager/singleton_manager.dart';

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

  // <dynamic, dynamic> necessary to avoid warning, but i do not know the
  // value in this moment
  static Future<void> add<T extends ISingleton<dynamic, dynamic>>() =>
      SingletonManager.instance.add<T>();

  // <dynamic, dynamic> necessary to avoid warning, but i do not know the
  // value in this moment
  static Future<void> addAs<I extends ISingleton<dynamic, dynamic>,
      T extends I>() => SingletonManager.instance.addAs<I, T>();

  static Future<void> addInstance<T extends ISingleton<dynamic, dynamic>>(
      T instance) =>
      SingletonManager.instance.addInstance<T>(instance);

  static Future<void> addInstanceAs<
      I extends ISingleton<dynamic, dynamic>,
      T extends I>(T instance) =>
      SingletonManager.instance.addInstanceAs<I, T>(instance);

  static T get<T extends ISingleton<dynamic, dynamic>>() =>
      SingletonManager.instance.get<T>();

  static void remove<T extends ISingleton<dynamic, dynamic>>() =>
      SingletonManager.instance.remove<T>();
}
