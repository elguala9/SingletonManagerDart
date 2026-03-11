import 'package:singleton_manager/src/mixin/i_value_for_registry.dart';

/// Sealed class representing a registry entry that can be either eager or lazy
sealed class RegistryEntry<V extends IValueForRegistry>
    implements IValueForRegistry {}

/// Entry that stores a pre-created (eager) instance
final class EagerEntry<V extends IValueForRegistry>
    extends RegistryEntry<V> {
  /// Constructor
  EagerEntry(this.value);

  /// The pre-created value
  final V value;

  @override
  void destroy() => value.destroy();
}

/// Entry that stores a factory function for lazy instantiation
final class LazyEntry<V extends IValueForRegistry>
    extends RegistryEntry<V> {
  /// Constructor that accepts a factory function
  LazyEntry(this._factory);

  final V Function() _factory;
  V? _cached;

  /// Get the resolved value, creating it if needed
  V get resolvedValue => _cached ??= _factory();

  @override
  void destroy() => _cached?.destroy();
}
