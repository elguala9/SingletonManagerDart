import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Error Handling & Edge Cases', () {
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('DuplicateRegistrationError on double register', () {
      final service1 = SimpleService(name: 'first');
      final service2 = SimpleService(name: 'second');

      registry.register<SimpleService>('key', service1);

      expect(
        () => registry.register<SimpleService>('key', service2),
        throwsA(isA<DuplicateRegistrationError>()),
      );

      expect(registry.getInstance<SimpleService>('key'), same(service1));
    });

    test('DuplicateRegistrationError message is informative', () {
      final service = SimpleService();
      registry.register<SimpleService>('key', service);

      expect(
        () => registry.register<SimpleService>('key', SimpleService()),
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
        () => registry.getInstance<SimpleService>('nonexistent'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('RegistryNotFoundError message includes key info', () {
      expect(
        () => registry.getInstance<SimpleService>('missing-key'),
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
        () => registry.replace<SimpleService>('nonexistent', service),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('RegistryNotFoundError on replaceLazy with nonexistent key', () {
      expect(
        () => registry.replaceLazy<SimpleService>('nonexistent', SimpleService.new),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('unregister returns null for nonexistent key', () {
      final result = registry.unregister<SimpleService>('nonexistent');
      expect(result, isNull);
    });

    test('getByKey returns null instead of throwing', () {
      final result = registry.getByKey<SimpleService>('nonexistent');
      expect(result, isNull);
    });

    test('contains returns false for nonexistent key', () {
      expect(registry.contains<SimpleService>('nonexistent'), isFalse);
    });

    test('registerLazy also throws DuplicateRegistrationError', () {
      registry.registerLazy<SimpleService>(
        'key',
        () => SimpleService(name: 'first'),
      );

      expect(
        () => registry.registerLazy<SimpleService>(
          'key',
          () => SimpleService(name: 'second'),
        ),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('registerLazy throws on duplicate with eager service', () {
      registry.register<SimpleService>('key', SimpleService());

      expect(
        () => registry.registerLazy<SimpleService>('key', SimpleService.new),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('register throws on duplicate with lazy service', () {
      registry.registerLazy<SimpleService>('key', SimpleService.new);

      expect(
        () => registry.register<SimpleService>('key', SimpleService()),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('getInstance works for lazy entry', () {
      registry.registerLazy<SimpleService>('lazy', SimpleService.new);

      expect(
        () => registry.getInstance<SimpleService>('lazy'),
        returnsNormally,
      );
    });

    test('error state does not corrupt registry', () {
      final service1 = SimpleService(name: 'service1');
      registry.register<SimpleService>('key1', service1);

      expect(
        () => registry.register<SimpleService>('key1', SimpleService()),
        throwsA(isA<DuplicateRegistrationError>()),
      );

      expect(registry.contains<SimpleService>('key1'), isTrue);
      expect(registry.getInstance<SimpleService>('key1'), same(service1));
      expect(registry.registrySize, equals(1));

      final service2 = SimpleService(name: 'service2');
      registry.register<SimpleService>('key2', service2);
      expect(registry.registrySize, equals(2));
    });

    test('replace triggers destroy on old value', () {
      final oldService = SimpleService(name: 'old');
      registry.register<SimpleService>('key', oldService);

      final newService = SimpleService(name: 'new');
      registry.replace<SimpleService>('key', newService);

      expect(oldService.destroyed, isTrue);
    });

    test('sequential errors do not break registry', () {
      registry.register<SimpleService>('key1', SimpleService());

      expect(
        () => registry.getInstance<SimpleService>('nonexistent1'),
        throwsA(isA<RegistryNotFoundError>()),
      );

      expect(registry.getInstance<SimpleService>('key1'), isNotNull);

      expect(
        () => registry.getInstance<SimpleService>('nonexistent2'),
        throwsA(isA<RegistryNotFoundError>()),
      );

      expect(registry.getInstance<SimpleService>('key1'), isNotNull);
    });

    test('keys property works even after errors', () {
      registry
        ..register<SimpleService>('key1', SimpleService())
        ..register<SimpleService>('key2', SimpleService());

      try {
        registry.getInstance<SimpleService>('nonexistent');
        // ignore: avoid_catching_errors
      } on RegistryError {
        // Ignored
      }

      expect(
        extractKeys(registry.keys),
        containsAll(['key1', 'key2']),
      );
    });

    test('isEmpty/isNotEmpty consistent after errors', () {
      registry.register<SimpleService>('key', SimpleService());
      expect(registry.isNotEmpty, isTrue);

      try {
        registry.replace<SimpleService>('nonexistent', SimpleService());
        // ignore: avoid_catching_errors
      } on RegistryError {
        // Ignored
      }

      expect(registry.isNotEmpty, isTrue);
      expect(registry.isEmpty, isFalse);
    });

    test('clearRegistry after errors', () {
      registry.register<SimpleService>('key', SimpleService());

      try {
        registry.getInstance<SimpleService>('nonexistent');
        // ignore: avoid_catching_errors
      } on RegistryError {
        // Ignored
      }

      registry.clearRegistry();
      expect(registry.isEmpty, isTrue);
    });

    test('destroyAll after errors', () {
      registry.register<SimpleService>('key', SimpleService());

      try {
        registry.replace<SimpleService>('nonexistent', SimpleService());
        // ignore: avoid_catching_errors
      } on RegistryError {
        // Ignored
      }

      registry.destroyAll();
      expect(registry.isEmpty, isTrue);
    });

    test('error in lazy factory is deferred', () {
      var factoryCallCount = 0;

      registry.registerLazy<SimpleService>('failing-lazy', () {
        factoryCallCount++;
        throw Exception('Factory error');
      });

      expect(factoryCallCount, equals(0));

      expect(
        () => registry.getInstance<SimpleService>('failing-lazy'),
        throwsA(isA<Exception>()),
      );

      expect(factoryCallCount, equals(1));
    });

    test('error in lazy factory does not poison registry', () {
      registry
        ..registerLazy<SimpleService>('failing', () {
          throw Exception('Factory error');
        })
        ..register<SimpleService>('working', SimpleService());

      expect(
        () => registry.getInstance<SimpleService>('failing'),
        throwsA(isA<Exception>()),
      );

      expect(registry.getInstance<SimpleService>('working'), isNotNull);
      expect(registry.registrySize, equals(2));
    });

    test('multiple registries error independence', () {
      final registry1 = createTestRegistry<String>();
      final registry2 = createTestRegistry<String>();

      registry1.register<SimpleService>('key', SimpleService(name: 'reg1'));
      registry2.register<SimpleService>('key', SimpleService(name: 'reg2'));

      expect(
        () => registry1.getInstance<SimpleService>('nonexistent'),
        throwsA(isA<RegistryNotFoundError>()),
      );

      expect(
        registry2.getInstance<SimpleService>('key').name,
        equals('reg2'),
      );

      cleanupRegistry(registry1);
      cleanupRegistry(registry2);
    });

    test('error recovery with replace', () {
      final service1 = SimpleService(name: 'v1');
      registry.register<SimpleService>('key', service1);

      expect(
        () => registry.register<SimpleService>('key', SimpleService()),
        throwsA(isA<DuplicateRegistrationError>()),
      );

      final service2 = SimpleService(name: 'v2');
      registry.replace<SimpleService>('key', service2);

      expect(service1.destroyed, isTrue);
      expect(registry.getInstance<SimpleService>('key'), same(service2));
    });

    test('unregister and re-register recovery pattern', () {
      final service1 = SimpleService(name: 'service1');
      registry
        ..register<SimpleService>('key', service1)
        ..unregister<SimpleService>('key');

      final service2 = SimpleService(name: 'service2');
      expect(
        () => registry.register<SimpleService>('key', service2),
        returnsNormally,
      );

      expect(registry.getInstance<SimpleService>('key'), same(service2));
    });

    test('registrySize accurate after error conditions', () {
      expect(registry.registrySize, equals(0));

      registry.register<SimpleService>('key1', SimpleService());
      expect(registry.registrySize, equals(1));

      try {
        registry.register<SimpleService>('key1', SimpleService());
        // ignore: avoid_catching_errors
      } on RegistryError {
        // Expected
      }

      expect(registry.registrySize, equals(1));

      registry.register<SimpleService>('key2', SimpleService());
      expect(registry.registrySize, equals(2));
    });
  });
}
