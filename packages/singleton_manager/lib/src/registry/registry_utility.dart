import 'package:singleton_manager/src/mixin/i_value_for_registry.dart';
import 'package:singleton_manager/src/mixin/registry_mixin.dart';

/// Generic registry manager for managing objects that implement
/// [IValueForRegistry].
///
/// This class provides a simple way to register, retrieve, and manage
/// objects that implement [IValueForRegistry].
///
/// Example usage:
/// ```dart
/// final registry = RegistryManager<String, MyService>();
/// registry.register('service', myService);
/// registry.registerLazy('lazy', () => MyService());
/// final service = registry.getInstance('service');
/// ```
class RegistryManager<Key, Value extends IValueForRegistry>
    with Registry<Key, Value> {
  /// Creates a new [RegistryManager] instance.
  RegistryManager();
}
