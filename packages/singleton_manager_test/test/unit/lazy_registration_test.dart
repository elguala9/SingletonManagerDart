import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('RegistryManager - Lazy Registration', () {
    late RegistryManager<String, LazyService> registry;

    setUp(() {
      registry = createTestRegistry();
      LazyService.reset();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('registerLazy() adds a lazy value without calling the factory', () {
      registry.registerLazy('key1', () => LazyService.tracked());

      expect(LazyService.constructorCalled, isFalse);
      expect(registry.contains('key1'), isTrue);
    });

    test('registerLazy() throws DuplicateRegistrationError for duplicate keys',
        () {
      registry.registerLazy('key1', () => LazyService());

      expect(
        () => registry.registerLazy('key1', () => LazyService()),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('getInstance() calls the factory function on first access', () {
      registry.registerLazy('key1', () => LazyService.tracked());

      expect(LazyService.constructorCalled, isFalse);

      final service = registry.getInstance('key1');

      expect(LazyService.constructorCalled, isTrue);
      expect(service, isNotNull);
    });

    test('getInstance() caches the lazy instance on subsequent calls', () {
      registry.registerLazy('key1', () => LazyService.tracked());

      final service1 = registry.getInstance('key1');
      final service2 = registry.getInstance('key1');

      expect(service1, same(service2));
      expect(LazyService.instantiationCount, equals(1));
    });

    test('replaceLazy() updates a lazy entry and destroys the old one', () {
      registry.registerLazy('key1', () => LazyService());

      // Access it to initialize
      final oldService = registry.getInstance('key1') as LazyService;
      final wasInitialized = oldService.destroyed == false;

      LazyService.reset();

      registry.replaceLazy('key1', () => LazyService.tracked());

      // The old service should not be destroyed until a new one is created
      final newService = registry.getInstance('key1');

      expect(newService, isNotNull);
      expect(LazyService.instantiationCount, equals(1));
    });

    test('replaceLazy() throws RegistryNotFoundError if key does not exist', () {
      expect(
        () => registry.replaceLazy('nonexistent', () => LazyService()),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('mixed eager and lazy registrations work together', () {
      final eagerService = LazyService();
      registry.register('eager', eagerService);
      registry.registerLazy('lazy', () => LazyService.tracked());

      expect(LazyService.constructorCalled, isFalse);

      final retrievedEager = registry.getInstance('eager');
      expect(retrievedEager, same(eagerService));

      final retrievedLazy = registry.getInstance('lazy');
      expect(LazyService.constructorCalled, isTrue);
      expect(retrievedLazy, isNotNull);
    });

    test('getInstance() throws RegistryNotFoundError for missing lazy keys', () {
      expect(
        () => registry.getInstance('nonexistent'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });
  });
}
