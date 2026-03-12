import 'package:singleton_manager/src/errors/registry_errors.dart';
import 'package:singleton_manager/src/interfaces/i_value_for_registry.dart';
import 'package:singleton_manager/src/mixin/registry_entry.dart';
import 'package:singleton_manager/src/mixin/value_with_version.dart';

mixin Registry<Key, Value extends IValueForRegistry> {
  final Map<Key, ValueWithVersion<RegistryEntry<Value>>> _registry = {};

  /// Registers an eager value for the given key.
  /// Throws [DuplicateRegistrationError] if the key already exists.
  void register(Key key, Value value) {
    if (_registry.containsKey(key)) {
      throw DuplicateRegistrationError(
        'Key $key is already registered. Use replace() to update it.',
      );
    }
    _registry[key] = ValueWithVersion<RegistryEntry<Value>>(
      EagerEntry(value),
      0,
    );
  }

  /// Registers a lazy value (factory function) for the given key.
  /// The factory is called only when [getInstance] is first called.
  /// Throws [DuplicateRegistrationError] if the key already exists.
  void registerLazy(Key key, Value Function() factory) {
    if (_registry.containsKey(key)) {
      throw DuplicateRegistrationError(
        'Key $key is already registered. Use replaceLazy() to update it.',
      );
    }
    _registry[key] = ValueWithVersion<RegistryEntry<Value>>(
      LazyEntry(factory),
      0,
    );
  }

  /// Replaces an existing eager value.
  /// Throws [RegistryNotFoundError] if the key does not exist.
  void replace(Key key, Value value) {
    final existing = _registry[key];
    if (existing == null) {
      throw RegistryNotFoundError('Key $key not found');
    }
    existing.value.destroy();
    _registry[key] = ValueWithVersion<RegistryEntry<Value>>(
      EagerEntry(value),
      existing.version + 1,
    );
  }

  /// Replaces an existing lazy value.
  /// Throws [RegistryNotFoundError] if the key does not exist.
  void replaceLazy(Key key, Value Function() factory) {
    final existing = _registry[key];
    if (existing == null) {
      throw RegistryNotFoundError('Key $key not found');
    }
    existing.value.destroy();
    _registry[key] = ValueWithVersion<RegistryEntry<Value>>(
      LazyEntry(factory),
      existing.version + 1,
    );
  }

  /// Retrieves a value by key, resolving lazy entries if needed.
  /// Throws [RegistryNotFoundError] if the key does not exist.
  Value getInstance(Key key) {
    final item = _registry[key];
    if (item == null) {
      throw RegistryNotFoundError('Instance not found for key: $key');
    }
    final entry = item.value;
    if (entry is LazyEntry<Value>) {
      return entry.resolvedValue;
    } else if (entry is EagerEntry<Value>) {
      return entry.value;
    }
    throw RegistryNotFoundError('Invalid entry type for key: $key');
  }

  /// Unregisters a value by key.
  ValueWithVersion<RegistryEntry<Value>>? unregister(Key key) =>
      _registry.remove(key);

  /// Retrieves the version container by key without resolving lazy entries.
  ValueWithVersion<RegistryEntry<Value>>? getByKey(Key key) =>
      _registry[key];

  /// Checks if a key exists in the registry.
  bool contains(Key key) => _registry.containsKey(key);

  /// Returns all keys in the registry.
  Set<Key> get keys => _registry.keys.toSet();

  /// Returns true if the registry is empty.
  bool get isEmpty => _registry.isEmpty;

  /// Returns true if the registry is not empty.
  bool get isNotEmpty => _registry.isNotEmpty;

  /// Returns the number of registered entries.
  int get registrySize => _registry.length;

  /// Clears the registry (does not call destroy on values).
  void clearRegistry() => _registry.clear();

  /// Destroys all values and clears the registry.
  void destroyAll() {
    final items = _registry.values.toList();
    for (final item in items) {
      item.value.destroy();
    }
    _registry.clear();
  }
}
