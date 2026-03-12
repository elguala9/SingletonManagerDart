import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

/// Test fixture: A service that tracks its own lifecycle
class TrackedService implements IValueForRegistry {
  TrackedService({required this.id, this.name = 'TrackedService'});

  final String id;
  final String name;
  bool _isDestroyed = false;
  bool _isInitialized = false;

  bool get isDestroyed => _isDestroyed;
  bool get isInitialized => _isInitialized;

  void initialize() {
    _isInitialized = true;
  }

  @override
  void destroy() {
    _isDestroyed = true;
  }
}

void main() {
  group('RegistryManager - Singleton Patterns', () {
    late RegistryManager<String, TrackedService> registry;

    setUp(() {
      registry = createTestRegistry();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('singleton pattern: single instance throughout lifecycle', () {
      final service = TrackedService(id: 'singleton-1')
        ..initialize();

      registry.register('app', service);

      final retrieved1 = registry.getInstance('app');
      final retrieved2 = registry.getInstance('app');
      final retrieved3 = registry.getInstance('app');

      expect(retrieved1, same(service));
      expect(retrieved2, same(service));
      expect(retrieved3, same(service));
      expect(identical(retrieved1, retrieved2), isTrue);
      expect(service.isInitialized, isTrue);
    });

    test('lazy singleton pattern: initialized on first access', () {
      var initCallCount = 0;
      TrackedService? createdInstance;

      registry.registerLazy('lazy-singleton', () {
        initCallCount++;
        createdInstance = TrackedService(id: 'lazy-singleton-1');
        createdInstance!.initialize();
        return createdInstance!;
      });

      // Before first access, initialization should not have occurred
      expect(initCallCount, equals(0));

      final first = registry.getInstance('lazy-singleton');
      expect(initCallCount, equals(1));
      expect(first.isInitialized, isTrue);

      final second = registry.getInstance('lazy-singleton');
      expect(initCallCount, equals(1)); // Still 1, not called again
      expect(identical(first, second), isTrue);
    });

    test('singleton replacement pattern: graceful lifecycle transition', () {
      final oldService = TrackedService(id: 'old-service')
        ..initialize();
      registry.register('config', oldService);

      final retrieved1 = registry.getInstance('config');
      expect(retrieved1.id, equals('old-service'));
      expect(oldService.isDestroyed, isFalse);

      // Replace with new singleton
      final newService = TrackedService(id: 'new-service')
        ..initialize();
      registry.replace('config', newService);

      expect(oldService.isDestroyed, isTrue);

      final retrieved2 = registry.getInstance('config');
      expect(retrieved2.id, equals('new-service'));
      expect(newService.isDestroyed, isFalse);
    });

    test('multi-level dependency pattern: multiple singletons', () {
      final databaseService = TrackedService(id: 'database')
        ..initialize();
      final cacheService = TrackedService(id: 'cache')
        ..initialize();
      final apiService = TrackedService(id: 'api')
        ..initialize();

      registry
        ..register('db', databaseService)
        ..register('cache', cacheService)
        ..register('api', apiService);

      // Verify each is a singleton
      expect(registry.getInstance('db'), same(databaseService));
      expect(registry.getInstance('cache'), same(cacheService));
      expect(registry.getInstance('api'), same(apiService));

      // Verify they are distinct
      expect(registry.getInstance('db'), isNot(same(registry.getInstance('cache'))));
      expect(
        registry.getInstance('cache'),
        isNot(same(registry.getInstance('api'))),
      );

      expect(registry.registrySize, equals(3));
    });

    test('factory pattern with singleton caching', () {
      var factoryCallCount = 0;

      registry.registerLazy('service', () {
        factoryCallCount++;
        final service = TrackedService(id: 'factory-generated-$factoryCallCount')
          ..initialize();
        return service;
      });

      final first = registry.getInstance('service');
      expect(factoryCallCount, equals(1));
      expect(first.id, contains('factory-generated-1'));

      // Access many times
      for (var i = 0; i < 10; i++) {
        final retrieved = registry.getInstance('service');
        expect(identical(retrieved, first), isTrue);
        expect(factoryCallCount, equals(1)); // Still 1
      }
    });

    test('volatile singleton pattern: replacement while in use', () {
      final version1 = TrackedService(id: 'v1')
        ..initialize();
      registry.register('volatile', version1);

      final ref1 = registry.getInstance('volatile');
      expect(ref1.id, equals('v1'));

      final version2 = TrackedService(id: 'v2')
        ..initialize();
      registry.replaceLazy('volatile', () => version2);

      // Old reference still valid, but registry now has new one
      expect(ref1.id, equals('v1'));

      final ref2 = registry.getInstance('volatile');
      expect(ref2.id, equals('v2'));
      expect(version1.isDestroyed, isTrue);
    });

    test('scoped singleton pattern: multiple scopes', () {
      final scope1 = createTestRegistry<String, TrackedService>();
      final scope2 = createTestRegistry<String, TrackedService>();

      final scope1Service = TrackedService(id: 'scope1-service')
        ..initialize();
      final scope2Service = TrackedService(id: 'scope2-service')
        ..initialize();

      scope1.register('user-session', scope1Service);
      scope2.register('user-session', scope2Service);

      expect(scope1.getInstance('user-session').id, equals('scope1-service'));
      expect(scope2.getInstance('user-session').id, equals('scope2-service'));

      cleanupRegistry(scope1);
      cleanupRegistry(scope2);
    });

    test('circular reference pattern: singleton referencing other singletons', () {
      final serviceA = TrackedService(id: 'service-a')
        ..initialize();
      final serviceB = TrackedService(id: 'service-b')
        ..initialize();

      registry
        ..register('a', serviceA)
        ..register('b', serviceB);

      // Services maintain references to each other
      final a = registry.getInstance('a');
      final b = registry.getInstance('b');

      expect(a.id, equals('service-a'));
      expect(b.id, equals('service-b'));

      // Both are still singletons
      expect(registry.getInstance('a'), same(a));
      expect(registry.getInstance('b'), same(b));
    });

    test('lifecycle management: initialization -> usage -> destruction', () {
      final service = TrackedService(id: 'lifecycle-test');

      // Phase 1: Initialization
      expect(service.isInitialized, isFalse);
      service.initialize();
      expect(service.isInitialized, isTrue);

      // Phase 2: Register as singleton
      registry.register('service', service);
      expect(registry.contains('service'), isTrue);

      // Phase 3: Usage
      final retrieved = registry.getInstance('service');
      expect(identical(retrieved, service), isTrue);

      // Phase 4: Replacement triggers destruction
      final newService = TrackedService(id: 'lifecycle-test-2')
        ..initialize();
      registry.replace('service', newService);

      expect(service.isDestroyed, isTrue);
      expect(newService.isDestroyed, isFalse);

      // Phase 5: Full cleanup
      registry.destroyAll();
      expect(newService.isDestroyed, isTrue);
      expect(registry.isEmpty, isTrue);
    });

    test('version tracking across singleton lifecycle', () {
      final service1 = TrackedService(id: 'v1');
      registry.register('versioned', service1);

      final version1 = registry.getByKey('versioned')!;
      expect(version1.version, equals(0));

      final service2 = TrackedService(id: 'v2');
      registry.replace('versioned', service2);

      final version2 = registry.getByKey('versioned')!;
      expect(version2.version, equals(1));

      final service3 = TrackedService(id: 'v3');
      registry.replace('versioned', service3);

      final version3 = registry.getByKey('versioned')!;
      expect(version3.version, equals(2));
    });

    test('singleton pool pattern: fixed number of instances', () {
      const poolSize = 5;

      for (var i = 0; i < poolSize; i++) {
        final service = TrackedService(id: 'pooled-$i')
          ..initialize();
        registry.register('pool-$i', service);
      }

      expect(registry.registrySize, equals(poolSize));

      // Each pool slot is a singleton
      for (var i = 0; i < poolSize; i++) {
        final first = registry.getInstance('pool-$i');
        final second = registry.getInstance('pool-$i');
        expect(identical(first, second), isTrue);
      }
    });

    test('singleton aware of its own state changes', () {
      final service = TrackedService(id: 'stateful')
        ..initialize();
      registry.register('state', service);

      expect(registry.getInstance('state').isInitialized, isTrue);
      expect(registry.getInstance('state').isDestroyed, isFalse);

      // Manually mark as destroyed
      service.destroy();

      expect(registry.getInstance('state').isDestroyed, isTrue);
    });
  });
}
