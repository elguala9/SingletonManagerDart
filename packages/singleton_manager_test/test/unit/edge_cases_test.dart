import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Edge Cases', () {
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
      SimpleService.instantiationCount = 0;
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('register with empty string as key', () {
      final service = SimpleService(name: 'test');
      registry.register<SimpleService>('', service);

      expect(registry.contains<SimpleService>(''), isTrue);
      expect(registry.getInstance<SimpleService>(''), same(service));
    });

    test('handle very long key names', () {
      const longKey = 'this_is_a_very_long_key_'
          'that_might_stress_the_string_handling_'
          'and_hashcode_implementation_'
          'with_lots_of_repetition';
      final service = SimpleService(name: 'test');

      registry.register<SimpleService>(longKey, service);

      expect(registry.contains<SimpleService>(longKey), isTrue);
      expect(registry.getInstance<SimpleService>(longKey), same(service));
    });

    test('handle special characters in keys', () {
      const specialKeys = [
        'key:with:colons',
        'key|with|pipes',
        'key/with/slashes',
        r'key\with\backslashes',
        'key"with"quotes',
        "key'with'single_quotes",
        'key{with}braces',
        'key[with]brackets',
      ];

      for (final key in specialKeys) {
        final service = SimpleService(name: key);
        registry.register<SimpleService>(key, service);
        expect(registry.contains<SimpleService>(key), isTrue);
        expect(
          registry.getInstance<SimpleService>(key).name,
          equals(key),
        );
      }
    });

    test('register and retrieve the same object via different keys', () {
      final service = SimpleService(name: 'shared');
      registry
        ..register<SimpleService>('key1', service)
        ..register<SimpleService>('key2', service);

      expect(registry.getInstance<SimpleService>('key1'), same(service));
      expect(registry.getInstance<SimpleService>('key2'), same(service));
      expect(registry.registrySize, equals(2));
    });

    test('unregister then re-register with same key', () {
      final service1 = SimpleService(name: 'first');
      registry.register<SimpleService>('key', service1);

      final unregistered = registry.unregister<SimpleService>('key');
      expect(unregistered, isNotNull);
      expect(registry.contains<SimpleService>('key'), isFalse);

      final service2 = SimpleService(name: 'second');
      registry.register<SimpleService>('key', service2);

      expect(registry.contains<SimpleService>('key'), isTrue);
      expect(registry.getInstance<SimpleService>('key'), same(service2));
    });

    test('clear registry then verify truly empty', () {
      registry
        ..register<SimpleService>('key1', SimpleService())
        ..register<SimpleService>('key2', SimpleService())
        ..registerLazy<SimpleService>('key3', SimpleService.new);

      expect(registry.isEmpty, isFalse);

      registry.clearRegistry();

      expect(registry.isEmpty, isTrue);
      expect(registry.registrySize, equals(0));
      expect(registry.keys.isEmpty, isTrue);
    });

    test('lazy factory that returns same instance repeatedly', () {
      final sharedInstance = SimpleService(name: 'shared');

      registry.registerLazy<SimpleService>('key', () => sharedInstance);

      final first = registry.getInstance<SimpleService>('key');
      final second = registry.getInstance<SimpleService>('key');
      final third = registry.getInstance<SimpleService>('key');

      expect(first, same(second));
      expect(second, same(third));
      expect(first, same(sharedInstance));
    });

    test('replace increments version', () {
      final service = SimpleService(name: 'test');
      registry.register<SimpleService>('key', service);

      final wrapper1 = registry.getByKey<SimpleService>('key');
      expect(wrapper1!.version, equals(0));

      final newService = SimpleService(name: 'new');
      registry.replace<SimpleService>('key', newService);

      final wrapper2 = registry.getByKey<SimpleService>('key');
      expect(wrapper2!.version, equals(1));
    });

    test('getByKey returns null for unregistered keys, not throws', () {
      final result = registry.getByKey<SimpleService>('nonexistent');
      expect(result, isNull);

      expect(
        () => registry.getInstance<SimpleService>('nonexistent'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('destroy on lazy entry that was never accessed', () {
      var factoryCalled = false;
      registry
        ..registerLazy<SimpleService>('key', () {
          factoryCalled = true;
          return SimpleService();
        })
        ..destroyAll();

      expect(factoryCalled, isFalse);
      expect(registry.isEmpty, isTrue);
    });

    test('register and unregister in rapid succession', () {
      for (var i = 0; i < 100; i++) {
        final service = SimpleService(name: 'service_$i');
        registry.register<SimpleService>('key', service);
        expect(registry.contains<SimpleService>('key'), isTrue);

        registry.unregister<SimpleService>('key');
        expect(registry.contains<SimpleService>('key'), isFalse);
      }
    });

    test('keys property reflects current state after unregister', () {
      registry
        ..register<SimpleService>('key1', SimpleService())
        ..register<SimpleService>('key2', SimpleService())
        ..register<SimpleService>('key3', SimpleService());

      var keyValues = extractKeys(registry.keys);
      expect(keyValues, hasLength(3));

      registry.unregister<SimpleService>('key2');

      keyValues = extractKeys(registry.keys);
      expect(keyValues, hasLength(2));
      expect(keyValues, containsAll(['key1', 'key3']));
      expect(keyValues, isNot(contains('key2')));
    });

    test('multiple registries do not interfere', () {
      final registry1 = createTestRegistry<String>();
      final registry2 = createTestRegistry<String>();

      final service1 = SimpleService(name: 'service1');
      final service2 = SimpleService(name: 'service2');

      registry1.register<SimpleService>('key', service1);
      registry2.register<SimpleService>('key', service2);

      expect(registry1.getInstance<SimpleService>('key'), same(service1));
      expect(registry2.getInstance<SimpleService>('key'), same(service2));
      expect(
        registry1.getInstance<SimpleService>('key'),
        isNot(same(service2)),
      );

      cleanupRegistry(registry1);
      cleanupRegistry(registry2);
    });

    test('registry size remains accurate after all operations', () {
      expect(registry.registrySize, equals(0));

      registry.register<SimpleService>('k1', SimpleService());
      expect(registry.registrySize, equals(1));

      registry.register<SimpleService>('k2', SimpleService());
      expect(registry.registrySize, equals(2));

      registry.registerLazy<SimpleService>('k3', SimpleService.new);
      expect(registry.registrySize, equals(3));

      registry.unregister<SimpleService>('k2');
      expect(registry.registrySize, equals(2));

      registry.replace<SimpleService>('k1', SimpleService());
      expect(registry.registrySize, equals(2));

      registry.clearRegistry();
      expect(registry.registrySize, equals(0));
    });
  });
}
