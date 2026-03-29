import 'package:singleton_manager/src/errors/registry_errors.dart';
import 'package:singleton_manager/src/interfaces/i_value_for_registry.dart';
import 'package:singleton_manager/src/mixin/registry_entry.dart';
import 'package:singleton_manager/src/mixin/value_with_version.dart';

mixin Registry<Key> {
  final Map<(Type, Key), ValueWithVersion<RegistryEntry<IValueForRegistry>>>
      _registry = {};

  /// Registers an eager value identified by type [T] and [key].
  /// Throws [DuplicateRegistrationError] if the (T, key) pair already exists.
  void register<T extends IValueForRegistry>(Key key, T value) {
    final k = (T, key);
    if (_registry.containsKey(k)) {
      throw DuplicateRegistrationError(
        'Type $T with key $key is already registered. '
        'Use replace() to update it.',
      );
    }
    _registry[k] = ValueWithVersion(EagerEntry<T>(value), 0);
  }

  /// Registers a lazy value (factory function) identified by type [T]
  /// and [key].
  /// The factory is called only when [getInstance] is first called.
  /// Throws [DuplicateRegistrationError] if the (T, key) pair already exists.
  void registerLazy<T extends IValueForRegistry>(
    Key key,
    T Function() factory,
  ) {
    final k = (T, key);
    if (_registry.containsKey(k)) {
      throw DuplicateRegistrationError(
        'Type $T with key $key is already registered. '
        'Use replaceLazy() to update it.',
      );
    }
    _registry[k] = ValueWithVersion(LazyEntry<T>(factory), 0);
  }

  /// Replaces an existing eager value identified by type [T] and [key].
  /// Throws [RegistryNotFoundError] if the (T, key) pair does not exist.
  void replace<T extends IValueForRegistry>(Key key, T value) {
    final k = (T, key);
    final existing = _registry[k];
    if (existing == null) {
      throw RegistryNotFoundError('Type $T with key $key not found');
    }
    existing.value.destroy();
    _registry[k] = ValueWithVersion(EagerEntry<T>(value), existing.version + 1);
  }

  /// Replaces an existing lazy value identified by type [T] and [key].
  /// Throws [RegistryNotFoundError] if the (T, key) pair does not exist.
  void replaceLazy<T extends IValueForRegistry>(
    Key key,
    T Function() factory,
  ) {
    final k = (T, key);
    final existing = _registry[k];
    if (existing == null) {
      throw RegistryNotFoundError('Type $T with key $key not found');
    }
    existing.value.destroy();
    _registry[k] =
        ValueWithVersion(LazyEntry<T>(factory), existing.version + 1);
  }

  /// Retrieves a value by type [T] and [key], resolving lazy entries if needed.
  /// Throws [RegistryNotFoundError] if the (T, key) pair does not exist.
  T getInstance<T extends IValueForRegistry>(Key key) {
    final item = _registry[(T, key)];
    if (item == null) {
      throw RegistryNotFoundError('Type $T not found for key $key');
    }
    final entry = item.value;
    if (entry is EagerEntry) {
      return entry.value as T;
    }
    if (entry is LazyEntry) {
      return entry.resolvedValue as T;
    }
    throw RegistryNotFoundError('Invalid entry for type $T / key $key');
  }

  /// Unregisters a value identified by type [T] and [key].
  ValueWithVersion<RegistryEntry<IValueForRegistry>>?
      unregister<T extends IValueForRegistry>(Key key) =>
          _registry.remove((T, key));

  /// Retrieves the version container by type [T] and [key]
  /// without resolving lazy entries.
  ValueWithVersion<RegistryEntry<IValueForRegistry>>?
      getByKey<T extends IValueForRegistry>(Key key) =>
          _registry[(T, key)];

  /// Checks if a (T, key) pair exists in the registry.
  bool contains<T extends IValueForRegistry>(Key key) =>
      _registry.containsKey((T, key));

  /// Returns all compound keys (Type, Key) in the registry.
  Set<(Type, Key)> get keys => _registry.keys.toSet();

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
    for (final item in _registry.values) {
      item.value.destroy();
    }
    _registry.clear();
  }
}
