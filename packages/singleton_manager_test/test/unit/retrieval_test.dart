import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('SingletonManager - Retrieval', () {
    late SingletonManager<String> manager;

    setUp(() {
      manager = createTestManager();
    });

    tearDown(() {
      manager.clear();
    });

    test('get returns registered singleton', () {
      final service = TestService(name: 'test1');
      manager.register('service', () => service);

      final retrieved = manager.get('service');

      expect(retrieved, same(service));
    });

    test('get returns same instance on multiple calls', () {
      manager.register('service', () => TestService());

      final first = manager.get('service');
      final second = manager.get('service');
      final third = manager.get('service');

      expect(first, same(second));
      expect(second, same(third));
    });

    test('get throws StateError if singleton not found', () {
      expect(
        () => manager.get('nonexistent'),
        throwsStateError,
      );
    });

    test('get creates lazy singleton on first access', () {
      CountedService.reset();

      manager.registerLazy('service', () => CountedService());

      expect(CountedService.instanceCount, equals(0));

      final instance = manager.get('service');

      expect(CountedService.instanceCount, equals(1));
      expect(instance, isNotNull);
    });

    test('get returns same instance for lazy singleton on subsequent calls', () {
      CountedService.reset();

      manager.registerLazy('service', () => CountedService());

      final first = manager.get('service');
      final second = manager.get('service');

      expect(first, same(second));
      expect(CountedService.instanceCount, equals(1));
    });

    test('different singletons return different instances', () {
      manager.register('service1', () => TestService(name: 'service1'));
      manager.register('service2', () => TestService(name: 'service2'));

      final instance1 = manager.get('service1');
      final instance2 = manager.get('service2');

      expect(instance1, isNot(same(instance2)));
      expect(instance1.name, equals('service1'));
      expect(instance2.name, equals('service2'));
    });
  });
}
