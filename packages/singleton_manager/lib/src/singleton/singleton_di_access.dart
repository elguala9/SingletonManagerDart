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

  static Future<void> add<T extends ISingletonDI<dynamic>>() =>
      SingletonManager.instance.add<T>();

  static Future<void> addAs<I extends ISingletonDI<dynamic>,
      T extends I>() => SingletonManager.instance.addAs<I, T>();

  static Future<void> addInstance<T extends Object>(
      T instance) =>
      SingletonManager.instance.addInstance<T>(instance);

  static Future<void> addInstanceAs<
      I extends Object,
      T extends I>(T instance) =>
      SingletonManager.instance.addInstanceAs<I, T>(instance);

  static T get<T extends Object>() =>
      SingletonManager.instance.get<T>();

  static void remove<T extends Object>() =>
      SingletonManager.instance.remove<T>();
}
