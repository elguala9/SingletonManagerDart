import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Stress Tests & Performance', () {
    late RegistryManager<String, SimpleService> registry;

    setUp(() {
      registry = createTestRegistry();
      SimpleService.instantiationCount = 0;
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('register and retrieve 1000 eager instances', () {
      const count = 1000;

      for (var i = 0; i < count; i++) {
        final service = SimpleService(name: 'service-$i');
        registry.register('key-$i', service);
      }

      expect(registry.registrySize, equals(count));

      // Verify random retrievals
      for (var i = 0; i < 100; i++) {
        final randomIdx = (i * 17) % count;
        final service = registry.getInstance('key-$randomIdx');
        expect(service.name, equals('service-$randomIdx'));
      }
    });

    test('register and retrieve 1000 lazy instances', () {
      const count = 1000;

      for (var i = 0; i < count; i++) {
        final idx = i;
        registry.registerLazy('lazy-key-$i', () {
          return SimpleService(name: 'lazy-service-$idx');
        });
      }

      expect(registry.registrySize, equals(count));

      // Access all lazy services
      for (var i = 0; i < count; i++) {
        final service = registry.getInstance('lazy-key-$i');
        expect(service.name, equals('lazy-service-$i'));
      }

      // Second access should use cached instances
      final firstAccess = SimpleService.instantiationCount;
      for (var i = 0; i < 100; i++) {
        registry.getInstance('lazy-key-$i');
      }
      expect(SimpleService.instantiationCount, equals(firstAccess));
    });

    test('mixed eager and lazy with 500 of each type', () {
      const eagerCount = 500;
      const lazyCount = 500;

      // Register eager
      for (var i = 0; i < eagerCount; i++) {
        registry.register('eager-$i', SimpleService(name: 'eager-$i'));
      }

      // Register lazy
      for (var i = 0; i < lazyCount; i++) {
        final idx = i;
        registry.registerLazy('lazy-$i', () {
          return SimpleService(name: 'lazy-$idx');
        });
      }

      expect(registry.registrySize, equals(eagerCount + lazyCount));

      // Verify samples from both
      expect(registry.getInstance('eager-100').name, equals('eager-100'));
      expect(registry.getInstance('lazy-100').name, equals('lazy-100'));
      expect(registry.getInstance('eager-450').name, equals('eager-450'));
      expect(registry.getInstance('lazy-450').name, equals('lazy-450'));
    });

    test('rapid sequential registrations and unregistrations', () {
      const iterations = 500;

      for (var i = 0; i < iterations; i++) {
        final service = SimpleService(name: 'rapid-$i');
        registry.register('key', service);
        expect(registry.contains('key'), isTrue);

        registry.unregister('key');
        expect(registry.contains('key'), isFalse);
      }

      expect(registry.isEmpty, isTrue);
    });

    test('replace operations on same key 100 times', () {
      var lastVersion = 0;

      for (var i = 0; i < 100; i++) {
        final service = SimpleService(name: 'version-$i');
        if (i == 0) {
          registry.register('replaceable', service);
        } else {
          registry.replace('replaceable', service);
        }

        final wrapper = registry.getByKey('replaceable')!;
        expect(wrapper.version, equals(lastVersion));
        lastVersion = wrapper.version + 1;
      }

      final finalVersion = registry.getByKey('replaceable')!.version;
      expect(finalVersion, equals(99));
    });

    test('get keys operation with large registry', () {
      const count = 500;

      for (var i = 0; i < count; i++) {
        registry.register('key-$i', SimpleService());
      }

      final keys = registry.keys;
      expect(keys, hasLength(count));

      // Verify all keys are present
      for (var i = 0; i < count; i++) {
        expect(keys, contains('key-$i'));
      }
    });

    test('containment checks on large registry', () {
      const count = 300;

      for (var i = 0; i < count; i++) {
        registry.register('key-$i', SimpleService());
      }

      // Check existing keys
      for (var i = 0; i < count; i++) {
        expect(registry.contains('key-$i'), isTrue);
      }

      // Check non-existing keys
      for (var i = count; i < count + 100; i++) {
        expect(registry.contains('key-$i'), isFalse);
      }
    });

    test('destroy all with large number of lazy entries', () {
      const count = 300;

      for (var i = 0; i < count; i++) {
        final idx = i;
        registry.registerLazy('lazy-$i', () {
          return SimpleService(name: 'lazy-$idx');
        });
      }

      // Don't access any - they should all be lazy
      expect(SimpleService.instantiationCount, equals(0));

      // Destroy all
      registry.destroyAll();

      expect(registry.isEmpty, isTrue);
      // Lazy entries that were never created shouldn't be instantiated
      expect(SimpleService.instantiationCount, equals(0));
    });

    test('destroy all with partially accessed lazy entries', () {
      const count = 300;

      for (var i = 0; i < count; i++) {
        final idx = i;
        registry.registerLazy('lazy-$i', () {
          return SimpleService.counted(name: 'lazy-$idx');
        });
      }

      // Access half of them
      for (var i = 0; i < count ~/ 2; i++) {
        registry.getInstance('lazy-$i');
      }

      expect(SimpleService.instantiationCount, equals(count ~/ 2));

      // Destroy all
      registry.destroyAll();

      expect(registry.isEmpty, isTrue);
      expect(SimpleService.instantiationCount, equals(count ~/ 2));
    });

    test('multiple sequential complete cycles', () {
      const cycleCount = 10;
      const itemsPerCycle = 100;

      for (var cycle = 0; cycle < cycleCount; cycle++) {
        for (var i = 0; i < itemsPerCycle; i++) {
          registry.register('cycle-$cycle-item-$i', SimpleService());
        }

        expect(registry.registrySize, equals(itemsPerCycle));

        // Verify retrieval
        for (var i = 0; i < 10; i++) {
          final service = registry.getInstance('cycle-$cycle-item-$i');
          expect(service, isNotNull);
        }

        // Clear for next cycle
        registry.clearRegistry();
        expect(registry.isEmpty, isTrue);
      }
    });

    test('stress test: interleaved operations', () {
      const operations = 500;

      for (var op = 0; op < operations; op++) {
        final opType = op % 4;
        final key = 'stress-${op % 100}';

        switch (opType) {
          case 0: // Register or replace
            final service = SimpleService(name: 'op-$op');
            if (registry.contains(key)) {
              registry.replace(key, service);
            } else {
              registry.register(key, service);
            }
          case 1: // Retrieve
            if (registry.contains(key)) {
              registry.getInstance(key);
            }
          case 2: // Unregister
            registry.unregister(key);
          case 3: // Check size
            registry.registrySize;
          default:
            break;
        }
      }

      // Should still be functional after stress
      registry.register('final-test', SimpleService());
      expect(registry.getInstance('final-test'), isNotNull);
    });

    test('registry size consistency during stress', () {
      expect(registry.registrySize, equals(0));

      for (var i = 0; i < 200; i++) {
        registry.register('key-$i', SimpleService());
        expect(registry.registrySize, equals(i + 1));
      }

      for (var i = 0; i < 200; i++) {
        registry.unregister('key-$i');
        expect(registry.registrySize, equals(200 - i - 1));
      }

      expect(registry.registrySize, equals(0));
    });

    test('keys property consistency during modifications', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        registry.register('key-$i', SimpleService());

        final keys = registry.keys;
        expect(keys.length, equals(i + 1));
        expect(keys.contains('key-$i'), isTrue);
      }

      for (var i = 0; i < iterations; i++) {
        registry.unregister('key-$i');

        final keys = registry.keys;
        expect(keys.length, equals(iterations - i - 1));
        expect(keys.contains('key-$i'), isFalse);
      }
    });

    test('factory function call count with repeated access', () {
      var callCount = 0;

      registry.registerLazy('lazy', () {
        callCount++;
        return SimpleService(name: 'lazy-$callCount');
      });

      // Access 1000 times
      for (var i = 0; i < 1000; i++) {
        registry.getInstance('lazy');
      }

      // Should only be called once due to caching
      expect(callCount, equals(1));
    });

    test('verify order independence of operations', () {
      // Register in one order
      registry
        ..register('a', SimpleService(name: 'a'))
        ..register('b', SimpleService(name: 'b'))
        ..register('c', SimpleService(name: 'c'));

      // Retrieve in different order
      final c = registry.getInstance('c');
      final a = registry.getInstance('a');
      final b = registry.getInstance('b');

      expect(a.name, equals('a'));
      expect(b.name, equals('b'));
      expect(c.name, equals('c'));

      // Unregister in different order
      registry
        ..unregister('b')
        ..unregister('a')
        ..unregister('c');

      expect(registry.isEmpty, isTrue);
    });
  });
}
