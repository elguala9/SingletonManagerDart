import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

/// A stateful service for tracking state transitions
class StatefulService implements IValueForRegistry {
  StatefulService({required this.id});

  final String id;
  String _state = 'initialized';
  int _actionCount = 0;
  bool _destroyed = false;

  String get state => _state;
  int get actionCount => _actionCount;
  bool get destroyed => _destroyed;

  void setState(String newState) {
    _state = newState;
  }

  void performAction() {
    _actionCount++;
  }

  void reset() {
    _state = 'initialized';
    _actionCount = 0;
  }

  @override
  void destroy() {
    _destroyed = true;
  }
}

void main() {
  group('RegistryManager - State Management & Lifecycle', () {
    late RegistryManager<String, StatefulService> registry;

    setUp(() {
      registry = createTestRegistry();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    test('state persistence across multiple retrievals', () {
      final service = StatefulService(id: 'state-1');
      service.performAction();
      service.performAction();
      service.setState('active');

      registry.register('service', service);

      // Multiple retrievals should return same instance with same state
      expect(registry.getInstance('service').state, equals('active'));
      expect(registry.getInstance('service').actionCount, equals(2));
      expect(registry.getInstance('service').state, equals('active'));
      expect(registry.getInstance('service').actionCount, equals(2));
    });

    test('state mutation through retrieved reference', () {
      final service = StatefulService(id: 'mutable-1');
      registry.register('service', service);

      final retrieved = registry.getInstance('service');
      expect(retrieved.state, equals('initialized'));

      retrieved.setState('modified');
      expect(retrieved.state, equals('modified'));

      final retrieved2 = registry.getInstance('service');
      expect(retrieved2.state, equals('modified'));
      expect(identical(retrieved, retrieved2), isTrue);
    });

    test('state isolation between different services', () {
      final service1 = StatefulService(id: 'service-1');
      final service2 = StatefulService(id: 'service-2');

      service1.setState('state-1');
      service2.setState('state-2');

      registry.register('svc1', service1);
      registry.register('svc2', service2);

      expect(registry.getInstance('svc1').state, equals('state-1'));
      expect(registry.getInstance('svc2').state, equals('state-2'));

      // Mutate one
      registry.getInstance('svc1').setState('state-1-modified');

      expect(registry.getInstance('svc1').state, equals('state-1-modified'));
      expect(registry.getInstance('svc2').state, equals('state-2')); // Unchanged
    });

    test('lazy service initial state on first access', () {
      final expectedService = StatefulService(id: 'lazy-1');
      expectedService.setState('lazy-state');
      expectedService.performAction();

      registry.registerLazy('lazy', () => expectedService);

      final retrieved = registry.getInstance('lazy');

      expect(retrieved.state, equals('lazy-state'));
      expect(retrieved.actionCount, equals(1));
    });

    test('state changes reflected after replacement', () {
      final oldService = StatefulService(id: 'old');
      oldService.setState('old-state');
      registry.register('service', oldService);

      final newService = StatefulService(id: 'new');
      newService.setState('new-state');
      newService.performAction();
      newService.performAction();

      registry.replace('service', newService);

      expect(oldService.destroyed, isTrue);

      final retrieved = registry.getInstance('service');
      expect(retrieved.id, equals('new'));
      expect(retrieved.state, equals('new-state'));
      expect(retrieved.actionCount, equals(2));
    });

    test('lifecycle: initialization -> mutation -> replacement', () {
      // Phase 1: Creation and initialization
      final service1 = StatefulService(id: 'v1');
      service1.setState('initialized');

      registry.register('service', service1);

      // Phase 2: Mutation
      final retrieved = registry.getInstance('service');
      retrieved.performAction();
      retrieved.performAction();
      retrieved.setState('active');

      expect(retrieved.actionCount, equals(2));
      expect(retrieved.state, equals('active'));

      // Phase 3: Replacement
      final service2 = StatefulService(id: 'v2');
      service2.setState('ready');

      registry.replace('service', service2);

      expect(service1.destroyed, isTrue);
      expect(registry.getInstance('service').id, equals('v2'));
      expect(registry.getInstance('service').state, equals('ready'));
    });

    test('stateful registry with multiple dependent services', () {
      final dbService = StatefulService(id: 'database');
      final cacheService = StatefulService(id: 'cache');
      final apiService = StatefulService(id: 'api');

      dbService.setState('connected');
      cacheService.setState('ready');
      apiService.setState('listening');

      registry.register('db', dbService);
      registry.register('cache', cacheService);
      registry.register('api', apiService);

      // Simulate operations
      registry.getInstance('db').performAction();
      registry.getInstance('cache').performAction();
      registry.getInstance('api').performAction();

      registry.getInstance('db').performAction();
      registry.getInstance('api').performAction();

      expect(registry.getInstance('db').actionCount, equals(2));
      expect(registry.getInstance('cache').actionCount, equals(1));
      expect(registry.getInstance('api').actionCount, equals(2));
    });

    test('state reset pattern', () {
      final service = StatefulService(id: 'resettable');
      service.performAction();
      service.performAction();
      service.setState('modified');

      registry.register('service', service);

      expect(registry.getInstance('service').actionCount, equals(2));
      expect(registry.getInstance('service').state, equals('modified'));

      // Reset state
      registry.getInstance('service').reset();

      expect(registry.getInstance('service').actionCount, equals(0));
      expect(registry.getInstance('service').state, equals('initialized'));
    });

    test('state tracking across unregister and re-register', () {
      final service = StatefulService(id: 'trackable');
      service.performAction();
      service.setState('tracked');

      registry.register('service', service);
      expect(registry.getInstance('service').actionCount, equals(1));

      // Unregister (state still in service object)
      registry.unregister('service');
      expect(service.actionCount, equals(1)); // Still there

      // Re-register same instance
      registry.register('service', service);
      expect(registry.getInstance('service').actionCount, equals(1)); // Still there
    });

    test('cleanup preserves state until destroy', () {
      final service = StatefulService(id: 'cleanup-test');
      service.performAction();
      service.setState('operational');

      registry.register('service', service);

      // Clear registry
      registry.clearRegistry();

      // Service is still in our reference
      expect(service.actionCount, equals(1));
      expect(service.state, equals('operational'));
      expect(service.destroyed, isFalse);

      // Now destroy
      service.destroy();
      expect(service.destroyed, isTrue);
    });

    test('concurrent state access through multiple references', () {
      final service = StatefulService(id: 'concurrent');
      registry.register('service', service);

      final ref1 = registry.getInstance('service');
      final ref2 = registry.getInstance('service');
      final ref3 = registry.getInstance('service');

      expect(identical(ref1, ref2), isTrue);
      expect(identical(ref2, ref3), isTrue);

      // All see same state
      expect(ref1.state, equals(ref2.state));
      expect(ref2.state, equals(ref3.state));

      // Mutation visible to all
      ref1.setState('modified');
      expect(ref2.state, equals('modified'));
      expect(ref3.state, equals('modified'));
    });

    test('state machine pattern in registry', () {
      final service = StatefulService(id: 'state-machine');
      registry.register('service', service);

      expect(registry.getInstance('service').state, equals('initialized'));

      // Transition 1
      registry.getInstance('service').setState('starting');
      expect(registry.getInstance('service').state, equals('starting'));

      // Transition 2
      registry.getInstance('service').setState('running');
      expect(registry.getInstance('service').state, equals('running'));

      // Transition 3
      registry.getInstance('service').setState('stopping');
      expect(registry.getInstance('service').state, equals('stopping'));

      // Transition 4
      registry.getInstance('service').setState('stopped');
      expect(registry.getInstance('service').state, equals('stopped'));
    });

    test('state versioning through version wrapper', () {
      final service = StatefulService(id: 'versioned');
      service.setState('v1');
      registry.register('service', service);

      var wrapper = registry.getByKey('service')!;
      expect(wrapper.version, equals(0));
      expect(registry.getInstance('service').state, equals('v1'));

      // Replace (version increments)
      final newService = StatefulService(id: 'versioned-v2');
      newService.setState('v2');
      registry.replace('service', newService);

      wrapper = registry.getByKey('service')!;
      expect(wrapper.version, equals(1));
      expect(registry.getInstance('service').state, equals('v2'));

      // Replace again
      final newerService = StatefulService(id: 'versioned-v3');
      newerService.setState('v3');
      registry.replace('service', newerService);

      wrapper = registry.getByKey('service')!;
      expect(wrapper.version, equals(2));
      expect(registry.getInstance('service').state, equals('v3'));
    });

    test('multiple registries maintain independent state', () {
      final registry1 = createTestRegistry<String, StatefulService>();
      final registry2 = createTestRegistry<String, StatefulService>();

      final service1 = StatefulService(id: 's1');
      final service2 = StatefulService(id: 's2');

      service1.setState('state-1');
      service2.setState('state-2');

      registry1.register('service', service1);
      registry2.register('service', service2);

      registry1.getInstance('service').performAction();
      registry2.getInstance('service').performAction();
      registry2.getInstance('service').performAction();

      expect(registry1.getInstance('service').actionCount, equals(1));
      expect(registry2.getInstance('service').actionCount, equals(2));

      cleanupRegistry(registry1);
      cleanupRegistry(registry2);
    });

    test('destroyed flag persists after cleanup', () {
      final service = StatefulService(id: 'cleanup-test');
      registry.register('service', service);

      registry.destroyAll();

      expect(service.destroyed, isTrue);

      // Even though removed from registry, object remembers it was destroyed
      final retrieved = service;
      expect(retrieved.destroyed, isTrue);
    });
  });
}
