import 'package:singleton_manager/src/errors/registry_errors.dart';
import 'package:singleton_manager/src/interfaces/i_value_for_registry.dart';
import 'package:singleton_manager/src/mixin/registry_entry.dart';
import 'package:singleton_manager/src/mixin/value_with_version.dart';

abstract class IRegistry<Key> {
  /// Registers an eager value identified by type [T] and [key].
  /// Throws [DuplicateRegistrationError] if the (T, key) pair already exists.
  void register<T extends IValueForRegistry>(Key key, T value);

  /// Registers a lazy value (factory function) identified by type [T]
  /// and [key].
  /// The factory is called only when [getInstance] is first called.
  /// Throws [DuplicateRegistrationError] if the (T, key) pair already exists.
  void registerLazy<T extends IValueForRegistry>(Key key, T Function() factory);

  /// Replaces an existing eager value identified by type [T] and [key].
  /// Throws [RegistryNotFoundError] if the (T, key) pair does not exist.
  void replace<T extends IValueForRegistry>(Key key, T value);

  /// Replaces an existing lazy value identified by type [T] and [key].
  /// Throws [RegistryNotFoundError] if the (T, key) pair does not exist.
  void replaceLazy<T extends IValueForRegistry>(Key key, T Function() factory);

  /// Retrieves a value by type [T] and [key], resolving lazy entries if needed.
  /// Throws [RegistryNotFoundError] if the (T, key) pair does not exist.
  T getInstance<T extends IValueForRegistry>(Key key);

  /// Unregisters a value identified by type [T] and [key].
  ValueWithVersion<RegistryEntry<IValueForRegistry>>?
      unregister<T extends IValueForRegistry>(Key key);

  /// Retrieves the version container by type [T] and [key]
  /// without resolving lazy entries.
  ValueWithVersion<RegistryEntry<IValueForRegistry>>?
      getByKey<T extends IValueForRegistry>(Key key);

  /// Checks if a (T, key) pair exists in the registry.
  bool contains<T extends IValueForRegistry>(Key key);

  /// Returns all compound keys (Type, Key) in the registry.
  Set<(Type, Key)> get keys;

  /// Returns true if the registry is empty.
  bool get isEmpty;

  /// Returns true if the registry is not empty.
  bool get isNotEmpty;

  /// Returns the number of registered entries.
  int get registrySize;

  /// Clears the registry (does not call destroy on values).
  void clearRegistry();

  /// Destroys all values and clears the registry.
  void destroyAll();
}
