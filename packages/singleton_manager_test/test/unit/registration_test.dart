import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Eager Registration', () {
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
      SimpleService.instantiationCount = 0;
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('register() adds an eager value to the registry', () {
      final service = SimpleService(name: 'test');
      registry.register<SimpleService>('key1', service);

      expect(registry.contains<SimpleService>('key1'), isTrue);
      expect(registry.getInstance<SimpleService>('key1'), same(service));
    });

    test('register() throws DuplicateRegistrationError for duplicate keys', () {
      final service1 = SimpleService(name: 'first');
      final service2 = SimpleService(name: 'second');

      registry.register<SimpleService>('key1', service1);

      expect(
        () => registry.register<SimpleService>('key1', service2),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('replace() updates an existing eager value', () {
      final service1 = SimpleService(name: 'first');
      final service2 = SimpleService(name: 'second');

      registry
        ..register<SimpleService>('key1', service1)
        ..replace<SimpleService>('key1', service2);

      expect(registry.getInstance<SimpleService>('key1'), same(service2));
      expect(service1.destroyed, isTrue);
    });

    test('replace() throws RegistryNotFoundError if key does not exist', () {
      final service = SimpleService();

      expect(
        () => registry.replace<SimpleService>('nonexistent', service),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('unregister() removes a value from the registry', () {
      final service = SimpleService();
      registry.register<SimpleService>('key1', service);

      final unregistered = registry.unregister<SimpleService>('key1');

      expect(unregistered, isNotNull);
      expect(registry.contains<SimpleService>('key1'), isFalse);
    });

    test('getInstance() throws RegistryNotFoundError if key not found', () {
      expect(
        () => registry.getInstance<SimpleService>('nonexistent'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('contains() correctly identifies registered keys', () {
      final service = SimpleService();
      registry.register<SimpleService>('key1', service);

      expect(registry.contains<SimpleService>('key1'), isTrue);
      expect(registry.contains<SimpleService>('key2'), isFalse);
    });

    test('keys property returns all registered compound keys', () {
      registry
        ..register<SimpleService>('key1', SimpleService())
        ..register<SimpleService>('key2', SimpleService());

      expect(registry.keys, hasLength(2));
      expect(extractKeys(registry.keys), containsAll(['key1', 'key2']));
    });

    test('isEmpty returns true for empty registry', () {
      expect(registry.isEmpty, isTrue);
    });

    test('isNotEmpty returns true when registry has items', () {
      registry.register<SimpleService>('key1', SimpleService());

      expect(registry.isNotEmpty, isTrue);
    });

    test('registrySize returns the correct number of entries', () {
      final service1 = SimpleService();
      final service2 = SimpleService();

      expect(registry.registrySize, equals(0));

      registry.register<SimpleService>('key1', service1);
      expect(registry.registrySize, equals(1));

      registry.register<SimpleService>('key2', service2);
      expect(registry.registrySize, equals(2));
    });
  });
}
