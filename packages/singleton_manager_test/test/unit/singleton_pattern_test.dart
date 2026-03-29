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
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('singleton pattern: single instance throughout lifecycle', () {
      final service = TrackedService(id: 'singleton-1')..initialize();

      registry.register<TrackedService>('app', service);

      final retrieved1 = registry.getInstance<TrackedService>('app');
      final retrieved2 = registry.getInstance<TrackedService>('app');
      final retrieved3 = registry.getInstance<TrackedService>('app');

      expect(retrieved1, same(service));
      expect(retrieved2, same(service));
      expect(retrieved3, same(service));
      expect(identical(retrieved1, retrieved2), isTrue);
      expect(service.isInitialized, isTrue);
    });

    test('lazy singleton pattern: initialized on first access', () {
      var initCallCount = 0;
      TrackedService? createdInstance;

      registry.registerLazy<TrackedService>('lazy-singleton', () {
        initCallCount++;
        createdInstance = TrackedService(id: 'lazy-singleton-1');
        createdInstance!.initialize();
        return createdInstance!;
      });

      expect(initCallCount, equals(0));

      final first = registry.getInstance<TrackedService>('lazy-singleton');
      expect(initCallCount, equals(1));
      expect(first.isInitialized, isTrue);

      final second = registry.getInstance<TrackedService>('lazy-singleton');
      expect(initCallCount, equals(1));
      expect(identical(first, second), isTrue);
    });

    test('singleton replacement pattern: graceful lifecycle transition', () {
      final oldService = TrackedService(id: 'old-service')..initialize();
      registry.register<TrackedService>('config', oldService);

      final retrieved1 = registry.getInstance<TrackedService>('config');
      expect(retrieved1.id, equals('old-service'));
      expect(oldService.isDestroyed, isFalse);

      final newService = TrackedService(id: 'new-service')..initialize();
      registry.replace<TrackedService>('config', newService);

      expect(oldService.isDestroyed, isTrue);

      final retrieved2 = registry.getInstance<TrackedService>('config');
      expect(retrieved2.id, equals('new-service'));
      expect(newService.isDestroyed, isFalse);
    });

    test('multi-level dependency pattern: multiple singletons', () {
      final databaseService = TrackedService(id: 'database')..initialize();
      final cacheService = TrackedService(id: 'cache')..initialize();
      final apiService = TrackedService(id: 'api')..initialize();

      registry
        ..register<TrackedService>('db', databaseService)
        ..register<TrackedService>('cache', cacheService)
        ..register<TrackedService>('api', apiService);

      expect(
        registry.getInstance<TrackedService>('db'),
        same(databaseService),
      );
      expect(
        registry.getInstance<TrackedService>('cache'),
        same(cacheService),
      );
      expect(
        registry.getInstance<TrackedService>('api'),
        same(apiService),
      );

      expect(
        registry.getInstance<TrackedService>('db'),
        isNot(same(registry.getInstance<TrackedService>('cache'))),
      );
      expect(
        registry.getInstance<TrackedService>('cache'),
        isNot(same(registry.getInstance<TrackedService>('api'))),
      );

      expect(registry.registrySize, equals(3));
    });

    test('factory pattern with singleton caching', () {
      var factoryCallCount = 0;

      registry.registerLazy<TrackedService>('service', () {
        factoryCallCount++;
        return TrackedService(id: 'factory-generated-$factoryCallCount')
          ..initialize();
      });

      final first = registry.getInstance<TrackedService>('service');
      expect(factoryCallCount, equals(1));
      expect(first.id, contains('factory-generated-1'));

      for (var i = 0; i < 10; i++) {
        final retrieved = registry.getInstance<TrackedService>('service');
        expect(identical(retrieved, first), isTrue);
        expect(factoryCallCount, equals(1));
      }
    });

    test('volatile singleton pattern: replacement while in use', () {
      final version1 = TrackedService(id: 'v1')..initialize();
      registry.register<TrackedService>('volatile', version1);

      final ref1 = registry.getInstance<TrackedService>('volatile');
      expect(ref1.id, equals('v1'));

      final version2 = TrackedService(id: 'v2')..initialize();
      registry.replaceLazy<TrackedService>('volatile', () => version2);

      expect(ref1.id, equals('v1'));

      final ref2 = registry.getInstance<TrackedService>('volatile');
      expect(ref2.id, equals('v2'));
      expect(version1.isDestroyed, isTrue);
    });

    test('scoped singleton pattern: multiple scopes', () {
      final scope1 = createTestRegistry<String>();
      final scope2 = createTestRegistry<String>();

      final scope1Service = TrackedService(id: 'scope1-service')..initialize();
      final scope2Service = TrackedService(id: 'scope2-service')..initialize();

      scope1.register<TrackedService>('user-session', scope1Service);
      scope2.register<TrackedService>('user-session', scope2Service);

      expect(
        scope1.getInstance<TrackedService>('user-session').id,
        equals('scope1-service'),
      );
      expect(
        scope2.getInstance<TrackedService>('user-session').id,
        equals('scope2-service'),
      );

      cleanupRegistry(scope1);
      cleanupRegistry(scope2);
    });

    test('circular reference pattern: singleton referencing other singletons',
        () {
      final serviceA = TrackedService(id: 'service-a')..initialize();
      final serviceB = TrackedService(id: 'service-b')..initialize();

      registry
        ..register<TrackedService>('a', serviceA)
        ..register<TrackedService>('b', serviceB);

      final a = registry.getInstance<TrackedService>('a');
      final b = registry.getInstance<TrackedService>('b');

      expect(a.id, equals('service-a'));
      expect(b.id, equals('service-b'));

      expect(registry.getInstance<TrackedService>('a'), same(a));
      expect(registry.getInstance<TrackedService>('b'), same(b));
    });

    test('lifecycle management: initialization -> usage -> destruction', () {
      final service = TrackedService(id: 'lifecycle-test');

      expect(service.isInitialized, isFalse);
      service.initialize();
      expect(service.isInitialized, isTrue);

      registry.register<TrackedService>('service', service);
      expect(registry.contains<TrackedService>('service'), isTrue);

      final retrieved = registry.getInstance<TrackedService>('service');
      expect(identical(retrieved, service), isTrue);

      final newService = TrackedService(id: 'lifecycle-test-2')..initialize();
      registry.replace<TrackedService>('service', newService);

      expect(service.isDestroyed, isTrue);
      expect(newService.isDestroyed, isFalse);

      registry.destroyAll();
      expect(newService.isDestroyed, isTrue);
      expect(registry.isEmpty, isTrue);
    });

    test('version tracking across singleton lifecycle', () {
      final service1 = TrackedService(id: 'v1');
      registry.register<TrackedService>('versioned', service1);

      final version1 = registry.getByKey<TrackedService>('versioned')!;
      expect(version1.version, equals(0));

      final service2 = TrackedService(id: 'v2');
      registry.replace<TrackedService>('versioned', service2);

      final version2 = registry.getByKey<TrackedService>('versioned')!;
      expect(version2.version, equals(1));

      final service3 = TrackedService(id: 'v3');
      registry.replace<TrackedService>('versioned', service3);

      final version3 = registry.getByKey<TrackedService>('versioned')!;
      expect(version3.version, equals(2));
    });

    test('singleton pool pattern: fixed number of instances', () {
      const poolSize = 5;

      for (var i = 0; i < poolSize; i++) {
        final service = TrackedService(id: 'pooled-$i')..initialize();
        registry.register<TrackedService>('pool-$i', service);
      }

      expect(registry.registrySize, equals(poolSize));

      for (var i = 0; i < poolSize; i++) {
        final first = registry.getInstance<TrackedService>('pool-$i');
        final second = registry.getInstance<TrackedService>('pool-$i');
        expect(identical(first, second), isTrue);
      }
    });

    test('singleton aware of its own state changes', () {
      final service = TrackedService(id: 'stateful')..initialize();
      registry.register<TrackedService>('state', service);

      expect(
        registry.getInstance<TrackedService>('state').isInitialized,
        isTrue,
      );
      expect(
        registry.getInstance<TrackedService>('state').isDestroyed,
        isFalse,
      );

      service.destroy();

      expect(
        registry.getInstance<TrackedService>('state').isDestroyed,
        isTrue,
      );
    });
  });
}
