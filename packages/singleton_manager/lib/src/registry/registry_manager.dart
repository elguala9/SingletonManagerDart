import 'package:singleton_manager/src/interfaces/i_registry.dart';
import 'package:singleton_manager/src/mixin/registry_mixin.dart';
import 'package:singleton_manager/src/mixin/registry_only_key_mixin.dart';

/// A registry with a fixed [String] key type.
///
/// Convenience specialisation of [Registry] for the common case where
/// instances are keyed by plain strings (e.g. environment names like
/// `'prod'`, `'dev'`).
///
/// Example usage:
/// ```dart
/// final registry = RegistryManager();
/// registry.register<MyService>('prod', myService);
/// final service = registry.getInstance<MyService>('prod');
/// ```
class RegistryManager
    with RegistryOnlyKey<String>
    implements IRegistry<String> {
  /// Creates a new [RegistryManager] instance.
  RegistryManager();
}

/// A registry with a fixed [String] key type.
///
/// Convenience specialisation of [Registry] for the common case where
/// instances are keyed by plain strings (e.g. environment names like
/// `'prod'`, `'dev'`).
///
/// Example usage:
/// ```dart
/// final registry = RegistryManager();
/// registry.register<MyService>('prod', myService);
/// final service = registry.getInstance<MyService>('prod');
/// ```
class RegistryManagerSingleton
    extends RegistryManager {
  factory RegistryManagerSingleton() => _instance;

  /// Creates a new [RegistryManagerSingleton] instance.
  RegistryManagerSingleton._();

  static final RegistryManagerSingleton _instance =
      RegistryManagerSingleton._();

  static RegistryManagerSingleton get instance => _instance;
}
