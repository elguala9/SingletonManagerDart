import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

void main() {
  group('SingletonManager - Lifecycle', () {
    late SingletonManager<String> manager;

    setUp(() {
      manager = createTestManager();
    });

    tearDown(() {
      manager.clear();
    });

    test('remove deletes a singleton', () {
      manager.register('service', () => TestService());
      expect(manager.contains('service'), isTrue);

      manager.remove('service');

      expect(manager.contains('service'), isFalse);
    });

    test('remove throws StateError if singleton not found', () {
      expect(
        () => manager.remove('nonexistent'),
        throwsStateError,
      );
    });

    test('clear removes all singletons', () {
      manager.register('service1', () => TestService());
      manager.register('service2', () => TestService());
      manager.registerLazy('service3', () => TestService());

      expect(manager.length, equals(3));

      manager.clear();

      expect(manager.isEmpty, isTrue);
      expect(manager.length, equals(0));
    });

    test('clear allows re-registering same keys', () {
      manager.register('service', () => TestService(name: 'first'));
      final first = manager.get('service');

      manager.clear();

      manager.register('service', () => TestService(name: 'second'));
      final second = manager.get('service');

      expect(first.name, equals('first'));
      expect(second.name, equals('second'));
      expect(first, isNot(same(second)));
    });

    test('keys returns all registered keys', () {
      manager.register('service1', () => TestService());
      manager.register('service2', () => TestService());
      manager.registerLazy('service3', () => TestService());

      final keys = manager.keys.toList();

      expect(keys, containsAll(['service1', 'service2', 'service3']));
      expect(keys.length, equals(3));
    });

    test('length counts all singletons', () {
      expect(manager.length, equals(0));

      manager.register('service1', () => TestService());
      expect(manager.length, equals(1));

      manager.register('service2', () => TestService());
      expect(manager.length, equals(2));

      manager.registerLazy('service3', () => TestService());
      expect(manager.length, equals(3));

      manager.remove('service1');
      expect(manager.length, equals(2));
    });

    test('isEmpty returns correct state', () {
      expect(manager.isEmpty, isTrue);

      manager.register('service', () => TestService());
      expect(manager.isEmpty, isFalse);

      manager.clear();
      expect(manager.isEmpty, isTrue);
    });
  });
}
