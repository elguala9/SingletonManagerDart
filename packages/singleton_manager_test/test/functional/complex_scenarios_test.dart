import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Complex Scenarios', () {
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('mixed eager and lazy registrations in a single registry', () {
      final eagerService1 = SimpleService(name: 'eager1');
      final eagerService2 = SimpleService(name: 'eager2');

      registry
        ..register<SimpleService>('eager1', eagerService1)
        ..register<SimpleService>('eager2', eagerService2)
        ..registerLazy<SimpleService>('lazy1', () => SimpleService(name: 'lazy1'))
        ..registerLazy<SimpleService>('lazy2', () => SimpleService(name: 'lazy2'));

      expect(registry.registrySize, equals(4));

      expect(registry.getInstance<SimpleService>('eager1'), same(eagerService1));
      expect(registry.getInstance<SimpleService>('eager2'), same(eagerService2));

      final lazy1 = registry.getInstance<SimpleService>('lazy1');
      expect(lazy1.name, equals('lazy1'));

      final lazy2 = registry.getInstance<SimpleService>('lazy2');
      expect(lazy2.name, equals('lazy2'));
    });

    test('replace eager with lazy and vice versa', () {
      final eagerService = SimpleService(name: 'eager');
      registry.register<SimpleService>('key', eagerService);

      expect(registry.getInstance<SimpleService>('key').name, equals('eager'));

      registry.replaceLazy<SimpleService>('key', () => SimpleService(name: 'lazy'));
      final lazyService = registry.getInstance<SimpleService>('key');

      expect(lazyService.name, equals('lazy'));
      expect(eagerService.destroyed, isTrue);
    });

    test('DI container with multiple service types', () {
      final registry1 = createTestRegistry<String>()
        ..register<SimpleService>('database', SimpleService(name: 'DatabaseService'))
        ..register<SimpleService>('cache', SimpleService(name: 'CacheService'))
        ..registerLazy<SimpleService>('logger', () => SimpleService(name: 'LoggerService'))
        ..registerLazy<SimpleService>('api', () => SimpleService(name: 'ApiService'));

      expect(
        registry1.getInstance<SimpleService>('database').name,
        equals('DatabaseService'),
      );
      expect(
        registry1.getInstance<SimpleService>('cache').name,
        equals('CacheService'),
      );
      expect(
        registry1.getInstance<SimpleService>('logger').name,
        equals('LoggerService'),
      );
      expect(
        registry1.getInstance<SimpleService>('api').name,
        equals('ApiService'),
      );

      expect(registry1.keys, hasLength(4));
      expect(
        extractKeys(registry1.keys),
        containsAll(['database', 'cache', 'logger', 'api']),
      );

      cleanupRegistry(registry1);
    });

    test('registry handles repeated destroy cycles', () {
      final service = SimpleService(name: 'test');
      registry
        ..register<SimpleService>('key', service)
        ..destroyAll();
      expect(service.destroyed, isTrue);
      expect(registry.isEmpty, isTrue);

      final newService = SimpleService(name: 'test2');
      registry.register<SimpleService>('key', newService);
      expect(registry.isNotEmpty, isTrue);

      registry.destroyAll();
      expect(newService.destroyed, isTrue);
      expect(registry.isEmpty, isTrue);
    });

    test('concurrent initialization of multiple lazy services', () {
      SimpleService.instantiationCount = 0;

      registry
        ..registerLazy<SimpleService>('lazy1', SimpleService.counted)
        ..registerLazy<SimpleService>('lazy2', SimpleService.counted)
        ..registerLazy<SimpleService>('lazy3', SimpleService.counted);

      final service1 = registry.getInstance<SimpleService>('lazy1');
      final service2 = registry.getInstance<SimpleService>('lazy2');
      final service3 = registry.getInstance<SimpleService>('lazy3');

      expect(SimpleService.instantiationCount, equals(3));
      expect(service1, isNot(same(service2)));
      expect(service2, isNot(same(service3)));
    });

    test('version tracking across updates', () {
      final service1 = SimpleService(name: 'v1');
      registry.register<SimpleService>('key', service1);

      final wrapper1 = registry.getByKey<SimpleService>('key');
      expect(wrapper1!.version, equals(0));

      registry.replace<SimpleService>('key', SimpleService(name: 'v2'));
      final wrapper2 = registry.getByKey<SimpleService>('key');
      expect(wrapper2!.version, equals(1));

      registry.replace<SimpleService>('key', SimpleService(name: 'v3'));
      final wrapper3 = registry.getByKey<SimpleService>('key');
      expect(wrapper3!.version, equals(2));
    });
  });
}
