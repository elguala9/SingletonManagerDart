import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Edge Cases', () {
    late RegistryManager<String, SimpleService> registry;

    setUp(() {
      registry = createTestRegistry();
      SimpleService.instantiationCount = 0;
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('register null-like objects (empty string as key)', () {
      final service = SimpleService(name: 'test');
      registry.register('', service);

      expect(registry.contains(''), isTrue);
      expect(registry.getInstance(''), same(service));
    });

    test('handle very long key names', () {
      const longKey = 'this_is_a_very_long_key_'
          'that_might_stress_the_string_handling_'
          'and_hashcode_implementation_'
          'with_lots_of_repetition';
      final service = SimpleService(name: 'test');

      registry.register(longKey, service);

      expect(registry.contains(longKey), isTrue);
      expect(registry.getInstance(longKey), same(service));
    });

    test('handle special characters in keys', () {
      const specialKeys = [
        'key:with:colons',
        'key|with|pipes',
        'key/with/slashes',
        'key\\with\\backslashes',
        'key"with"quotes',
        "key'with'single_quotes",
        'key{with}braces',
        'key[with]brackets',
      ];

      for (final key in specialKeys) {
        final service = SimpleService(name: key);
        registry.register(key, service);
        expect(registry.contains(key), isTrue);
        expect(registry.getInstance(key).name, equals(key));
      }
    });

    test('register and retrieve the same object multiple times via different keys',
        () {
      final service = SimpleService(name: 'shared');
      registry
        ..register('key1', service)
        ..register('key2', service);

      // Both keys should point to the exact same instance
      expect(registry.getInstance('key1'), same(service));
      expect(registry.getInstance('key2'), same(service));
      expect(registry.registrySize, equals(2));
    });

    test('unregister then re-register with same key', () {
      final service1 = SimpleService(name: 'first');
      registry.register('key', service1);

      final unregistered = registry.unregister('key');
      expect(unregistered, isNotNull);
      expect(registry.contains('key'), isFalse);

      // Re-register with same key should work
      final service2 = SimpleService(name: 'second');
      registry.register('key', service2);

      expect(registry.contains('key'), isTrue);
      expect(registry.getInstance('key'), same(service2));
    });

    test('clear registry then verify it is truly empty', () {
      registry
        ..register('key1', SimpleService())
        ..register('key2', SimpleService())
        ..registerLazy('key3', SimpleService.new);

      expect(registry.isEmpty, isFalse);

      registry.clearRegistry();

      expect(registry.isEmpty, isTrue);
      expect(registry.registrySize, equals(0));
      expect(registry.keys.isEmpty, isTrue);
    });

    test('lazy factory that returns same instance repeatedly', () {
      final sharedInstance = SimpleService(name: 'shared');

      registry.registerLazy('key', () => sharedInstance);

      final first = registry.getInstance('key');
      final second = registry.getInstance('key');
      final third = registry.getInstance('key');

      expect(first, same(second));
      expect(second, same(third));
      expect(first, same(sharedInstance));
    });

    test('replace with self should still increment version', () {
      final service = SimpleService(name: 'test');
      registry.register('key', service);

      final wrapper1 = registry.getByKey('key');
      expect(wrapper1!.version, equals(0));

      // Replace with different instance
      final newService = SimpleService(name: 'new');
      registry.replace('key', newService);

      final wrapper2 = registry.getByKey('key');
      expect(wrapper2!.version, equals(1));
    });

    test('getByKey returns null for unregistered keys, not throws', () {
      final result = registry.getByKey('nonexistent');
      expect(result, isNull);

      // Should not throw, unlike getInstance
      expect(
        () => registry.getInstance('nonexistent'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('destroy on lazy entry that was never accessed', () {
      var factoryCalled = false;
      registry
        ..registerLazy('key', () {
          factoryCalled = true;
          return SimpleService();
        })
        ..destroyAll();

      // Factory should never have been called
      expect(factoryCalled, isFalse);
      expect(registry.isEmpty, isTrue);
    });

    test('register and unregister in rapid succession', () {
      for (var i = 0; i < 100; i++) {
        final service = SimpleService(name: 'service_$i');
        registry.register('key', service);
        expect(registry.contains('key'), isTrue);

        registry.unregister('key');
        expect(registry.contains('key'), isFalse);
      }
    });

    test('keys property reflects current state after unregister', () {
      registry
        ..register('key1', SimpleService())
        ..register('key2', SimpleService())
        ..register('key3', SimpleService());

      var keys = registry.keys;
      expect(keys, hasLength(3));

      registry.unregister('key2');

      keys = registry.keys;
      expect(keys, hasLength(2));
      expect(keys, containsAll(['key1', 'key3']));
      expect(keys, isNot(contains('key2')));
    });

    test('multiple registries do not interfere', () {
      final registry1 = createTestRegistry<String, SimpleService>();
      final registry2 = createTestRegistry<String, SimpleService>();

      final service1 = SimpleService(name: 'service1');
      final service2 = SimpleService(name: 'service2');

      registry1.register('key', service1);
      registry2.register('key', service2);

      expect(registry1.getInstance('key'), same(service1));
      expect(registry2.getInstance('key'), same(service2));
      expect(registry1.getInstance('key'), isNot(same(service2)));

      cleanupRegistry(registry1);
      cleanupRegistry(registry2);
    });

    test('registry size remains accurate after all operations', () {
      expect(registry.registrySize, equals(0));

      registry.register('k1', SimpleService());
      expect(registry.registrySize, equals(1));

      registry.register('k2', SimpleService());
      expect(registry.registrySize, equals(2));

      registry.registerLazy('k3', SimpleService.new);
      expect(registry.registrySize, equals(3));

      registry.unregister('k2');
      expect(registry.registrySize, equals(2));

      registry.replace('k1', SimpleService());
      expect(registry.registrySize, equals(2));

      registry.clearRegistry();
      expect(registry.registrySize, equals(0));
    });
  });
}
