import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('SingletonManager - Registration', () {
    late SingletonManager<String> manager;

    setUp(() {
      manager = createTestManager();
    });

    tearDown(() {
      manager.clear();
    });

    test('register creates an eager singleton', () {
      manager.register('service', () => TestService());

      expect(manager.contains('service'), isTrue);
      expect(manager.length, equals(1));
    });

    test('registerLazy creates a lazy singleton', () {
      manager.registerLazy('service', () => TestService());

      expect(manager.contains('service'), isTrue);
      expect(manager.length, equals(1));
    });

    test('register throws StateError if key already exists', () {
      manager.register('service', () => TestService());

      expect(
        () => manager.register('service', () => TestService()),
        throwsStateError,
      );
    });

    test('registerLazy throws StateError if key already exists', () {
      manager.registerLazy('service', () => TestService());

      expect(
        () => manager.registerLazy('service', () => TestService()),
        throwsStateError,
      );
    });

    test('register throws StateError if lazy key already exists', () {
      manager.registerLazy('service', () => TestService());

      expect(
        () => manager.register('service', () => TestService()),
        throwsStateError,
      );
    });

    test('registerLazy throws StateError if eager key already exists', () {
      manager.register('service', () => TestService());

      expect(
        () => manager.registerLazy('service', () => TestService()),
        throwsStateError,
      );
    });

    test('multiple singletons can be registered', () {
      manager.register('service1', () => TestService(name: 'service1'));
      manager.register('service2', () => TestService(name: 'service2'));
      manager.registerLazy('service3', () => TestService(name: 'service3'));

      expect(manager.length, equals(3));
      expect(manager.contains('service1'), isTrue);
      expect(manager.contains('service2'), isTrue);
      expect(manager.contains('service3'), isTrue);
    });
  });
}
