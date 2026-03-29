import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Retrieval Methods', () {
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('getInstance() returns the exact instance registered', () {
      final service = SimpleService(name: 'test');
      registry.register<SimpleService>('key1', service);

      final retrieved = registry.getInstance<SimpleService>('key1');

      expect(retrieved, same(service));
    });

    test('getByKey() returns the version wrapper without resolving', () {
      final service = SimpleService(name: 'test');
      registry.register<SimpleService>('key1', service);

      final versionWrapper = registry.getByKey<SimpleService>('key1');

      expect(versionWrapper, isNotNull);
      expect(versionWrapper!.value, isNotNull);
    });

    test('getByKey() returns null for non-existent keys', () {
      final result = registry.getByKey<SimpleService>('nonexistent');

      expect(result, isNull);
    });

    test('keys returns all registered compound keys', () {
      registry
        ..register<SimpleService>('key1', SimpleService())
        ..register<SimpleService>('key2', SimpleService())
        ..register<SimpleService>('key3', SimpleService());

      expect(registry.keys, hasLength(3));
      expect(
        extractKeys(registry.keys),
        containsAll(['key1', 'key2', 'key3']),
      );
    });

    test('keys returns empty set for empty registry', () {
      expect(registry.keys, isEmpty);
    });

    test('isEmpty returns true when registry is empty', () {
      expect(registry.isEmpty, isTrue);
    });

    test('isEmpty returns false when registry has items', () {
      registry.register<SimpleService>('key1', SimpleService());

      expect(registry.isEmpty, isFalse);
    });

    test('isNotEmpty returns false when registry is empty', () {
      expect(registry.isNotEmpty, isFalse);
    });

    test('isNotEmpty returns true when registry has items', () {
      registry.register<SimpleService>('key1', SimpleService());

      expect(registry.isNotEmpty, isTrue);
    });

    test('getInstance() resolves lazy entries transparently', () {
      final registry2 = createTestRegistry<String>()
        ..registerLazy<SimpleService>('lazy', () => SimpleService(name: 'lazy'));

      final retrieved = registry2.getInstance<SimpleService>('lazy');

      expect(retrieved, isNotNull);
      expect(retrieved.name, equals('lazy'));

      cleanupRegistry(registry2);
    });

    test('multiple calls to getInstance() return same lazy instance', () {
      final registry2 = createTestRegistry<String>();
      SimpleService.instantiationCount = 0;

      registry2.registerLazy<SimpleService>('lazy', SimpleService.counted);

      final instance1 = registry2.getInstance<SimpleService>('lazy');
      final instance2 = registry2.getInstance<SimpleService>('lazy');

      expect(instance1, same(instance2));
      expect(SimpleService.instantiationCount, equals(1));

      cleanupRegistry(registry2);
    });
  });
}
