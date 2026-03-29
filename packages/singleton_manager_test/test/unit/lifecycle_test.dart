import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Lifecycle Management', () {
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('destroy() is called on manually destroyed items', () {
      final service = SimpleService();
      registry.register<SimpleService>('key1', service);

      service.destroy();

      expect(service.destroyed, isTrue);
    });

    test('destroyAll() calls destroy on all registered items', () {
      final service1 = SimpleService(name: 'service1');
      final service2 = SimpleService(name: 'service2');

      registry
        ..register<SimpleService>('key1', service1)
        ..register<SimpleService>('key2', service2)
        ..destroyAll();

      expect(service1.destroyed, isTrue);
      expect(service2.destroyed, isTrue);
    });

    test('destroyAll() clears the registry', () {
      final service1 = SimpleService();
      final service2 = SimpleService();

      registry
        ..register<SimpleService>('key1', service1)
        ..register<SimpleService>('key2', service2);

      expect(registry.registrySize, equals(2));

      registry.destroyAll();

      expect(registry.isEmpty, isTrue);
      expect(registry.registrySize, equals(0));
    });

    test('clearRegistry() empties the registry without destroying', () {
      final service = SimpleService();
      registry
        ..register<SimpleService>('key1', service)
        ..clearRegistry();

      expect(registry.isEmpty, isTrue);
      expect(service.destroyed, isFalse);
    });

    test('destroyAll() handles lazy entries correctly', () {
      final lazyRegistry = createTestRegistry<String>()
        ..registerLazy<SimpleService>('lazy1', () => SimpleService(name: 'lazy1'))
        ..registerLazy<SimpleService>('lazy2', () => SimpleService(name: 'lazy2'));

      final initializedService = lazyRegistry.getInstance<SimpleService>('lazy1');

      lazyRegistry.destroyAll();

      expect(initializedService.destroyed, isTrue);
      expect(lazyRegistry.isEmpty, isTrue);

      cleanupRegistry(lazyRegistry);
    });

    test('multiple destroy calls are safe', () {
      final service = SimpleService();
      registry
        ..register<SimpleService>('key1', service)
        ..destroyAll();
      expect(service.destroyed, isTrue);

      service.destroy();
      expect(service.destroyed, isTrue);
    });

    test('unregister does not destroy', () {
      final service = SimpleService();
      registry.register<SimpleService>('key1', service);

      final unregistered = registry.unregister<SimpleService>('key1');

      expect(unregistered, isNotNull);
      expect(service.destroyed, isFalse);
    });
  });
}
