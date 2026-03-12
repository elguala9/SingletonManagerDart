// ignore_for_file: avoid_print,file_names,sort_constructors_first,cascade_invocations,unnecessary_lambdas,lines_longer_than_80_chars
import 'package:singleton_manager/singleton_manager.dart';

/// Example 2: Registry Mixin - Eager and Lazy Registration
///
/// The Registry mixin provides a flexible key-value registry with support for:
/// - Eager registration: Create and store immediately
/// - Lazy registration: Create on first access (factory pattern)
/// - Replace and version tracking

abstract class Service implements IValueForRegistry {
  String get name;
  void printInfo();
}

class DatabaseService extends Service {
  final int connectionId;

  DatabaseService({required this.connectionId}) {
    print('✓ DatabaseService created (connection: $connectionId)');
  }

  @override
  String get name => 'DatabaseService';

  @override
  void printInfo() => print('Database connected on port: $connectionId');

  @override
  void destroy() {
    print('✗ DatabaseService destroyed');
  }
}

class CacheService extends Service {
  CacheService() {
    print('✓ CacheService created');
  }

  @override
  String get name => 'CacheService';

  @override
  void printInfo() => print('Cache service ready');

  @override
  void destroy() {
    print('✗ CacheService destroyed');
  }
}

class ApiService extends Service {
  ApiService() {
    print('✓ ApiService created');
  }

  @override
  String get name => 'ApiService';

  @override
  void printInfo() => print('API service ready');

  @override
  void destroy() {
    print('✗ ApiService destroyed');
  }
}

class ServiceRegistry with Registry<String, Service> {
  // Mixin provides all registry functionality
}

void main() {
  final registry = ServiceRegistry();

  print('=== Registry: Eager and Lazy Loading ===\n');

  // Step 1: Eager Registration
  print('Step 1: Eager Registration (created immediately)');
  registry.register('db', DatabaseService(connectionId: 5432));
  registry.register('cache', CacheService());
  print('Registry size: ${registry.registrySize}\n');

  // Step 2: Lazy Registration
  print('Step 2: Lazy Registration (created on first access)');
  print('Registering ApiService lazily...');
  registry.registerLazy('api', () => ApiService());
  print('Registry size: ${registry.registrySize}');
  print('(Note: ApiService not created yet)\n');

  // Step 3: Access lazy service (triggers creation)
  print('Step 3: Access lazy service');
  final api = registry.getInstance('api');
  api.printInfo();
  print('(ApiService created on first access)\n');

  // Step 4: Verify singleton behavior
  print('Step 4: Verify singleton behavior');
  final api2 = registry.getInstance('api');
  print('Same instance: ${identical(api, api2)}\n');

  // Step 5: Get all keys
  print('Step 5: List all services');
  for (final key in registry.keys) {
    final service = registry.getInstance(key);
    print('  - $key: ${service.name}');
  }
  print('');

  // Step 6: Check if service exists
  print('Step 6: Check existence');
  print('Contains "db": ${registry.contains('db')}');
  print('Contains "unknown": ${registry.contains('unknown')}\n');

  // Step 7: Replace eager service
  print('Step 7: Replace service');
  registry.replace('db', DatabaseService(connectionId: 3306));
  final newDb = registry.getInstance('db');
  newDb.printInfo();
  print('');

  // Step 8: Replace lazy service
  print('Step 8: Replace lazy service');
  registry.replaceLazy('cache', () {
    print('✓ New CacheService created (from lazy factory)');
    return CacheService();
  });
  final newCache = registry.getInstance('cache');
  newCache.printInfo();
  print('');

  // Step 9: Registry info
  print('Step 9: Registry info');
  print('Is empty: ${registry.isEmpty}');
  print('Is not empty: ${registry.isNotEmpty}');
  print('Size: ${registry.registrySize}\n');

  // Step 10: Destroy all
  print('Step 10: Clean up');
  registry.destroyAll();
  print('All services destroyed and registry cleared');
  print('Size after destroy: ${registry.registrySize}');
}
