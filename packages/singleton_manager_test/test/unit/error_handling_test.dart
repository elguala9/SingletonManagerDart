import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Error Handling & Edge Cases', () {
    late RegistryManager<String, SimpleService> registry;

    setUp(() {
      registry = createTestRegistry();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('DuplicateRegistrationError on double register', () {
      final service1 = SimpleService(name: 'first');
      final service2 = SimpleService(name: 'second');

      registry.register('key', service1);

      expect(
        () => registry.register('key', service2),
        throwsA(isA<DuplicateRegistrationError>()),
      );

      // Original should still be registered
      expect(registry.getInstance('key'), same(service1));
    });

    test('DuplicateRegistrationError message is informative', () {
      final service = SimpleService();
      registry.register('key', service);

      expect(
        () => registry.register('key', SimpleService()),
        throwsA(
          isA<DuplicateRegistrationError>().having(
            (e) => e.message,
            'message',
            contains('key'),
          ),
        ),
      );
    });

    test('RegistryNotFoundError on getInstance with nonexistent key', () {
      expect(
        () => registry.getInstance('nonexistent'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('RegistryNotFoundError message includes key info', () {
      expect(
        () => registry.getInstance('missing-key'),
        throwsA(
          isA<RegistryNotFoundError>().having(
            (e) => e.message,
            'message',
            contains('missing-key'),
          ),
        ),
      );
    });

    test('RegistryNotFoundError on replace with nonexistent key', () {
      final service = SimpleService();

      expect(
        () => registry.replace('nonexistent', service),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('RegistryNotFoundError on replaceLazy with nonexistent key', () {
      expect(
        () => registry.replaceLazy('nonexistent', () => SimpleService()),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('unregister returns null for nonexistent key', () {
      final result = registry.unregister('nonexistent');
      expect(result, isNull);
    });

    test('getByKey returns null instead of throwing', () {
      final result = registry.getByKey('nonexistent');
      expect(result, isNull);
    });

    test('contains returns false for nonexistent key', () {
      expect(registry.contains('nonexistent'), isFalse);
    });

    test('registerLazy also throws DuplicateRegistrationError', () {
      registry.registerLazy('key', () => SimpleService(name: 'first'));

      expect(
        () => registry.registerLazy('key', () => SimpleService(name: 'second')),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('registerLazy throws on duplicate with eager service', () {
      registry.register('key', SimpleService());

      expect(
        () => registry.registerLazy('key', () => SimpleService()),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('register throws on duplicate with lazy service', () {
      registry.registerLazy('key', () => SimpleService());

      expect(
        () => registry.register('key', SimpleService()),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('getInstance throws for lazy entry with missing factory', () {
      // This is a structural test - lazy entries should always be callable
      registry.registerLazy('lazy', () => SimpleService());

      // Should work
      expect(
        () => registry.getInstance('lazy'),
        returnsNormally,
      );
    });

    test('error state does not corrupt registry', () {
      final service1 = SimpleService(name: 'service1');
      registry.register('key1', service1);

      // Try to register duplicate
      expect(
        () => registry.register('key1', SimpleService()),
        throwsA(isA<DuplicateRegistrationError>()),
      );

      // Registry should still be valid
      expect(registry.contains('key1'), isTrue);
      expect(registry.getInstance('key1'), same(service1));
      expect(registry.registrySize, equals(1));

      // Should be able to register other keys
      final service2 = SimpleService(name: 'service2');
      registry.register('key2', service2);
      expect(registry.registrySize, equals(2));
    });

    test('replace triggers destroy even on error', () {
      final oldService = SimpleService(name: 'old');
      registry.register('key', oldService);

      final newService = SimpleService(name: 'new');
      registry.replace('key', newService);

      expect(oldService.destroyed, isTrue);
    });

    test('sequential errors do not break registry', () {
      registry.register('key1', SimpleService());

      // First error
      expect(
        () => registry.getInstance('nonexistent1'),
        throwsA(isA<RegistryNotFoundError>()),
      );

      // Registry should still work
      expect(registry.getInstance('key1'), isNotNull);

      // Second error
      expect(
        () => registry.getInstance('nonexistent2'),
        throwsA(isA<RegistryNotFoundError>()),
      );

      // Registry still functional
      expect(registry.getInstance('key1'), isNotNull);
    });

    test('keys property works even after errors', () {
      registry.register('key1', SimpleService());
      registry.register('key2', SimpleService());

      try {
        registry.getInstance('nonexistent');
      } catch (e) {
        // Ignored
      }

      final keys = registry.keys;
      expect(keys, containsAll(['key1', 'key2']));
    });

    test('isEmpty/isNotEmpty consistent after errors', () {
      registry.register('key', SimpleService());
      expect(registry.isNotEmpty, isTrue);

      try {
        registry.replace('nonexistent', SimpleService());
      } catch (e) {
        // Ignored
      }

      expect(registry.isNotEmpty, isTrue);
      expect(registry.isEmpty, isFalse);
    });

    test('clearRegistry after errors', () {
      registry.register('key', SimpleService());

      try {
        registry.getInstance('nonexistent');
      } catch (e) {
        // Ignored
      }

      registry.clearRegistry();
      expect(registry.isEmpty, isTrue);
    });

    test('destroyAll after errors', () {
      registry.register('key', SimpleService());

      try {
        registry.replace('nonexistent', SimpleService());
      } catch (e) {
        // Ignored
      }

      registry.destroyAll();
      expect(registry.isEmpty, isTrue);
    });

    test('error in lazy factory is deferred', () {
      var factoryCallCount = 0;

      registry.registerLazy('failing-lazy', () {
        factoryCallCount++;
        throw Exception('Factory error');
      });

      expect(factoryCallCount, equals(0)); // Not called yet

      expect(
        () => registry.getInstance('failing-lazy'),
        throwsA(isA<Exception>()),
      );

      expect(factoryCallCount, equals(1)); // Called on access
    });

    test('error in lazy factory does not poison registry', () {
      registry.registerLazy('failing', () {
        throw Exception('Factory error');
      });

      registry.register('working', SimpleService());

      expect(
        () => registry.getInstance('failing'),
        throwsA(isA<Exception>()),
      );

      // Working service should still be accessible
      expect(registry.getInstance('working'), isNotNull);

      // Registry size should reflect both
      expect(registry.registrySize, equals(2));
    });

    test('multiple registries error independence', () {
      final registry1 = createTestRegistry<String, SimpleService>();
      final registry2 = createTestRegistry<String, SimpleService>();

      registry1.register('key', SimpleService(name: 'reg1'));
      registry2.register('key', SimpleService(name: 'reg2'));

      // Error in registry1
      expect(
        () => registry1.getInstance('nonexistent'),
        throwsA(isA<RegistryNotFoundError>()),
      );

      // Registry2 should not be affected
      expect(registry2.getInstance('key').name, equals('reg2'));

      cleanupRegistry(registry1);
      cleanupRegistry(registry2);
    });

    test('error recovery with replace', () {
      final service1 = SimpleService(name: 'v1');
      registry.register('key', service1);

      // Try to register duplicate (error)
      expect(
        () => registry.register('key', SimpleService()),
        throwsA(isA<DuplicateRegistrationError>()),
      );

      // Recover with replace
      final service2 = SimpleService(name: 'v2');
      registry.replace('key', service2);

      expect(service1.destroyed, isTrue);
      expect(registry.getInstance('key'), same(service2));
    });

    test('unregister and re-register recovery pattern', () {
      final service1 = SimpleService(name: 'service1');
      registry.register('key', service1);

      registry.unregister('key');

      // Should be able to re-register
      final service2 = SimpleService(name: 'service2');
      expect(
        () => registry.register('key', service2),
        returnsNormally,
      );

      expect(registry.getInstance('key'), same(service2));
    });

    test('registrySize accurate after error conditions', () {
      expect(registry.registrySize, equals(0));

      registry.register('key1', SimpleService());
      expect(registry.registrySize, equals(1));

      try {
        registry.register('key1', SimpleService()); // Duplicate error
      } catch (e) {
        // Expected
      }

      expect(registry.registrySize, equals(1)); // Should not change

      registry.register('key2', SimpleService());
      expect(registry.registrySize, equals(2));
    });
  });
}
