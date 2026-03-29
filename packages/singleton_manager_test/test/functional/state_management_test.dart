import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

/// A stateful service for tracking state transitions
class StatefulService implements IValueForRegistry {
  StatefulService({required this.id});

  final String id;
  String state = 'initialized';
  int actionCount = 0;
  bool destroyed = false;

  void performAction() {
    actionCount++;
  }

  void reset() {
    state = 'initialized';
    actionCount = 0;
  }

  @override
  void destroy() {
    destroyed = true;
  }
}

void main() {
  group('RegistryManager - State Management & Lifecycle', () {
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('state persistence across multiple retrievals', () {
      final service = StatefulService(id: 'state-1')
        ..performAction()
        ..performAction()
        ..state = 'active';

      registry.register<StatefulService>('service', service);

      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('active'),
      );
      expect(
        registry.getInstance<StatefulService>('service').actionCount,
        equals(2),
      );
      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('active'),
      );
      expect(
        registry.getInstance<StatefulService>('service').actionCount,
        equals(2),
      );
    });

    test('state mutation through retrieved reference', () {
      final service = StatefulService(id: 'mutable-1');
      registry.register<StatefulService>('service', service);

      final retrieved = registry.getInstance<StatefulService>('service');
      expect(retrieved.state, equals('initialized'));

      retrieved.state = 'modified';
      expect(retrieved.state, equals('modified'));

      final retrieved2 = registry.getInstance<StatefulService>('service');
      expect(retrieved2.state, equals('modified'));
      expect(identical(retrieved, retrieved2), isTrue);
    });

    test('state isolation between different services', () {
      final service1 = StatefulService(id: 'service-1');
      final service2 = StatefulService(id: 'service-2');

      service1.state = 'state-1';
      service2.state = 'state-2';

      registry
        ..register<StatefulService>('svc1', service1)
        ..register<StatefulService>('svc2', service2);

      expect(
        registry.getInstance<StatefulService>('svc1').state,
        equals('state-1'),
      );
      expect(
        registry.getInstance<StatefulService>('svc2').state,
        equals('state-2'),
      );

      registry.getInstance<StatefulService>('svc1').state = 'state-1-modified';

      expect(
        registry.getInstance<StatefulService>('svc1').state,
        equals('state-1-modified'),
      );
      expect(
        registry.getInstance<StatefulService>('svc2').state,
        equals('state-2'),
      );
    });

    test('lazy service initial state on first access', () {
      final expectedService = StatefulService(id: 'lazy-1')
        ..state = 'lazy-state'
        ..performAction();

      registry.registerLazy<StatefulService>('lazy', () => expectedService);

      final retrieved = registry.getInstance<StatefulService>('lazy');

      expect(retrieved.state, equals('lazy-state'));
      expect(retrieved.actionCount, equals(1));
    });

    test('state changes reflected after replacement', () {
      final oldService = StatefulService(id: 'old')..state = 'old-state';
      registry.register<StatefulService>('service', oldService);

      final newService = StatefulService(id: 'new')
        ..state = 'new-state'
        ..performAction()
        ..performAction();

      registry.replace<StatefulService>('service', newService);

      expect(oldService.destroyed, isTrue);

      final retrieved = registry.getInstance<StatefulService>('service');
      expect(retrieved.id, equals('new'));
      expect(retrieved.state, equals('new-state'));
      expect(retrieved.actionCount, equals(2));
    });

    test('lifecycle: initialization -> mutation -> replacement', () {
      final service1 = StatefulService(id: 'v1')..state = 'initialized';

      registry.register<StatefulService>('service', service1);

      final retrieved = registry.getInstance<StatefulService>('service')
        ..performAction()
        ..performAction()
        ..state = 'active';

      expect(retrieved.actionCount, equals(2));
      expect(retrieved.state, equals('active'));

      final service2 = StatefulService(id: 'v2')..state = 'ready';

      registry.replace<StatefulService>('service', service2);

      expect(service1.destroyed, isTrue);
      expect(
        registry.getInstance<StatefulService>('service').id,
        equals('v2'),
      );
      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('ready'),
      );
    });

    test('stateful registry with multiple dependent services', () {
      final dbService = StatefulService(id: 'database');
      final cacheService = StatefulService(id: 'cache');
      final apiService = StatefulService(id: 'api');

      dbService.state = 'connected';
      cacheService.state = 'ready';
      apiService.state = 'listening';

      registry
        ..register<StatefulService>('db', dbService)
        ..register<StatefulService>('cache', cacheService)
        ..register<StatefulService>('api', apiService);

      registry.getInstance<StatefulService>('db').performAction();
      registry.getInstance<StatefulService>('cache').performAction();
      registry.getInstance<StatefulService>('api').performAction();
      registry.getInstance<StatefulService>('db').performAction();
      registry.getInstance<StatefulService>('api').performAction();

      expect(
        registry.getInstance<StatefulService>('db').actionCount,
        equals(2),
      );
      expect(
        registry.getInstance<StatefulService>('cache').actionCount,
        equals(1),
      );
      expect(
        registry.getInstance<StatefulService>('api').actionCount,
        equals(2),
      );
    });

    test('state reset pattern', () {
      final service = StatefulService(id: 'resettable')
        ..performAction()
        ..performAction()
        ..state = 'modified';

      registry.register<StatefulService>('service', service);

      expect(
        registry.getInstance<StatefulService>('service').actionCount,
        equals(2),
      );
      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('modified'),
      );

      registry.getInstance<StatefulService>('service').reset();

      expect(
        registry.getInstance<StatefulService>('service').actionCount,
        equals(0),
      );
      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('initialized'),
      );
    });

    test('state tracking across unregister and re-register', () {
      final service = StatefulService(id: 'trackable')
        ..performAction()
        ..state = 'tracked';

      registry.register<StatefulService>('service', service);
      expect(
        registry.getInstance<StatefulService>('service').actionCount,
        equals(1),
      );

      registry.unregister<StatefulService>('service');
      expect(service.actionCount, equals(1));

      registry.register<StatefulService>('service', service);
      expect(
        registry.getInstance<StatefulService>('service').actionCount,
        equals(1),
      );
    });

    test('cleanup preserves state until destroy', () {
      final service = StatefulService(id: 'cleanup-test')
        ..performAction()
        ..state = 'operational';

      registry
        ..register<StatefulService>('service', service)
        ..clearRegistry();

      expect(service.actionCount, equals(1));
      expect(service.state, equals('operational'));
      expect(service.destroyed, isFalse);

      service.destroy();
      expect(service.destroyed, isTrue);
    });

    test('concurrent state access through multiple references', () {
      final service = StatefulService(id: 'concurrent');
      registry.register<StatefulService>('service', service);

      final ref1 = registry.getInstance<StatefulService>('service');
      final ref2 = registry.getInstance<StatefulService>('service');
      final ref3 = registry.getInstance<StatefulService>('service');

      expect(identical(ref1, ref2), isTrue);
      expect(identical(ref2, ref3), isTrue);

      expect(ref1.state, equals(ref2.state));
      expect(ref2.state, equals(ref3.state));

      ref1.state = 'modified';
      expect(ref2.state, equals('modified'));
      expect(ref3.state, equals('modified'));
    });

    test('state machine pattern in registry', () {
      final service = StatefulService(id: 'state-machine');
      registry.register<StatefulService>('service', service);

      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('initialized'),
      );

      registry.getInstance<StatefulService>('service').state = 'starting';
      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('starting'),
      );

      registry.getInstance<StatefulService>('service').state = 'running';
      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('running'),
      );

      registry.getInstance<StatefulService>('service').state = 'stopping';
      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('stopping'),
      );

      registry.getInstance<StatefulService>('service').state = 'stopped';
      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('stopped'),
      );
    });

    test('state versioning through version wrapper', () {
      final service = StatefulService(id: 'versioned')..state = 'v1';
      registry.register<StatefulService>('service', service);

      var wrapper = registry.getByKey<StatefulService>('service')!;
      expect(wrapper.version, equals(0));
      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('v1'),
      );

      final newService = StatefulService(id: 'versioned-v2')..state = 'v2';
      registry.replace<StatefulService>('service', newService);

      wrapper = registry.getByKey<StatefulService>('service')!;
      expect(wrapper.version, equals(1));
      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('v2'),
      );

      final newerService = StatefulService(id: 'versioned-v3')..state = 'v3';
      registry.replace<StatefulService>('service', newerService);

      wrapper = registry.getByKey<StatefulService>('service')!;
      expect(wrapper.version, equals(2));
      expect(
        registry.getInstance<StatefulService>('service').state,
        equals('v3'),
      );
    });

    test('multiple registries maintain independent state', () {
      final registry1 = createTestRegistry<String>();
      final registry2 = createTestRegistry<String>();

      final service1 = StatefulService(id: 's1')..state = 'state-1';
      final service2 = StatefulService(id: 's2')..state = 'state-2';

      registry1.register<StatefulService>('service', service1);
      registry2.register<StatefulService>('service', service2);

      registry1.getInstance<StatefulService>('service').performAction();
      registry2.getInstance<StatefulService>('service').performAction();
      registry2.getInstance<StatefulService>('service').performAction();

      expect(
        registry1.getInstance<StatefulService>('service').actionCount,
        equals(1),
      );
      expect(
        registry2.getInstance<StatefulService>('service').actionCount,
        equals(2),
      );

      cleanupRegistry(registry1);
      cleanupRegistry(registry2);
    });

    test('destroyed flag persists after cleanup', () {
      final service = StatefulService(id: 'cleanup-test');
      registry
        ..register<StatefulService>('service', service)
        ..destroyAll();

      expect(service.destroyed, isTrue);

      final retrieved = service;
      expect(retrieved.destroyed, isTrue);
    });
  });
}
