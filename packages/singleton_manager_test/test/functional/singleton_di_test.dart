import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager/src/singleton/singleton_di_access.dart';
import 'package:test/test.dart';

// Test fixtures
class SimpleService {
  SimpleService({this.name = 'SimpleService'});

  final String name;

  @override
  String toString() => 'SimpleService($name)';
}

class ServiceWithInit implements ISingleton<void, void> {
  ServiceWithInit({this.name = 'ServiceWithInit'});

  final String name;
  bool initialized = false;

  @override
  Future<void> initialize(void input) async {
    // Not used in this test
  }

  @override
  Future<void> initializeDI() async {
    initialized = true;
    await Future.delayed(const Duration(milliseconds: 10));
  }

  @override
  String toString() => 'ServiceWithInit($name, initialized=$initialized)';
}

class HeavyService {
  HeavyService({this.name = 'HeavyService', SimpleService? dependency}) {
    this.dependency = dependency ?? SimpleService(name: 'default-dep');
  }

  final String name;
  late SimpleService dependency;

  @override
  String toString() => 'HeavyService($name)';
}

// Interface for testing addAs
abstract class IRepository {
  String getName();
}

class RepositoryImpl implements IRepository {
  RepositoryImpl({this.name = 'RepositoryImpl'});

  final String name;

  @override
  String getName() => name;
}

class DestroyableService implements IValueForRegistry {
  DestroyableService({this.name = 'DestroyableService'});

  final String name;
  bool destroyed = false;

  @override
  void destroy() {
    destroyed = true;
  }
}

class RepositoryWithInit implements IRepository, ISingleton<void, void> {
  RepositoryWithInit({this.name = 'RepositoryWithInit'});

  final String name;
  bool initialized = false;

  @override
  String getName() => name;

  @override
  Future<void> initialize(void input) async {
    // Not used in this test
  }

  @override
  Future<void> initializeDI() async {
    initialized = true;
    await Future.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('SingletonDI - Factory Registration', () {
    setUp(SingletonDI.clearFactories);

    test('registerFactory() stores factory for type T', () {
      expect(SingletonDI.factoryCount, equals(0));

      SingletonDI.registerFactory<SimpleService>(SimpleService.new);

      expect(SingletonDI.factoryCount, equals(1));
    });

    test('registerFactory() allows multiple factories', () {
      SingletonDI.registerFactory<SimpleService>(SimpleService.new);
      SingletonDI.registerFactory<HeavyService>(HeavyService.new);
      SingletonDI.registerFactory<ServiceWithInit>(
        ServiceWithInit.new,
      );

      expect(SingletonDI.factoryCount, equals(3));
    });

    test('registerFactory() overwrites previous factory for same type', () {
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'first'),
      );
      expect(SingletonDI.factoryCount, equals(1));

      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'second'),
      );
      expect(SingletonDI.factoryCount, equals(1));
    });

    test('clearFactories() removes all registered factories', () {
      SingletonDI.registerFactory<SimpleService>(SimpleService.new);
      SingletonDI.registerFactory<HeavyService>(HeavyService.new);
      expect(SingletonDI.factoryCount, equals(2));

      SingletonDI.clearFactories();

      expect(SingletonDI.factoryCount, equals(0));
    });

    test('factoryCount getter returns correct count', () {
      expect(SingletonDI.factoryCount, equals(0));

      SingletonDI.registerFactory<SimpleService>(SimpleService.new);
      expect(SingletonDI.factoryCount, equals(1));

      SingletonDI.registerFactory<HeavyService>(HeavyService.new);
      expect(SingletonDI.factoryCount, equals(2));

      SingletonDI.registerFactory<ServiceWithInit>(
        ServiceWithInit.new,
      );
      expect(SingletonDI.factoryCount, equals(3));
    });
  });

  group('SingletonDIExt - add<T>()', () {
    setUp(() {
      SingletonDI.clearFactories();
      SingletonManager().clearRegistry();
    });

    tearDown(() {
      SingletonManager().clearRegistry();
    });

    test('add<T>() creates instance from registered factory', () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'registered'),
      );

      await manager.add<SimpleService>();

      final instance = manager.get<SimpleService>();
      expect(instance.name, equals('registered'));
    });

    test('add<T>() throws StateError if factory not registered', () async {
      final manager = SingletonManager();
      await expectLater(
        manager.add<SimpleService>(),
        throwsA(isA<StateError>()),
      );
    });

    test('add<T>() calls initializeDI() if instance implements ISingleton',
        () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<ServiceWithInit>(
        () => ServiceWithInit(name: 'with-init'),
      );

      await manager.add<ServiceWithInit>();

      final instance = manager.get<ServiceWithInit>();
      expect(instance.initialized, isTrue);
    });

    test('add<T>() does not fail for non-ISingleton classes', () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<SimpleService>(
        SimpleService.new,
      );

      await manager.add<SimpleService>();

      // Verify it was registered
      final instance = manager.get<SimpleService>();
      expect(instance, isNotNull);
    });

    test('add<T>() raises error with helpful message when factory missing',
        () async {
      final manager = SingletonManager();
      await expectLater(
        manager.add<SimpleService>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.toString(),
            'message',
            contains('No factory registered for type'),
          ),
        ),
      );
    });

    test('add<T>() registers singleton and can be retrieved',
        () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'first-add'),
      );

      await manager.add<SimpleService>();
      final first = manager.get<SimpleService>();

      expect(first.name, equals('first-add'));
      expect(manager.get<SimpleService>(), same(first));
    });

    test('add<T>() maintains singleton property', () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<SimpleService>(
        SimpleService.new,
      );

      await manager.add<SimpleService>();
      final first = manager.get<SimpleService>();
      final second = manager.get<SimpleService>();

      expect(identical(first, second), isTrue);
    });
  });

  group('SingletonDIExt - addAs<I, T>()', () {
    setUp(() {
      SingletonDI.clearFactories();
      SingletonManager().clearRegistry();
    });

    tearDown(() {
      SingletonManager().clearRegistry();
    });

    test('addAs<I, T>() registers T by interface I', () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<RepositoryImpl>(
        () => RepositoryImpl(name: 'impl-1'),
      );

      await manager.addAs<IRepository, RepositoryImpl>();

      final instance = manager.get<IRepository>();
      expect(instance.getName(), equals('impl-1'));
    });

    test('addAs<I, T>() throws StateError if factory not registered',
        () async {
      final manager = SingletonManager();
      await expectLater(
        manager.addAs<IRepository, RepositoryImpl>(),
        throwsA(isA<StateError>()),
      );
    });

    test('addAs<I, T>() calls initializeDI() if T implements ISingleton',
        () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<RepositoryWithInit>(
        () => RepositoryWithInit(name: 'with-init'),
      );

      await manager.addAs<IRepository, RepositoryWithInit>();

      final instance = manager.get<IRepository>();
      expect((instance as RepositoryWithInit).initialized, isTrue);
    });

    test('addAs<I, T>() can replace previous interface registration',
        () async {
      final manager = SingletonManager();
      final repo1 = RepositoryImpl(name: 'first');
      final repo2 = RepositoryImpl(name: 'second');

      manager.register<IRepository>(repo1);
      expect(manager.get<IRepository>().getName(), equals('first'));

      SingletonDI.registerFactory<RepositoryImpl>(() => repo2);
      await manager.addAs<IRepository, RepositoryImpl>();

      expect(manager.get<IRepository>().getName(), equals('second'));
    });

    test('addAs<I, T>() unregisters previous before registering new',
        () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<RepositoryImpl>(
        () => RepositoryImpl(name: 'updated'),
      );

      // Register first time manually
      final initial = RepositoryImpl(name: 'initial');
      manager.register<IRepository>(initial);

      // Then use addAs to update
      await manager.addAs<IRepository, RepositoryImpl>();

      expect(manager.get<IRepository>().getName(), equals('updated'));
    });
  });

  group('SingletonDI & SingletonDIExt - Integration', () {
    setUp(() {
      SingletonDI.clearFactories();
      SingletonManager().clearRegistry();
    });

    tearDown(() {
      SingletonManager().clearRegistry();
    });

    test('complete setup: register factories and add singletons', () async {
      final manager = SingletonManager();

      // Setup phase
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'main-service'),
      );
      SingletonDI.registerFactory<HeavyService>(
        () => HeavyService(name: 'main-heavy'),
      );
      SingletonDI.registerFactory<RepositoryImpl>(
        () => RepositoryImpl(name: 'main-repo'),
      );

      expect(SingletonDI.factoryCount, equals(3));

      // Initialize phase
      await manager.add<SimpleService>();
      await manager.add<HeavyService>();
      await manager.addAs<IRepository, RepositoryImpl>();

      // Verify phase
      final service = manager.get<SimpleService>();
      expect(service.name, equals('main-service'));

      final heavy = manager.get<HeavyService>();
      expect(heavy.name, equals('main-heavy'));

      final repo = manager.get<IRepository>();
      expect(repo.getName(), equals('main-repo'));
    });

    test('register factories and verify singleton behavior', () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'singleton-test'),
      );

      await manager.add<SimpleService>();

      final first = manager.get<SimpleService>();
      final second = manager.get<SimpleService>();

      expect(identical(first, second), isTrue);
    });

    test('mixed ISingleton and regular classes', () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'simple'),
      );
      SingletonDI.registerFactory<ServiceWithInit>(
        () => ServiceWithInit(name: 'with-init'),
      );

      await manager.add<SimpleService>();
      await manager.add<ServiceWithInit>();

      final simple = manager.get<SimpleService>();
      final withInit = manager.get<ServiceWithInit>();

      expect(simple.name, equals('simple'));
      expect(withInit.initialized, isTrue);
    });

    test('factory can be updated for subsequent use', () async {
      // First setup
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'v1'),
      );

      final manager1 = SingletonManager();
      await manager1.add<SimpleService>();
      expect(manager1.get<SimpleService>().name, equals('v1'));

      // Update factory and create new manager
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'v2'),
      );

      manager1.clearRegistry();
      await manager1.add<SimpleService>();
      expect(manager1.get<SimpleService>().name, equals('v2'));
    });

    test('error handling: missing factory shows helpful error', () async {
      final manager = SingletonManager();
      await expectLater(
        manager.add<SimpleService>(),
        throwsA(
          isA<StateError>().having(
            (e) => e.toString(),
            'message',
            allOf([
              contains('No factory registered'),
              contains('SimpleService'),
              contains('registerFactory'),
            ]),
          ),
        ),
      );
    });
  });

  group('SingletonDIExt - remove<T>()', () {
    setUp(() {
      SingletonDI.clearFactories();
      SingletonManager().clearRegistry();
    });

    tearDown(() {
      SingletonManager().clearRegistry();
    });

    test('remove<T>() unregisters instance from manager', () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'to-remove'),
      );

      await manager.add<SimpleService>();
      expect(manager.get<SimpleService>().name, equals('to-remove'));

      manager.remove<SimpleService>();

      expect(
        () => manager.get<SimpleService>(),
        throwsA(isA<StateError>()),
      );
    });

    test('remove<T>() calls destroy on IValueForRegistry instances', () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<DestroyableService>(
        () => DestroyableService(name: 'destroyable'),
      );

      await manager.add<DestroyableService>();
      final instance = manager.get<DestroyableService>();
      expect(instance.destroyed, isFalse);

      manager.remove<DestroyableService>();

      expect(instance.destroyed, isTrue);
    });

    test('remove<T>() does not fail for non-IValueForRegistry instances',
        () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'plain'),
      );

      await manager.add<SimpleService>();
      manager.remove<SimpleService>();

      expect(
        () => manager.get<SimpleService>(),
        throwsA(isA<StateError>()),
      );
    });

    test('remove<T>() does not fail when instance not registered', () {
      // Should not throw
      SingletonManager().remove<SimpleService>();
    });

    test('remove<T>() allows re-adding after removal', () async {
      final manager = SingletonManager();
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'v1'),
      );

      await manager.add<SimpleService>();
      expect(manager.get<SimpleService>().name, equals('v1'));

      manager.remove<SimpleService>();

      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'v2'),
      );
      await manager.add<SimpleService>();
      expect(manager.get<SimpleService>().name, equals('v2'));
    });
  });

  group('SingletonDI - Edge Cases', () {
    setUp(SingletonDI.clearFactories);

    test('factory can be registered multiple times (last wins)', () {
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'first'),
      );
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'second'),
      );

      expect(SingletonDI.factoryCount, equals(1));
    });

    test('clearFactories works correctly with empty registry', () {
      SingletonDI.clearFactories();
      expect(SingletonDI.factoryCount, equals(0));

      SingletonDI.clearFactories();
      expect(SingletonDI.factoryCount, equals(0));
    });

    test('generic factory types maintain type safety', () async {
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'test'),
      );

      final manager = SingletonManager();
      await manager.add<SimpleService>();

      final instance = manager.get<SimpleService>();
      expect(instance, isA<SimpleService>());
      expect(instance.name, equals('test'));
    });

    test('multiple factory registrations do not leak between managers',
        () async {
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'shared'),
      );

      // Both managers use the same factory registry
      final manager1 = SingletonManager();
      final manager2 = SingletonManager();

      // But SingletonManager is a singleton, so they're the same instance
      expect(identical(manager1, manager2), isTrue);
    });
  });

  group('SingletonDIAccess - Static Methods', () {
    setUp(() {
      SingletonDI.clearFactories();
      SingletonManager().clearRegistry();
    });

    tearDown(() {
      SingletonManager().clearRegistry();
    });

    test('add<T>() registers singleton via instance', () async {
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'static-add'),
      );

      await SingletonDIAccess.add<SimpleService>();

      final instance = SingletonDIAccess.get<SimpleService>();
      expect(instance.name, equals('static-add'));
    });

    test('add<T>() is equivalent to instance.add<T>()', () async {
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'equivalence-test'),
      );

      await SingletonDIAccess.add<SimpleService>();
      final staticInstance = SingletonDIAccess.get<SimpleService>();

      SingletonManager().clearRegistry();
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'equivalence-test'),
      );

      final manager = SingletonManager();
      await manager.add<SimpleService>();
      final instanceMethod = manager.get<SimpleService>();

      expect(staticInstance.name, equals(instanceMethod.name));
    });

    test('add<T>() calls initializeDI if instance implements ISingleton',
        () async {
      SingletonDI.registerFactory<ServiceWithInit>(
        () => ServiceWithInit(name: 'static-init'),
      );

      await SingletonDIAccess.add<ServiceWithInit>();

      final instance = SingletonDIAccess.get<ServiceWithInit>();
      expect(instance.initialized, isTrue);
    });

    test('add<T>() throws StateError if factory not registered',
        () async {
      await expectLater(
        SingletonDIAccess.add<SimpleService>(),
        throwsA(isA<StateError>()),
      );
    });

    test('addAs<I, T>() registers by interface via instance', () async {
      SingletonDI.registerFactory<RepositoryImpl>(
        () => RepositoryImpl(name: 'static-impl'),
      );

      await SingletonDIAccess.addAs<IRepository, RepositoryImpl>();

      final instance = SingletonDIAccess.get<IRepository>();
      expect(instance.getName(), equals('static-impl'));
    });

    test('addAs<I, T>() is equivalent to instance.addAs<I, T>()',
        () async {
      SingletonDI.registerFactory<RepositoryImpl>(
        () => RepositoryImpl(name: 'addas-test'),
      );

      await SingletonDIAccess.addAs<IRepository, RepositoryImpl>();
      final staticInstance = SingletonDIAccess.get<IRepository>();

      SingletonManager().clearRegistry();
      SingletonDI.registerFactory<RepositoryImpl>(
        () => RepositoryImpl(name: 'addas-test'),
      );

      final manager = SingletonManager();
      await manager.addAs<IRepository, RepositoryImpl>();
      final instanceMethod = manager.get<IRepository>();

      expect(staticInstance.getName(), equals(instanceMethod.getName()));
    });

    test('addAs<I, T>() calls initializeDI if T implements ISingleton',
        () async {
      SingletonDI.registerFactory<RepositoryWithInit>(
        () => RepositoryWithInit(name: 'static-with-init'),
      );

      await SingletonDIAccess.addAs<IRepository, RepositoryWithInit>();

      final instance = SingletonDIAccess.get<IRepository>();
      expect((instance as RepositoryWithInit).initialized, isTrue);
    });

    test('addAs<I, T>() throws StateError if factory not registered',
        () async {
      await expectLater(
        SingletonDIAccess.addAs<IRepository, RepositoryImpl>(),
        throwsA(isA<StateError>()),
      );
    });

    test('get<T>() retrieves registered singleton', () async {
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'get-test'),
      );

      await SingletonDIAccess.add<SimpleService>();

      final instance = SingletonDIAccess.get<SimpleService>();
      expect(instance.name, equals('get-test'));
    });

    test('get<T>() is equivalent to instance.get<T>()', () async {
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'get-equiv'),
      );

      await SingletonDIAccess.add<SimpleService>();
      final staticResult = SingletonDIAccess.get<SimpleService>();

      final manager = SingletonManager();
      final instanceResult = manager.get<SimpleService>();

      expect(identical(staticResult, instanceResult), isTrue);
    });

    test('get<T>() throws StateError if not found', () {
      expect(
        () => SingletonDIAccess.get<SimpleService>(),
        throwsA(isA<StateError>()),
      );
    });

    test('remove<T>() removes singleton via instance', () async {
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'to-remove'),
      );

      await SingletonDIAccess.add<SimpleService>();
      SingletonDIAccess.remove<SimpleService>();

      expect(
        () => SingletonDIAccess.get<SimpleService>(),
        throwsA(isA<StateError>()),
      );
    });

    test('remove<T>() is equivalent to instance.remove<T>()',
        () async {
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'remove-equiv'),
      );

      await SingletonDIAccess.add<SimpleService>();
      SingletonDIAccess.remove<SimpleService>();

      // Verify it's removed
      expect(
        () => SingletonDIAccess.get<SimpleService>(),
        throwsA(isA<StateError>()),
      );

      // Verify instance method would do the same
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'remove-equiv'),
      );
      final manager = SingletonManager();
      await manager.add<SimpleService>();
      manager.remove<SimpleService>();

      expect(
        () => manager.get<SimpleService>(),
        throwsA(isA<StateError>()),
      );
    });

    test('remove<T>() calls destroy on IValueForRegistry instances',
        () async {
      SingletonDI.registerFactory<DestroyableService>(
        () => DestroyableService(name: 'destroyable'),
      );

      await SingletonDIAccess.add<DestroyableService>();
      final instance = SingletonDIAccess.get<DestroyableService>();
      expect(instance.destroyed, isFalse);

      SingletonDIAccess.remove<DestroyableService>();

      expect(instance.destroyed, isTrue);
    });

    test('remove<T>() does not fail when instance not registered', () {
      // Should not throw
      SingletonDIAccess.remove<SimpleService>();
    });

    test('complete workflow using static methods', () async {
      // Setup
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'workflow-service'),
      );
      SingletonDI.registerFactory<RepositoryImpl>(
        () => RepositoryImpl(name: 'workflow-repo'),
      );

      // Register
      await SingletonDIAccess.add<SimpleService>();
      await SingletonDIAccess.addAs<IRepository, RepositoryImpl>();

      // Retrieve
      final service = SingletonDIAccess.get<SimpleService>();
      final repo = SingletonDIAccess.get<IRepository>();

      expect(service.name, equals('workflow-service'));
      expect(repo.getName(), equals('workflow-repo'));

      // Remove
      SingletonDIAccess.remove<SimpleService>();
      SingletonDIAccess.remove<IRepository>();

      expect(
        () => SingletonDIAccess.get<SimpleService>(),
        throwsA(isA<StateError>()),
      );
      expect(
        () => SingletonDIAccess.get<IRepository>(),
        throwsA(isA<StateError>()),
      );
    });

    test('static methods use singleton manager instance', () async {
      SingletonDI.registerFactory<SimpleService>(
        () => SimpleService(name: 'singleton-test'),
      );

      await SingletonDIAccess.add<SimpleService>();

      // Both static method and instance method should access same singleton
      final staticInstance = SingletonDIAccess.get<SimpleService>();
      final manager = SingletonManager();
      final managerInstance = manager.get<SimpleService>();

      expect(identical(staticInstance, managerInstance), isTrue);
    });
  });
}
