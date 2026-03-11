import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Async Initialization Pattern', () {
    late RegistryManager<String, AsyncService> registry;

    setUp(() {
      registry = createTestRegistry();
      AsyncService.reset();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('async pattern: initialize then register', () async {
      // This demonstrates the async pattern where you initialize
      // the service asynchronously and then register it
      final service = await AsyncService.create(name: 'async-service');

      registry.register('async', service);

      expect(registry.getInstance('async'), same(service));
      expect(service.initialized, isTrue);
    });

    test('async pattern with multiple services', () async {
      // Initialize multiple services asynchronously
      final db = await AsyncService.create(name: 'database');
      final cache = await AsyncService.create(name: 'cache');
      final logger = await AsyncService.create(name: 'logger');

      // Register them
      registry.register('db', db);
      registry.register('cache', cache);
      registry.register('logger', logger);

      // Verify all are properly registered
      expect(registry.getInstance('db'), same(db));
      expect(registry.getInstance('cache'), same(cache));
      expect(registry.getInstance('logger'), same(logger));
      expect(AsyncService.instantiationCount, equals(3));
    });

    test('ISingleton interface pattern for initialization', () async {
      // This demonstrates using a custom class that implements ISingleton
      // for managing the async initialization of a service
      final initializer = _ServiceInitializer(registry);

      // Initialize the service asynchronously
      await initializer.initializeDI();

      // Verify it's registered
      expect(registry.contains('service'), isTrue);
      final service = registry.getInstance('service');
      expect(service.initialized, isTrue);
    });

    test('lazy factories in async context', () async {
      // Lazy factories can be used to defer async initialization
      // until the service is actually needed
      var initialized = false;

      registry.registerLazy('lazy-async', () {
        initialized = true;
        // In reality, you'd call an async factory here
        // For this test, we just create a sync service
        return AsyncService(
          name: 'lazy-async',
          initialized: true,
        );
      });

      expect(initialized, isFalse);

      final service = registry.getInstance('lazy-async');

      expect(initialized, isTrue);
      expect(service.initialized, isTrue);
    });

    test('factory error handling in lazy registration', () async {
      var errorThrown = false;

      registry.registerLazy('error-factory', () {
        errorThrown = true;
        throw Exception('Factory failed');
      });

      expect(errorThrown, isFalse);

      expect(
        () => registry.getInstance('error-factory'),
        throwsA(isA<Exception>()),
      );
      expect(errorThrown, isTrue);
    });

    test('cleanup after async initialization', () async {
      final services = <AsyncService>[];

      for (var i = 0; i < 3; i++) {
        final service = await AsyncService.create(name: 'service-$i');
        registry.register('service-$i', service);
        services.add(service);
      }

      expect(registry.registrySize, equals(3));

      registry.destroyAll();

      for (final service in services) {
        expect(service.destroyed, isTrue);
      }
      expect(registry.isEmpty, isTrue);
    });
  });
}

/// Example implementation of ISingleton interface for managing
/// async service initialization
class _ServiceInitializer
    implements ISingleton<Null, AsyncService> {
  _ServiceInitializer(this.registry);

  final RegistryManager<String, AsyncService> registry;

  @override
  Future<AsyncService> initialize(Null input) async {
    final service = await AsyncService.create(name: 'initialized-service');
    registry.register('service', service);
    return service;
  }

  @override
  Future<AsyncService> initializeDI() async {
    return initialize(null);
  }
}
