// ignore_for_file: avoid_print,file_names,sort_constructors_first,cascade_invocations,omit_local_variable_types,lines_longer_than_80_chars
import 'package:singleton_manager/singleton_manager.dart';

/// Example 6: Version Tracking and Service Replacement
///
/// Shows how to:
/// - Track versions of registered services
/// - Replace services while maintaining version history
/// - Implement hot-reload patterns

class Configuration implements IValueForRegistry {
  final String environment;
  final String dbUrl;
  final int timeout;

  Configuration({
    required this.environment,
    required this.dbUrl,
    required this.timeout,
  }) {
    print('✓ Configuration created (env: $environment)');
  }

  void printInfo() {
    print('  Environment: $environment');
    print('  DB URL: $dbUrl');
    print('  Timeout: ${timeout}ms');
  }

  @override
  void destroy() {
    print('✗ Configuration destroyed (env: $environment)');
  }
}

class ConfigRegistry with Registry<String, Configuration> {
  void printVersionInfo() {
    print('\nVersion Tracking:');
    for (final key in keys) {
      final entry = getByKey(key);
      if (entry != null) {
        final config = getInstance(key);
        print('  $key: version ${entry.version}, env: ${config.environment}');
      }
    }
  }
}

void main() {
  final registry = ConfigRegistry();

  print('=== Version Tracking and Service Replacement ===\n');

  // ========== Initial Registration ==========
  print('Step 1: Initial Registration');
  registry.register('main', Configuration(
    environment: 'development',
    dbUrl: 'localhost:5432',
    timeout: 5000,
  ));
  registry.printVersionInfo();
  print('');

  // ========== Verify Initial State ==========
  print('Step 2: Verify Initial State');
  final config1 = registry.getInstance('main');
  config1.printInfo();
  print('');

  // ========== Replace Service (triggers version increment) ==========
  print('Step 3: Replace Service (hot reload)');
  print('Replacing configuration...');
  registry.replace('main', Configuration(
    environment: 'staging',
    dbUrl: 'staging.example.com:5432',
    timeout: 10000,
  ));
  registry.printVersionInfo();
  print('');

  // ========== Verify New Instance ==========
  print('Step 4: Verify New Instance');
  final config2 = registry.getInstance('main');
  config2.printInfo();
  print('Same instance as before: ${identical(config1, config2)}');
  print('');

  // ========== Multiple Replacements ==========
  print('Step 5: Multiple Replacements');
  for (var i = 1; i <= 2; i++) {
    print('Replacement $i...');
    registry.replace('main', Configuration(
      environment: 'production-$i',
      dbUrl: 'prod$i.example.com:5432',
      timeout: 15000 + (i * 1000),
    ));
    registry.printVersionInfo();
  }
  print('');

  // ========== Hot Reload with Multiple Services ==========
  print('Step 6: Hot Reload with Multiple Services');

  print('Registering secondary config...');
  registry.register('secondary', Configuration(
    environment: 'development-backup',
    dbUrl: 'backup.localhost:5433',
    timeout: 3000,
  ));

  print('Registering tertiary config...');
  registry.registerLazy('tertiary', () {
    print('    (Creating tertiary config)');
    return Configuration(
      environment: 'development-cache',
      dbUrl: 'cache.localhost:6379',
      timeout: 1000,
    );
  });
  registry.printVersionInfo();
  print('');

  // ========== Access Lazy Configuration ==========
  print('Step 7: Access Lazy Configuration');
  print('Accessing tertiary (will create it)...');
  final config3 = registry.getInstance('tertiary');
  config3.printInfo();
  registry.printVersionInfo();
  print('');

  // ========== Replace Lazy Configuration ==========
  print('Step 8: Replace Lazy Configuration');
  registry.replaceLazy('tertiary', () {
    print('    (Creating new tertiary config from factory)');
    return Configuration(
      environment: 'development-cache-v2',
      dbUrl: 'cache.localhost:7000',
      timeout: 2000,
    );
  });
  registry.printVersionInfo();
  print('');

  // ========== Summary ==========
  print('Step 9: Summary');
  print('Total configurations: ${registry.registrySize}');
  print('Is registry empty: ${registry.isEmpty}');
  print('All keys: ${registry.keys.join(", ")}\n');

  // ========== Cleanup ==========
  print('Step 10: Cleanup');
  registry.destroyAll();
  print('All configurations destroyed');
  print('Registry size: ${registry.registrySize}');
}
