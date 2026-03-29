import 'package:singleton_manager/singleton_manager.dart' show DuplicateRegistrationError, RegistryNotFoundError;
import 'package:singleton_manager/src/errors/registry_errors.dart' show DuplicateRegistrationError, RegistryNotFoundError;
import 'package:singleton_manager/src/interfaces/i_registry.dart';
import 'package:singleton_manager/src/interfaces/i_value_for_registry.dart';
import 'package:singleton_manager/src/mixin/registry_entry.dart';
import 'package:singleton_manager/src/mixin/value_with_version.dart';
import 'package:singleton_manager/src/registry/registry_manager.dart';

/// Static convenience methods for accessing the global [String]-keyed registry.
///
/// Delegates all operations to the [RegistryManagerSingleton] global instance.
/// Each entry is identified by a compound key `(Type, String)`, so multiple
/// value types can share the same string key without collision.
///
/// Mirrors SingletonDIAccess in structure.
///
/// Example:
/// ```dart
/// RegistryAccess.register<MyService>('prod', MyService());
/// RegistryAccess.register<OtherService>('prod', OtherService());
///
/// final svc = RegistryAccess.getInstance<MyService>('prod');
/// ```
class RegistryAccess {
  // Private constructor - use static methods only
  RegistryAccess._();

  /// Returns the global [RegistryManagerSingleton] instance.
  static IRegistry<String> get instance => RegistryManagerSingleton.instance;

  /// Registers an eager [value] identified by type [T] and [key].
  /// Throws [DuplicateRegistrationError] if the (T, key) pair already exists.
  static void register<T extends IValueForRegistry>(String key, T value) =>
      instance.register<T>(key, value);

  /// Registers a lazy factory identified by type [T] and [key].
  /// Throws [DuplicateRegistrationError] if the (T, key) pair already exists.
  static void registerLazy<T extends IValueForRegistry>(
    String key,
    T Function() factory,
  ) =>
      instance.registerLazy<T>(key, factory);

  /// Replaces an existing eager value identified by type [T] and [key].
  /// Throws [RegistryNotFoundError] if the (T, key) pair does not exist.
  static void replace<T extends IValueForRegistry>(String key, T value) =>
      instance.replace<T>(key, value);

  /// Replaces an existing lazy factory identified by type [T] and [key].
  /// Throws [RegistryNotFoundError] if the (T, key) pair does not exist.
  static void replaceLazy<T extends IValueForRegistry>(
    String key,
    T Function() factory,
  ) =>
      instance.replaceLazy<T>(key, factory);

  /// Retrieves a value by type [T] and [key].
  /// Throws [RegistryNotFoundError] if the (T, key) pair does not exist.
  static T getInstance<T extends IValueForRegistry>(String key) =>
      instance.getInstance<T>(key);

  /// Returns true if the (T, key) pair is registered.
  static bool contains<T extends IValueForRegistry>(String key) =>
      instance.contains<T>(key);

  /// Unregisters the value identified by type [T] and [key].
  static ValueWithVersion<RegistryEntry<IValueForRegistry>>?
      unregister<T extends IValueForRegistry>(String key) =>
          instance.unregister<T>(key);

  /// Destroys all values and clears the global registry.
  static void destroyAll() => instance.destroyAll();

  /// Clears the global registry without calling destroy.
  static void clearRegistry() => instance.clearRegistry();
}
