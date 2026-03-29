import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Lazy Registration', () {
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
      LazyService.reset();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('registerLazy() adds a lazy value without calling the factory', () {
      registry.registerLazy<LazyService>('key1', LazyService.tracked);

      expect(LazyService.constructorCalled, isFalse);
      expect(registry.contains<LazyService>('key1'), isTrue);
    });

    test('registerLazy() throws DuplicateRegistrationError for duplicate keys',
        () {
      registry.registerLazy<LazyService>('key1', LazyService.new);

      expect(
        () => registry.registerLazy<LazyService>('key1', LazyService.new),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('getInstance() calls the factory function on first access', () {
      registry.registerLazy<LazyService>('key1', LazyService.tracked);

      expect(LazyService.constructorCalled, isFalse);

      final service = registry.getInstance<LazyService>('key1');

      expect(LazyService.constructorCalled, isTrue);
      expect(service, isNotNull);
    });

    test('getInstance() caches the lazy instance on subsequent calls', () {
      registry.registerLazy<LazyService>('key1', LazyService.tracked);

      final service1 = registry.getInstance<LazyService>('key1');
      final service2 = registry.getInstance<LazyService>('key1');

      expect(service1, same(service2));
      expect(LazyService.instantiationCount, equals(1));
    });

    test('replaceLazy() updates a lazy entry and destroys the old one', () {
      registry
        ..registerLazy<LazyService>('key1', LazyService.new)
        ..getInstance<LazyService>('key1');

      LazyService.reset();

      registry.replaceLazy<LazyService>('key1', LazyService.tracked);

      final newService = registry.getInstance<LazyService>('key1');

      expect(newService, isNotNull);
      expect(LazyService.instantiationCount, equals(1));
    });

    test('replaceLazy() throws RegistryNotFoundError if key does not exist', () {
      expect(
        () => registry.replaceLazy<LazyService>('nonexistent', LazyService.new),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('mixed eager and lazy registrations work together', () {
      final eagerService = LazyService();
      registry
        ..register<LazyService>('eager', eagerService)
        ..registerLazy<LazyService>('lazy', LazyService.tracked);

      expect(LazyService.constructorCalled, isFalse);

      final retrievedEager = registry.getInstance<LazyService>('eager');
      expect(retrievedEager, same(eagerService));

      final retrievedLazy = registry.getInstance<LazyService>('lazy');
      expect(LazyService.constructorCalled, isTrue);
      expect(retrievedLazy, isNotNull);
    });

    test('getInstance() throws RegistryNotFoundError for missing lazy keys', () {
      expect(
        () => registry.getInstance<LazyService>('nonexistent'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });
  });
}
