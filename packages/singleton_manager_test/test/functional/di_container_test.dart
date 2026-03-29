import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

/// Simulates a real-world application structure
class AppDependencyContainer {
  final IRegistry<String> _services = RegistryManager();

  void registerDatabaseService() {
    _services.register<SimpleService>(
      'db',
      SimpleService.counted(name: 'DatabaseService'),
    );
  }

  void registerCacheService() {
    _services.registerLazy<SimpleService>(
      'cache',
      () => SimpleService.counted(name: 'CacheService'),
    );
  }

  void registerApiService() {
    _services.registerLazy<SimpleService>(
      'api',
      () => SimpleService.counted(name: 'ApiService'),
    );
  }

  void registerLoggerService() {
    _services.registerLazy<SimpleService>(
      'logger',
      () => SimpleService.counted(name: 'LoggerService'),
    );
  }

  SimpleService getService(String key) =>
      _services.getInstance<SimpleService>(key);

  void updateService(String key, SimpleService newService) {
    _services.replace<SimpleService>(key, newService);
  }

  void shutdown() => _services.destroyAll();

  int get serviceCount => _services.registrySize;

  Set<String> get serviceNames =>
      _services.keys.map((k) => k.$2).toSet();

  bool hasService(String key) => _services.contains<SimpleService>(key);
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

      final db = container.getService('db');
      expect(db.name, equals('DatabaseService'));

      final cache = container.getService('cache');
      expect(cache.name, equals('CacheService'));

      final api = container.getService('api');
      expect(api.name, equals('ApiService'));

      final logger = container.getService('logger');
      expect(logger.name, equals('LoggerService'));

      expect(container.getService('db'), same(db));
      expect(container.getService('cache'), same(cache));
      expect(container.getService('api'), same(api));
      expect(container.getService('logger'), same(logger));

      container.shutdown();
    });

    test('lazy services are created only when accessed', () {
      container
        ..registerDatabaseService()
        ..registerCacheService()
        ..registerApiService()
        ..registerLoggerService();

      expect(SimpleService.instantiationCount, equals(1));

      container.getService('cache');
      expect(SimpleService.instantiationCount, equals(2));

      container.getService('api');
      expect(SimpleService.instantiationCount, equals(3));

      container.getService('logger');
      expect(SimpleService.instantiationCount, equals(4));

      container
        ..getService('cache')
        ..getService('api')
        ..getService('logger');
      expect(SimpleService.instantiationCount, equals(4));
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

      expect(identical(db1, db2), isFalse);

      container1.shutdown();
      container2.shutdown();

      expect(db1.destroyed, isTrue);
      expect(db2.destroyed, isTrue);
    });

    test('partial service activation pattern', () {
      container.registerDatabaseService();
      expect(container.serviceCount, equals(1));

      container.registerCacheService();
      expect(container.serviceCount, equals(2));

      container.registerApiService();
      expect(container.serviceCount, equals(3));

      container.registerLoggerService();
      expect(container.serviceCount, equals(4));

      expect(container.hasService('db'), isTrue);
      expect(container.hasService('cache'), isTrue);
      expect(container.hasService('api'), isTrue);
      expect(container.hasService('logger'), isTrue);
    });

    test('service dependency chain', () {
      container
        ..registerDatabaseService()
        ..registerCacheService()
        ..registerApiService()
        ..registerLoggerService();

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

      final newDb = SimpleService(name: 'DatabaseService-reloaded');
      container.updateService('db', newDb);

      expect(originalDb.destroyed, isTrue);
      expect(container.getService('db'), same(newDb));

      expect(container.getService('cache'), same(originalCache));
      expect(originalCache.destroyed, isFalse);
    });

    test('error recovery pattern: graceful degradation', () {
      container
        ..registerDatabaseService()
        ..registerCacheService();

      final cache = container.getService('cache');
      expect(cache, isNotNull);

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

      final services = container.serviceNames;
      expect(services, hasLength(3));

      container.shutdown();
      expect(container.serviceCount, equals(0));
    });

    test('service validation and status checks', () {
      container
        ..registerDatabaseService()
        ..registerCacheService();

      for (final serviceName in ['db', 'cache']) {
        expect(container.hasService(serviceName), isTrue);
        final service = container.getService(serviceName);
        expect(service.destroyed, isFalse);
      }

      final dbService = container.getService('db');
      final cacheService = container.getService('cache');

      container.shutdown();

      expect(container.serviceCount, equals(0));
      expect(container.hasService('db'), isFalse);
      expect(container.hasService('cache'), isFalse);

      expect(dbService.destroyed, isTrue);
      expect(cacheService.destroyed, isTrue);
    });

    test('configuration update pattern', () {
      container.registerDatabaseService();

      final oldDb = container.getService('db');

      final configuredDb = SimpleService(name: 'DatabaseService-configured');
      container.updateService('db', configuredDb);

      expect(oldDb.destroyed, isTrue);
      expect(container.getService('db'), same(configuredDb));
    });

    test('scaling pattern: adding multiple services', () {
      container
        ..registerDatabaseService()
        ..registerCacheService();

      expect(container.serviceCount, equals(2));

      container.registerApiService();

      expect(container.serviceCount, equals(3));
      expect(container.serviceNames.length, equals(3));
    });
  });
}
