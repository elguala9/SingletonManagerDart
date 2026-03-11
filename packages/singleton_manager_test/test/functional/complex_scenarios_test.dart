import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Complex Scenarios', () {
    late RegistryManager<String, SimpleService> registry;

    setUp(() {
      registry = createTestRegistry();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('mixed eager and lazy registrations in a single registry', () {
      final eagerService1 = SimpleService(name: 'eager1');
      final eagerService2 = SimpleService(name: 'eager2');

      registry.register('eager1', eagerService1);
      registry.register('eager2', eagerService2);
      registry.registerLazy('lazy1', () => SimpleService(name: 'lazy1'));
      registry.registerLazy('lazy2', () => SimpleService(name: 'lazy2'));

      expect(registry.registrySize, equals(4));

      // Verify eager services are immediately available
      expect(registry.getInstance('eager1'), same(eagerService1));
      expect(registry.getInstance('eager2'), same(eagerService2));

      // Verify lazy services work after access
      final lazy1 = registry.getInstance('lazy1');
      expect(lazy1.name, equals('lazy1'));

      final lazy2 = registry.getInstance('lazy2');
      expect(lazy2.name, equals('lazy2'));
    });

    test('replace eager with lazy and vice versa', () {
      final eagerService = SimpleService(name: 'eager');
      registry.register('key', eagerService);

      expect(registry.getInstance('key').name, equals('eager'));

      registry.replaceLazy('key', () => SimpleService(name: 'lazy'));
      final lazyService = registry.getInstance('key');

      expect(lazyService.name, equals('lazy'));
      expect(eagerService.destroyed, isTrue);
    });

    test('DI container with multiple service types', () {
      // Simulate a DI container with different service types
      final registry1 = createTestRegistry<String, SimpleService>();

      // Register different "services" with descriptive keys
      registry1.register('database', SimpleService(name: 'DatabaseService'));
      registry1.register('cache', SimpleService(name: 'CacheService'));
      registry1.registerLazy('logger', () => SimpleService(name: 'LoggerService'));
      registry1.registerLazy('api', () => SimpleService(name: 'ApiService'));

      // Verify all are accessible
      expect(registry1.getInstance('database').name, equals('DatabaseService'));
      expect(registry1.getInstance('cache').name, equals('CacheService'));
      expect(registry1.getInstance('logger').name, equals('LoggerService'));
      expect(registry1.getInstance('api').name, equals('ApiService'));

      // Verify we have all keys
      final keys = registry1.keys;
      expect(keys, hasLength(4));
      expect(
        keys,
        containsAll(['database', 'cache', 'logger', 'api']),
      );

      cleanupRegistry(registry1);
    });

    test('registry handles repeated destroy cycles', () {
      final service = SimpleService(name: 'test');
      registry.register('key', service);

      // First destroy
      registry.destroyAll();
      expect(service.destroyed, isTrue);
      expect(registry.isEmpty, isTrue);

      // Re-register
      final newService = SimpleService(name: 'test2');
      registry.register('key', newService);
      expect(registry.isNotEmpty, isTrue);

      // Second destroy
      registry.destroyAll();
      expect(newService.destroyed, isTrue);
      expect(registry.isEmpty, isTrue);
    });

    test('concurrent initialization of multiple lazy services', () {
      SimpleService.instantiationCount = 0;

      registry.registerLazy('lazy1', () => SimpleService.counted());
      registry.registerLazy('lazy2', () => SimpleService.counted());
      registry.registerLazy('lazy3', () => SimpleService.counted());

      final service1 = registry.getInstance('lazy1');
      final service2 = registry.getInstance('lazy2');
      final service3 = registry.getInstance('lazy3');

      expect(SimpleService.instantiationCount, equals(3));
      expect(service1, isNot(same(service2)));
      expect(service2, isNot(same(service3)));
    });

    test('version tracking across updates', () {
      final service1 = SimpleService(name: 'v1');
      registry.register('key', service1);

      final wrapper1 = registry.getByKey('key');
      expect(wrapper1!.version, equals(0));

      registry.replace('key', SimpleService(name: 'v2'));
      final wrapper2 = registry.getByKey('key');
      expect(wrapper2!.version, equals(1));

      registry.replace('key', SimpleService(name: 'v3'));
      final wrapper3 = registry.getByKey('key');
      expect(wrapper3!.version, equals(2));
    });
  });
}
