import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Async Initialization Pattern', () {
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
      AsyncService.reset();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('async pattern: initialize then register', () async {
      final service = await AsyncService.create(name: 'async-service');

      registry.register<AsyncService>('async', service);

      expect(registry.getInstance<AsyncService>('async'), same(service));
      expect(service.initialized, isTrue);
    });

    test('async pattern with multiple services', () async {
      final db = await AsyncService.create(name: 'database');
      final cache = await AsyncService.create(name: 'cache');
      final logger = await AsyncService.create(name: 'logger');

      registry
        ..register<AsyncService>('db', db)
        ..register<AsyncService>('cache', cache)
        ..register<AsyncService>('logger', logger);

      expect(registry.getInstance<AsyncService>('db'), same(db));
      expect(registry.getInstance<AsyncService>('cache'), same(cache));
      expect(registry.getInstance<AsyncService>('logger'), same(logger));
      expect(AsyncService.instantiationCount, equals(3));
    });

    test('ISingleton interface pattern for initialization', () async {
      _ServiceInitializer(registry).initializeDI();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(registry.contains<AsyncService>('service'), isTrue);
      final service = registry.getInstance<AsyncService>('service');
      expect(service.initialized, isTrue);
    });

    test('lazy factories in async context', () async {
      var initialized = false;

      registry.registerLazy<AsyncService>('lazy-async', () {
        initialized = true;
        return AsyncService(name: 'lazy-async', initialized: true);
      });

      expect(initialized, isFalse);

      final service = registry.getInstance<AsyncService>('lazy-async');

      expect(initialized, isTrue);
      expect(service.initialized, isTrue);
    });

    test('factory error handling in lazy registration', () async {
      var errorThrown = false;

      registry.registerLazy<AsyncService>('error-factory', () {
        errorThrown = true;
        throw Exception('Factory failed');
      });

      expect(errorThrown, isFalse);

      expect(
        () => registry.getInstance<AsyncService>('error-factory'),
        throwsA(isA<Exception>()),
      );
      expect(errorThrown, isTrue);
    });

    test('cleanup after async initialization', () async {
      final services = <AsyncService>[];

      for (var i = 0; i < 3; i++) {
        final service = await AsyncService.create(name: 'service-$i');
        registry.register<AsyncService>('service-$i', service);
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
class _ServiceInitializer implements ISingletonStandard<Null> {
  _ServiceInitializer(this.registry);

  final IRegistry<String> registry;

  @override
  Future<void> initialize(Null input) async {
    final service = await AsyncService.create(name: 'initialized-service');
    registry.register<AsyncService>('service', service);
  }

  @override
  void initializeDI() {
    // Note: fire-and-forget initialization
    initialize(null);
  }
}
