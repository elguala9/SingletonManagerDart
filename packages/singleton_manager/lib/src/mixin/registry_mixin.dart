import 'package:singleton_manager/src/interfaces/i_value_for_registry.dart';
import 'package:singleton_manager/src/mixin/registry_core.dart';
import 'package:singleton_manager/src/mixin/registry_entry.dart';
import 'package:singleton_manager/src/mixin/value_with_version.dart';

mixin Registry<Key, Value extends IValueForRegistry> {
  final RegistryCore<Key> _core = RegistryCore<Key>();

  /// Registers an eager value for the given key.
  /// Throws DuplicateRegistrationError if the key already exists.
  void register(Key key, Value value) => _core.store(key, value);

  /// Registers a lazy value (factory function) for the given key.
  /// The factory is called only when [getInstance] is first called.
  /// Throws DuplicateRegistrationError if the key already exists.
  void registerLazy(Key key, Value Function() factory) =>
      _core.storeLazy(key, factory);

  /// Replaces an existing eager value.
  /// Throws RegistryNotFoundError if the key does not exist.
  void replace(Key key, Value value) => _core.replace(key, value);

  /// Replaces an existing lazy value.
  /// Throws RegistryNotFoundError if the key does not exist.
  void replaceLazy(Key key, Value Function() factory) =>
      _core.replaceLazy(key, factory);

  /// Retrieves a value by key, resolving lazy entries if needed.
  /// Throws RegistryNotFoundError if the key does not exist.
  Value getInstance(Key key) => _core.resolve(key) as Value;

  /// Unregisters a value by key.
  ValueWithVersion<RegistryEntry<IValueForRegistry>>? unregister(Key key) =>
      _core.remove(key);

  /// Retrieves the version container by key without resolving lazy entries.
  ValueWithVersion<RegistryEntry<IValueForRegistry>>? getByKey(Key key) =>
      _core.getVersioned(key);

  /// Checks if a key exists in the registry.
  bool contains(Key key) => _core.containsKey(key);

  /// Returns all keys in the registry.
  Set<Key> get keys => _core.keys;

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
