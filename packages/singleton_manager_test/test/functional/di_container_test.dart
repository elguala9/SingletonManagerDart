import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

/// Simulates a real-world application structure
class AppDependencyContainer {
  final RegistryManager<String, SimpleService> _services = RegistryManager();

  void registerDatabaseService() {
    _services.register('db', SimpleService.counted(name: 'DatabaseService'));
  }

  void registerCacheService() {
    _services.registerLazy(
      'cache',
      () => SimpleService.counted(name: 'CacheService'),
    );
  }

  void registerApiService() {
    _services.registerLazy(
      'api',
      () => SimpleService.counted(name: 'ApiService'),
    );
  }

  void registerLoggerService() {
    _services.registerLazy(
      'logger',
      () => SimpleService.counted(name: 'LoggerService'),
    );
  }

  SimpleService getService(String key) => _services.getInstance(key);

  void updateService(String key, SimpleService newService) {
    _services.replace(key, newService);
  }

  void shutdown() => _services.destroyAll();

  int get serviceCount => _services.registrySize;

  Set<String> get serviceNames => _services.keys;

  bool hasService(String key) => _services.contains(key);
}

void main() {
  group('RegistryManager - DI Container Integration', () {
    late AppDependencyContainer container;

    setUp(() {
      SimpleService.instantiationCount = 0;
      container = AppDependencyContainer();
    });

    tearDown(() {
      container.shutdown();
    });

    test('complete application lifecycle with DI container', () {
      // Bootstrap
      container
        ..registerDatabaseService()
        ..registerCacheService()
        ..registerApiService()
        ..registerLoggerService();

      expect(container.serviceCount, equals(4));
      expect(
        container.serviceNames,
        containsAll(['db', 'cache', 'api', 'logger']),
      );

      // Use services
      final db = container.getService('db');
      expect(db.name, equals('DatabaseService'));

      final cache = container.getService('cache');
      expect(cache.name, equals('CacheService'));

      final api = container.getService('api');
      expect(api.name, equals('ApiService'));

      final logger = container.getService('logger');
      expect(logger.name, equals('LoggerService'));

      // Verify singletons
      expect(container.getService('db'), same(db));
      expect(container.getService('cache'), same(cache));
      expect(container.getService('api'), same(api));
      expect(container.getService('logger'), same(logger));

      // Shutdown
      container.shutdown();
    });

    test('lazy services are created only when accessed', () {
      container
        ..registerDatabaseService() // Eager
        ..registerCacheService() // Lazy
        ..registerApiService() // Lazy
        ..registerLoggerService(); // Lazy

      // Only database should be instantiated
      expect(SimpleService.instantiationCount, equals(1)); // Only DB

      // Access cache
      container.getService('cache');
      expect(SimpleService.instantiationCount, equals(2)); // DB + Cache

      // Access api
      container.getService('api');
      expect(SimpleService.instantiationCount, equals(3)); // DB + Cache + API

      // Access logger
      container.getService('logger');
      expect(SimpleService.instantiationCount, equals(4)); // All 4

      // Access again - no new creations
      container
        ..getService('cache')
        ..getService('api')
        ..getService('logger');
      expect(SimpleService.instantiationCount, equals(4)); // Still 4
    });

    test('service replacement with cleanup', () {
      container.registerDatabaseService();
      final originalDb = container.getService('db');
      expect(originalDb.destroyed, isFalse);

      final newDb = SimpleService(name: 'DatabaseService-v2');
      container.updateService('db', newDb);

      expect(originalDb.destroyed, isTrue);
      expect(container.getService('db').name, contains('v2'));
    });

    test('multi-registry scenario: multiple containers', () {
      final container1 = AppDependencyContainer();
      final container2 = AppDependencyContainer();

      container1.registerDatabaseService();
      container2.registerDatabaseService();

      final db1 = container1.getService('db');
      final db2 = container2.getService('db');

      // Different instances
      expect(identical(db1, db2), isFalse);

      container1.shutdown();
      container2.shutdown();

      expect(db1.destroyed, isTrue);
      expect(db2.destroyed, isTrue);
    });

    test('partial service activation pattern', () {
      // Start with essential services
      container.registerDatabaseService();
      expect(container.serviceCount, equals(1));

      // Add more services later
      container.registerCacheService();
      expect(container.serviceCount, equals(2));

      container.registerApiService();
      expect(container.serviceCount, equals(3));

      container.registerLoggerService();
      expect(container.serviceCount, equals(4));

      // Verify all are accessible
      expect(container.hasService('db'), isTrue);
      expect(container.hasService('cache'), isTrue);
      expect(container.hasService('api'), isTrue);
      expect(container.hasService('logger'), isTrue);
    });

    test('service dependency chain', () {
      // Register services
      container
        ..registerDatabaseService() // Depends on nothing
        ..registerCacheService() // Could depend on DB
        ..registerApiService() // Could depend on DB and Cache
        ..registerLoggerService(); // Could depend on all

      // In real app, services might have constructor parameters
      // Here we verify the dependency injection works structurally
      final db = container.getService('db');
      final cache = container.getService('cache');
      final api = container.getService('api');
      final logger = container.getService('logger');

      expect(db, isNotNull);
      expect(cache, isNotNull);
      expect(api, isNotNull);
      expect(logger, isNotNull);
    });

    test('hot reload pattern: service update without restart', () {
      container
        ..registerDatabaseService()
        ..registerCacheService();

      final originalDb = container.getService('db');
      final originalCache = container.getService('cache');

      // Simulate hot reload - update critical services
      final newDb = SimpleService(name: 'DatabaseService-reloaded');
      container.updateService('db', newDb);

      expect(originalDb.destroyed, isTrue);
      expect(container.getService('db'), same(newDb));

      // Cache is still the original
      expect(container.getService('cache'), same(originalCache));
      expect(originalCache.destroyed, isFalse);
    });

    test('error recovery pattern: graceful degradation', () {
      container
        ..registerDatabaseService()
        ..registerCacheService();

      // Get cache - should work normally
      final cache = container.getService('cache');
      expect(cache, isNotNull);

      // Replace with new implementation
      final improvedCache = SimpleService(name: 'CacheService-optimized');
      container.updateService('cache', improvedCache);

      expect(cache.destroyed, isTrue);
      expect(container.getService('cache'), same(improvedCache));
    });

    test('selective shutdown pattern', () {
      container
        ..registerDatabaseService()
        ..registerCacheService()
        ..registerApiService();

      expect(container.serviceCount, equals(3));

      // In real scenario, you might selectively destroy
      // Here we verify the structure supports it
      final services = container.serviceNames;
      expect(services, hasLength(3));

      container.shutdown();
      expect(container.serviceCount, equals(0));
    });

    test('service validation and status checks', () {
      container
        ..registerDatabaseService()
        ..registerCacheService();

      // Check all services are available
      for (final serviceName in ['db', 'cache']) {
        expect(container.hasService(serviceName), isTrue);
        final service = container.getService(serviceName);
        expect(service.destroyed, isFalse);
      }

      // Keep references before shutdown
      final dbService = container.getService('db');
      final cacheService = container.getService('cache');

      container.shutdown();

      // After shutdown, registry should be empty
      expect(container.serviceCount, equals(0));
      expect(container.hasService('db'), isFalse);
      expect(container.hasService('cache'), isFalse);

      // But the service objects themselves should be destroyed
      expect(dbService.destroyed, isTrue);
      expect(cacheService.destroyed, isTrue);
    });

    test('configuration update pattern', () {
      // Register initial configuration
      container.registerDatabaseService();

      final oldDb = container.getService('db');

      // Update configuration
      final configuredDb = SimpleService(name: 'DatabaseService-configured');
      container.updateService('db', configuredDb);

      expect(oldDb.destroyed, isTrue);
      expect(container.getService('db'), same(configuredDb));
    });

    test('scaling pattern: adding multiple instances of same type', () {
      // Register primary instances
      container
        ..registerDatabaseService()
        ..registerCacheService();

      expect(container.serviceCount, equals(2));

      // In a real scenario, you might add replicas
      // Here we show the structure supports it
      container.registerApiService(); // Add another service

      expect(container.serviceCount, equals(3));
      expect(container.serviceNames.length, equals(3));
    });
  });
}
