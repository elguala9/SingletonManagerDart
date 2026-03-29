import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Stress Tests & Performance', () {
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
      SimpleService.instantiationCount = 0;
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('register and retrieve 1000 eager instances', () {
      const count = 1000;

      for (var i = 0; i < count; i++) {
        registry.register<SimpleService>('key-$i', SimpleService(name: 'service-$i'));
      }

      expect(registry.registrySize, equals(count));

      for (var i = 0; i < 100; i++) {
        final randomIdx = (i * 17) % count;
        final service = registry.getInstance<SimpleService>('key-$randomIdx');
        expect(service.name, equals('service-$randomIdx'));
      }
    });

    test('register and retrieve 1000 lazy instances', () {
      const count = 1000;

      for (var i = 0; i < count; i++) {
        final idx = i;
        registry.registerLazy<SimpleService>('lazy-key-$i', () {
          return SimpleService(name: 'lazy-service-$idx');
        });
      }

      expect(registry.registrySize, equals(count));

      for (var i = 0; i < count; i++) {
        final service = registry.getInstance<SimpleService>('lazy-key-$i');
        expect(service.name, equals('lazy-service-$i'));
      }

      final firstAccess = SimpleService.instantiationCount;
      for (var i = 0; i < 100; i++) {
        registry.getInstance<SimpleService>('lazy-key-$i');
      }
      expect(SimpleService.instantiationCount, equals(firstAccess));
    });

    test('mixed eager and lazy with 500 of each type', () {
      const eagerCount = 500;
      const lazyCount = 500;

      for (var i = 0; i < eagerCount; i++) {
        registry.register<SimpleService>('eager-$i', SimpleService(name: 'eager-$i'));
      }

      for (var i = 0; i < lazyCount; i++) {
        final idx = i;
        registry.registerLazy<SimpleService>('lazy-$i', () {
          return SimpleService(name: 'lazy-$idx');
        });
      }

      expect(registry.registrySize, equals(eagerCount + lazyCount));

      expect(
        registry.getInstance<SimpleService>('eager-100').name,
        equals('eager-100'),
      );
      expect(
        registry.getInstance<SimpleService>('lazy-100').name,
        equals('lazy-100'),
      );
      expect(
        registry.getInstance<SimpleService>('eager-450').name,
        equals('eager-450'),
      );
      expect(
        registry.getInstance<SimpleService>('lazy-450').name,
        equals('lazy-450'),
      );
    });

    test('rapid sequential registrations and unregistrations', () {
      const iterations = 500;

      for (var i = 0; i < iterations; i++) {
        final service = SimpleService(name: 'rapid-$i');
        registry.register<SimpleService>('key', service);
        expect(registry.contains<SimpleService>('key'), isTrue);

        registry.unregister<SimpleService>('key');
        expect(registry.contains<SimpleService>('key'), isFalse);
      }

      expect(registry.isEmpty, isTrue);
    });

    test('replace operations on same key 100 times', () {
      var lastVersion = 0;

      for (var i = 0; i < 100; i++) {
        final service = SimpleService(name: 'version-$i');
        if (i == 0) {
          registry.register<SimpleService>('replaceable', service);
        } else {
          registry.replace<SimpleService>('replaceable', service);
        }

        final wrapper = registry.getByKey<SimpleService>('replaceable')!;
        expect(wrapper.version, equals(lastVersion));
        lastVersion = wrapper.version + 1;
      }

      final finalVersion =
          registry.getByKey<SimpleService>('replaceable')!.version;
      expect(finalVersion, equals(99));
    });

    test('get keys operation with large registry', () {
      const count = 500;

      for (var i = 0; i < count; i++) {
        registry.register<SimpleService>('key-$i', SimpleService());
      }

      final keys = extractKeys(registry.keys);
      expect(keys, hasLength(count));

      for (var i = 0; i < count; i++) {
        expect(keys, contains('key-$i'));
      }
    });

    test('containment checks on large registry', () {
      const count = 300;

      for (var i = 0; i < count; i++) {
        registry.register<SimpleService>('key-$i', SimpleService());
      }

      for (var i = 0; i < count; i++) {
        expect(registry.contains<SimpleService>('key-$i'), isTrue);
      }

      for (var i = count; i < count + 100; i++) {
        expect(registry.contains<SimpleService>('key-$i'), isFalse);
      }
    });

    test('destroy all with large number of lazy entries', () {
      const count = 300;

      for (var i = 0; i < count; i++) {
        final idx = i;
        registry.registerLazy<SimpleService>('lazy-$i', () {
          return SimpleService(name: 'lazy-$idx');
        });
      }

      expect(SimpleService.instantiationCount, equals(0));

      registry.destroyAll();

      expect(registry.isEmpty, isTrue);
      expect(SimpleService.instantiationCount, equals(0));
    });

    test('destroy all with partially accessed lazy entries', () {
      const count = 300;

      for (var i = 0; i < count; i++) {
        final idx = i;
        registry.registerLazy<SimpleService>('lazy-$i', () {
          return SimpleService.counted(name: 'lazy-$idx');
        });
      }

      for (var i = 0; i < count ~/ 2; i++) {
        registry.getInstance<SimpleService>('lazy-$i');
      }

      expect(SimpleService.instantiationCount, equals(count ~/ 2));

      registry.destroyAll();

      expect(registry.isEmpty, isTrue);
      expect(SimpleService.instantiationCount, equals(count ~/ 2));
    });

    test('multiple sequential complete cycles', () {
      const cycleCount = 10;
      const itemsPerCycle = 100;

      for (var cycle = 0; cycle < cycleCount; cycle++) {
        for (var i = 0; i < itemsPerCycle; i++) {
          registry.register<SimpleService>(
            'cycle-$cycle-item-$i',
            SimpleService(),
          );
        }

        expect(registry.registrySize, equals(itemsPerCycle));

        for (var i = 0; i < 10; i++) {
          final service =
              registry.getInstance<SimpleService>('cycle-$cycle-item-$i');
          expect(service, isNotNull);
        }

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
          case 0:
            final service = SimpleService(name: 'op-$op');
            if (registry.contains<SimpleService>(key)) {
              registry.replace<SimpleService>(key, service);
            } else {
              registry.register<SimpleService>(key, service);
            }
          case 1:
            if (registry.contains<SimpleService>(key)) {
              registry.getInstance<SimpleService>(key);
            }
          case 2:
            registry.unregister<SimpleService>(key);
          case 3:
            registry.registrySize;
          default:
            break;
        }
      }

      registry.register<SimpleService>('final-test', SimpleService());
      expect(registry.getInstance<SimpleService>('final-test'), isNotNull);
    });

    test('registry size consistency during stress', () {
      expect(registry.registrySize, equals(0));

      for (var i = 0; i < 200; i++) {
        registry.register<SimpleService>('key-$i', SimpleService());
        expect(registry.registrySize, equals(i + 1));
      }

      for (var i = 0; i < 200; i++) {
        registry.unregister<SimpleService>('key-$i');
        expect(registry.registrySize, equals(200 - i - 1));
      }

      expect(registry.registrySize, equals(0));
    });

    test('keys property consistency during modifications', () {
      const iterations = 100;

      for (var i = 0; i < iterations; i++) {
        registry.register<SimpleService>('key-$i', SimpleService());

        final keys = extractKeys(registry.keys);
        expect(keys.length, equals(i + 1));
        expect(keys.contains('key-$i'), isTrue);
      }

      for (var i = 0; i < iterations; i++) {
        registry.unregister<SimpleService>('key-$i');

        final keys = extractKeys(registry.keys);
        expect(keys.length, equals(iterations - i - 1));
        expect(keys.contains('key-$i'), isFalse);
      }
    });

    test('factory function call count with repeated access', () {
      var callCount = 0;

      registry.registerLazy<SimpleService>('lazy', () {
        callCount++;
        return SimpleService(name: 'lazy-$callCount');
      });

      for (var i = 0; i < 1000; i++) {
        registry.getInstance<SimpleService>('lazy');
      }

      expect(callCount, equals(1));
    });

    test('verify order independence of operations', () {
      registry
        ..register<SimpleService>('a', SimpleService(name: 'a'))
        ..register<SimpleService>('b', SimpleService(name: 'b'))
        ..register<SimpleService>('c', SimpleService(name: 'c'));

      final c = registry.getInstance<SimpleService>('c');
      final a = registry.getInstance<SimpleService>('a');
      final b = registry.getInstance<SimpleService>('b');

      expect(a.name, equals('a'));
      expect(b.name, equals('b'));
      expect(c.name, equals('c'));

      registry
        ..unregister<SimpleService>('b')
        ..unregister<SimpleService>('a')
        ..unregister<SimpleService>('c');

      expect(registry.isEmpty, isTrue);
    });
  });
}
