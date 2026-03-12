import 'package:singleton_manager/src/interfaces/i_value_for_registry.dart';
import 'package:singleton_manager/src/singleton/singleton_manager.dart';
import 'package:test/test.dart';

/// Mock implementation that tracks lifecycle calls
class MockService implements IValueForRegistry {
  final String id;
  bool isDestroyed = false;

  MockService(this.id);

  @override
  void destroy() {
    isDestroyed = true;
  }
}

/// Regular service without lifecycle
class RegularService {
  final String id;

  RegularService(this.id);
}

/// Service that counts destroy calls
class CountingService implements IValueForRegistry {
  int destroyCount = 0;

  @override
  void destroy() => destroyCount++;
}

void main() {
  group('SingletonManager - Lifecycle & Destroy', () {
    late SingletonManager manager;

    setUp(() {
      manager = SingletonManager.instance;
      // Start fresh
      manager.clearRegistry();
    });

    group('register() - destroy on replacement', () {
      test('should destroy previous value when replacing with IValueForRegistry',
          () {
        final old = MockService('old');
        final replacement = MockService('replacement');

        manager.register<MockService>(old);
        expect(old.isDestroyed, false, reason: 'old service not destroyed yet');

        manager.register<MockService>(replacement);
        expect(old.isDestroyed, true,
            reason: 'old service should be destroyed on replacement');
        expect(replacement.isDestroyed, false,
            reason: 'new service should not be destroyed');
      });

      test('should handle replacing non-IValueForRegistry with IValueForRegistry',
          () {
        final regularService = RegularService('regular');
        final mockService = MockService('mock');

        manager.register<RegularService>(regularService);
        manager.register<MockService>(mockService);

        // Replace with different type
        final newMock = MockService('newMock');
        manager.register<MockService>(newMock);

        expect(mockService.isDestroyed, true,
            reason: 'previous mock should be destroyed');
        expect(newMock.isDestroyed, false);
      });

      test('should not crash when replacing non-IValueForRegistry service', () {
        final regular = RegularService('1');
        final replacement = RegularService('2');

        manager.register<RegularService>(regular);
        expect(() {
          manager.register<RegularService>(replacement);
        }, returnsNormally);

        final retrieved = manager.getInstance<RegularService>();
        expect(retrieved.id, '2');
      });

      test('multiple replacements call destroy each time', () {
        final services = [
          MockService('1'),
          MockService('2'),
          MockService('3'),
        ];

        for (final service in services) {
          manager.register<MockService>(service);
        }

        expect(services[0].isDestroyed, true, reason: 'first should be destroyed');
        expect(services[1].isDestroyed, true, reason: 'second should be destroyed');
        expect(services[2].isDestroyed, false,
            reason: 'last should not be destroyed');
      });
    });

    group('unregister() - destroy on removal', () {
      test('should destroy value when unregistering', () {
        final service = MockService('test');
        manager.register<MockService>(service);

        expect(service.isDestroyed, false);
        manager.unregister<MockService>();
        expect(service.isDestroyed, true,
            reason: 'service should be destroyed on unregister');
      });

      test('should not crash unregistering non-existent key', () {
        expect(
          () => manager.unregister<MockService>(),
          returnsNormally,
          reason: 'unregister non-existent key should not crash',
        );
      });

      test('should not crash unregistering non-IValueForRegistry service', () {
        final service = RegularService('test');
        manager.register<RegularService>(service);

        expect(
          () => manager.unregister<RegularService>(),
          returnsNormally,
          reason: 'unregister non-IValueForRegistry should not crash',
        );
      });

      test('unregistering same key twice should be safe', () {
        final service = MockService('test');
        manager.register<MockService>(service);

        manager.unregister<MockService>();
        expect(service.isDestroyed, true);

        expect(
          () => manager.unregister<MockService>(),
          returnsNormally,
          reason: 'second unregister should not crash',
        );
      });
    });

    group('clearRegistry() - should NOT destroy', () {
      test('clearRegistry should not call destroy on IValueForRegistry', () {
        final service1 = MockService('1');

        manager.register<MockService>(service1);
        manager.register<RegularService>(RegularService('regular'));

        manager.clearRegistry();

        expect(service1.isDestroyed, false,
            reason: 'clearRegistry should not destroy values');
      });

      test('clearRegistry should still remove all entries', () {
        manager.register<MockService>(MockService('1'));
        manager.register<RegularService>(RegularService('2'));

        expect(manager.registrySize, 2);
        manager.clearRegistry();
        expect(manager.registrySize, 0);
      });

      test('after clearRegistry, getInstance should throw', () {
        final service = MockService('test');
        manager.register<MockService>(service);
        manager.clearRegistry();

        expect(
          () => manager.getInstance<MockService>(),
          throwsStateError,
        );
      });
    });

    group('destroyAll() - destroy all and clear', () {
      test('destroyAll should destroy all IValueForRegistry instances', () {
        final mock1 = MockService('1');
        final mock2 = MockService('2');
        final regular = RegularService('regular');

        manager.register<MockService>(mock1);
        // Store in a different type key to have multiple services
        manager.register(mock2);
        manager.register<RegularService>(regular);

        manager.destroyAll();

        expect(mock1.isDestroyed, true);
        expect(mock2.isDestroyed, true);
        expect(manager.registrySize, 0);
      });

      test('destroyAll should clear registry', () {
        manager.register<MockService>(MockService('1'));
        manager.register<RegularService>(RegularService('2'));
        manager.register<String>('test');

        expect(manager.registrySize, 3);
        manager.destroyAll();
        expect(manager.registrySize, 0);
      });

      test('destroyAll should not crash with empty registry', () {
        expect(
          () => manager.destroyAll(),
          returnsNormally,
        );
      });

      test('destroyAll with mixed IValueForRegistry and regular services', () {
        final mock = MockService('mock');
        final regular = RegularService('regular');
        final string = 'string';

        manager.register<MockService>(mock);
        manager.register<RegularService>(regular);
        manager.register<String>(string);

        expect(manager.registrySize, 3);
        manager.destroyAll();

        expect(mock.isDestroyed, true);
        expect(manager.registrySize, 0);
      });

      test('after destroyAll, getInstance should throw', () {
        manager.register<MockService>(MockService('test'));
        manager.destroyAll();

        expect(
          () => manager.getInstance<MockService>(),
          throwsStateError,
        );
      });
    });

    group('difference between clearRegistry and destroyAll', () {
      test('clearRegistry does NOT call destroy, destroyAll does', () {
        final service1 = MockService('1');

        manager.register<MockService>(service1);
        manager.register<RegularService>(RegularService('regular'));

        // clearRegistry - no destroy
        manager.clearRegistry();
        expect(service1.isDestroyed, false,
            reason: 'clearRegistry should not destroy MockService');

        // Register again for destroyAll test
        final service3 = MockService('3');
        manager.register<MockService>(service3);

        // destroyAll - should destroy
        manager.destroyAll();
        expect(service3.isDestroyed, true,
            reason: 'destroyAll should destroy');
      });
    });

    group('complex scenarios', () {
      test('register -> unregister -> register flow', () {
        final service1 = MockService('1');
        final service2 = MockService('2');

        manager.register<MockService>(service1);
        expect(service1.isDestroyed, false);

        manager.unregister<MockService>();
        expect(service1.isDestroyed, true);

        manager.register<MockService>(service2);
        expect(service2.isDestroyed, false);

        manager.destroyAll();
        expect(service2.isDestroyed, true);
      });

      test('rapid replacements all trigger destroy', () {
        final services = List.generate(10, (i) => MockService('$i'));

        for (final service in services) {
          manager.register<MockService>(service);
        }

        // All but the last should be destroyed
        for (int i = 0; i < services.length - 1; i++) {
          expect(services[i].isDestroyed, true,
              reason: 'service $i should be destroyed by replacement');
        }

        expect(services.last.isDestroyed, false,
            reason: 'last service should not be destroyed');

        manager.destroyAll();
        expect(services.last.isDestroyed, true);
      });

      test('destroy is called exactly once per service lifetime', () {
        final service = CountingService();
        manager.register<CountingService>(service);
        expect(service.destroyCount, 0);

        manager.unregister<CountingService>();
        expect(service.destroyCount, 1);

        final service2 = CountingService();
        manager.register<CountingService>(service2);
        expect(service2.destroyCount, 0);

        manager.destroyAll();
        expect(service2.destroyCount, 1);
      });

      test('replacing on top of non-IValueForRegistry then with IValueForRegistry',
          () {
        final regular = RegularService('regular');
        manager.register<Object>(regular);

        final mock = MockService('mock');
        manager.register<Object>(mock);
        expect(mock.isDestroyed, false);

        manager.destroyAll();
        expect(mock.isDestroyed, true);
      });
    });
  });
}
