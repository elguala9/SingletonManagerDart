import 'package:singleton_manager/src/errors/registry_errors.dart';
import 'package:singleton_manager/src/interfaces/i_value_for_registry.dart';
import 'package:singleton_manager/src/mixin/registry_entry.dart';
import 'package:singleton_manager/src/mixin/value_with_version.dart';

/// Internal backing store shared by Registry and RegistryOnlyKey.
/// Not part of the public API.
class RegistryCore<K> {
  final Map<K, ValueWithVersion<RegistryEntry<IValueForRegistry>>> _map = {};

  void store(K key, IValueForRegistry value) {
    if (_map.containsKey(key)) {
      throw DuplicateRegistrationError(
        'Key $key is already registered. Use replace() to update it.',
      );
    }
    _map[key] = ValueWithVersion(EagerEntry(value), 0);
  }

  void storeLazy(K key, IValueForRegistry Function() factory) {
    if (_map.containsKey(key)) {
      throw DuplicateRegistrationError(
        'Key $key is already registered. Use replaceLazy() to update it.',
      );
    }
    _map[key] = ValueWithVersion(LazyEntry(factory), 0);
  }

  void replace(K key, IValueForRegistry value) {
    final existing = _map[key];
    if (existing == null) {
      throw RegistryNotFoundError('Key $key not found');
    }
    existing.value.destroy();
    _map[key] = ValueWithVersion(EagerEntry(value), existing.version + 1);
  }

  void replaceLazy(K key, IValueForRegistry Function() factory) {
    final existing = _map[key];
    if (existing == null) {
      throw RegistryNotFoundError('Key $key not found');
    }
    existing.value.destroy();
    _map[key] = ValueWithVersion(LazyEntry(factory), existing.version + 1);
  }

  IValueForRegistry resolve(K key) {
    final item = _map[key];
    if (item == null) {
      throw RegistryNotFoundError('Instance not found for key: $key');
    }
    final entry = item.value;
    if (entry is LazyEntry) {
      return entry.resolvedValue;
    }
    if (entry is EagerEntry) {
      return entry.value;
    }
    throw RegistryNotFoundError('Invalid entry type for key: $key');
  }

  ValueWithVersion<RegistryEntry<IValueForRegistry>>? remove(K key) =>
      _map.remove(key);

  ValueWithVersion<RegistryEntry<IValueForRegistry>>? getVersioned(K key) =>
      _map[key];

  bool containsKey(K key) => _map.containsKey(key);

  Set<K> get keys => _map.keys.toSet();

  bool get isEmpty => _map.isEmpty;

  bool get isNotEmpty => _map.isNotEmpty;

  int get size => _map.length;

  void clear() => _map.clear();

  void destroyAll() {
    final items = _map.values.toList();
    for (final item in items) {
      item.value.destroy();
    }
    _map.clear();
  }
}
