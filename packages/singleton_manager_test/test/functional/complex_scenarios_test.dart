import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('SingletonManager - Complex Scenarios', () {
    late SingletonManager<String> manager;

    setUp(() {
      manager = createTestManager();
    });

    tearDown(() {
      manager.clear();
    });

    test('dependency chain with eager singletons', () {
      final service1 = TestService(name: 'service1');
      final service2 = TestService(name: 'service2');

      manager.register('service1', () => service1);
      manager.register('service2', () => service2);

      final retrieved1 = manager.get('service1');
      final retrieved2 = manager.get('service2');

      expect(retrieved1, same(service1));
      expect(retrieved2, same(service2));
    });

    test('lazy loading performance advantage', () {
      var heavyServiceCreated = false;

      manager.registerLazy('heavy', () {
        heavyServiceCreated = true;
        return HeavyService();
      });

      expect(heavyServiceCreated, isFalse);

      manager.get('heavy');

      expect(heavyServiceCreated, isTrue);
    });

    test('mixed eager and lazy singletons', () {
      CountedService.reset();

      manager.register('eager1', () => CountedService());
      manager.registerLazy('lazy1', () => CountedService());
      manager.register('eager2', () => CountedService());
      manager.registerLazy('lazy2', () => CountedService());

      expect(CountedService.instanceCount, equals(2));

      manager.get('lazy1');
      expect(CountedService.instanceCount, equals(3));

      manager.get('lazy2');
      expect(CountedService.instanceCount, equals(4));
    });

    test('multiple manager instances are independent', () {
      final manager1 = createTestManager();
      final manager2 = createTestManager();

      manager1.register('service', () => TestService(name: 'manager1'));
      manager2.register('service', () => TestService(name: 'manager2'));

      final service1 = manager1.get('service');
      final service2 = manager2.get('service');

      expect(service1.name, equals('manager1'));
      expect(service2.name, equals('manager2'));
      expect(service1, isNot(same(service2)));
    });

    test('generic key types work correctly', () {
      final intManager = createTestManagerWithKeyType<int>();
      final doubleManager = createTestManagerWithKeyType<double>();

      intManager.register(1, () => TestService(name: 'int-service'));
      doubleManager.register(1.0, () => TestService(name: 'double-service'));

      final intService = intManager.get(1);
      final doubleService = doubleManager.get(1.0);

      expect(intService.name, equals('int-service'));
      expect(doubleService.name, equals('double-service'));
    });
  });
}
