import 'package:singleton_manager/src/interfaces/i_value_for_registry.dart';
import 'package:singleton_manager/src/mixin/registry_core.dart';
import 'package:singleton_manager/src/mixin/registry_entry.dart';
import 'package:singleton_manager/src/mixin/value_with_version.dart';

mixin RegistryOnlyKey<Key> {
  final RegistryCore<(Type, Key)> _core = RegistryCore<(Type, Key)>();

  /// Registers an eager value identified by type [T] and [key].
  /// Throws DuplicateRegistrationError if the (T, key) pair already exists.
  void register<T extends IValueForRegistry>(Key key, T value) =>
      _core.store((T, key), value);

  /// Registers a lazy value identified by type [T] and [key].
  /// The factory is called only when [getInstance] is first called.
  /// Throws DuplicateRegistrationError if the (T, key) pair already exists.
  void registerLazy<T extends IValueForRegistry>(
    Key key,
    T Function() factory,
  ) =>
      _core.storeLazy((T, key), factory);

  /// Replaces an existing eager value identified by type [T] and [key].
  /// Throws RegistryNotFoundError if the (T, key) pair does not exist.
  void replace<T extends IValueForRegistry>(Key key, T value) =>
      _core.replace((T, key), value);

  /// Replaces an existing lazy value identified by type [T] and [key].
  /// Throws RegistryNotFoundError if the (T, key) pair does not exist.
  void replaceLazy<T extends IValueForRegistry>(
    Key key,
    T Function() factory,
  ) =>
      _core.replaceLazy((T, key), factory);

  /// Retrieves a value by type [T] and [key], resolving lazy entries if needed.
  /// Throws RegistryNotFoundError if the (T, key) pair does not exist.
  T getInstance<T extends IValueForRegistry>(Key key) =>
      _core.resolve((T, key)) as T;

  /// Unregisters a value identified by type [T] and [key].
  ValueWithVersion<RegistryEntry<IValueForRegistry>>?
      unregister<T extends IValueForRegistry>(Key key) =>
          _core.remove((T, key));

  /// Retrieves the version container by type [T] and [key]
  /// without resolving lazy entries.
  ValueWithVersion<RegistryEntry<IValueForRegistry>>?
      getByKey<T extends IValueForRegistry>(Key key) =>
          _core.getVersioned((T, key));

  /// Checks if a (T, key) pair exists in the registry.
  bool contains<T extends IValueForRegistry>(Key key) =>
      _core.containsKey((T, key));

  /// Returns all compound keys (Type, Key) in the registry.
  Set<(Type, Key)> get keys => _core.keys;

  /// Returns true if the registry is empty.
  bool get isEmpty => _core.isEmpty;

  /// Returns true if the registry is not empty.
  bool get isNotEmpty => _core.isNotEmpty;

  /// Returns the number of registered entries.
  int get registrySize => _core.size;

  /// Clears the registry (does not call destroy on values).
  void clearRegistry() => _core.clear();

  /// Destroys all values and clears the registry.
  void destroyAll() => _core.destroyAll();
}
