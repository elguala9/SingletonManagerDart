import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

class ServiceA implements IValueForRegistry {
  ServiceA({this.name = 'ServiceA'});
  final String name;
  bool _destroyed = false;
  bool get destroyed => _destroyed;

  @override
  void destroy() => _destroyed = true;
}

class ServiceB implements IValueForRegistry {
  ServiceB({this.name = 'ServiceB'});
  final String name;
  bool _destroyed = false;
  bool get destroyed => _destroyed;

  @override
  void destroy() => _destroyed = true;
}

void main() {
  group('RegistryAccess - Static Facade', () {
    tearDown(RegistryAccess.destroyAll);

    // ── instance ──────────────────────────────────────────────────────────
    group('instance', () {
      test('returns the RegistryManagerSingleton instance', () {
        expect(RegistryAccess.instance, same(RegistryManagerSingleton.instance));
      });

      test('returns the same IRegistry<String> on repeated calls', () {
        expect(identical(RegistryAccess.instance, RegistryAccess.instance), isTrue);
      });
    });

    // ── register / getInstance ────────────────────────────────────────────
    group('register and getInstance', () {
      test('register then getInstance returns same instance', () {
        final svc = ServiceA(name: 'prod');
        RegistryAccess.register<ServiceA>('prod', svc);
        expect(RegistryAccess.getInstance<ServiceA>('prod'), same(svc));
      });

      test('same key, different types are independent', () {
        final a = ServiceA(name: 'shared-key');
        final b = ServiceB(name: 'shared-key');

        RegistryAccess.register<ServiceA>('env', a);
        RegistryAccess.register<ServiceB>('env', b);

        expect(RegistryAccess.getInstance<ServiceA>('env'), same(a));
        expect(RegistryAccess.getInstance<ServiceB>('env'), same(b));
      });

      test('same type, different keys are independent', () {
        final prod = ServiceA(name: 'prod');
        final dev = ServiceA(name: 'dev');

        RegistryAccess.register<ServiceA>('prod', prod);
        RegistryAccess.register<ServiceA>('dev', dev);

        expect(RegistryAccess.getInstance<ServiceA>('prod'), same(prod));
        expect(RegistryAccess.getInstance<ServiceA>('dev'), same(dev));
      });

      test('register throws DuplicateRegistrationError on duplicate', () {
        RegistryAccess.register<ServiceA>('k', ServiceA());
        expect(
          () => RegistryAccess.register<ServiceA>('k', ServiceA()),
          throwsA(isA<DuplicateRegistrationError>()),
        );
      });

      test('getInstance throws RegistryNotFoundError for missing pair', () {
        expect(
          () => RegistryAccess.getInstance<ServiceA>('missing'),
          throwsA(isA<RegistryNotFoundError>()),
        );
      });
    });

    // ── registerLazy ─────────────────────────────────────────────────────
    group('registerLazy', () {
      test('factory is not called until getInstance', () {
        var called = false;
        RegistryAccess.registerLazy<ServiceA>('lazy', () {
          called = true;
          return ServiceA();
        });

        expect(called, isFalse);
        RegistryAccess.getInstance<ServiceA>('lazy');
        expect(called, isTrue);
      });

      test('factory is cached after first call', () {
        var callCount = 0;
        RegistryAccess.registerLazy<ServiceB>('cached', () {
          callCount++;
          return ServiceB();
        });

        RegistryAccess.getInstance<ServiceB>('cached');
        RegistryAccess.getInstance<ServiceB>('cached');
        RegistryAccess.getInstance<ServiceB>('cached');

        expect(callCount, equals(1));
      });

      test('contains returns true for lazy entry before resolution', () {
        RegistryAccess.registerLazy<ServiceA>('pre-resolve', ServiceA.new);
        expect(RegistryAccess.contains<ServiceA>('pre-resolve'), isTrue);
      });
    });

    // ── replace / replaceLazy ─────────────────────────────────────────────
    group('replace and replaceLazy', () {
      test('replace swaps value and destroys the old one', () {
        final old = ServiceA(name: 'old');
        RegistryAccess.register<ServiceA>('k', old);

        final fresh = ServiceA(name: 'new');
        RegistryAccess.replace<ServiceA>('k', fresh);

        expect(old.destroyed, isTrue);
        expect(RegistryAccess.getInstance<ServiceA>('k'), same(fresh));
      });

      test('replace throws RegistryNotFoundError for nonexistent key', () {
        expect(
          () => RegistryAccess.replace<ServiceA>('nope', ServiceA()),
          throwsA(isA<RegistryNotFoundError>()),
        );
      });

      test('replaceLazy swaps factory', () {
        RegistryAccess.register<ServiceA>('k', ServiceA(name: 'v1'));
        RegistryAccess.replaceLazy<ServiceA>('k', () => ServiceA(name: 'lazy-v2'));
        expect(RegistryAccess.getInstance<ServiceA>('k').name, equals('lazy-v2'));
      });

      test('replaceLazy throws RegistryNotFoundError for nonexistent key', () {
        expect(
          () => RegistryAccess.replaceLazy<ServiceA>('nope', ServiceA.new),
          throwsA(isA<RegistryNotFoundError>()),
        );
      });
    });

    // ── contains / unregister ─────────────────────────────────────────────
    group('contains and unregister', () {
      test('contains returns true only for registered (T, key)', () {
        RegistryAccess.register<ServiceA>('present', ServiceA());

        expect(RegistryAccess.contains<ServiceA>('present'), isTrue);
        expect(RegistryAccess.contains<ServiceA>('absent'), isFalse);
        expect(RegistryAccess.contains<ServiceB>('present'), isFalse);
      });

      test('unregister removes only the matching (T, key)', () {
        RegistryAccess.register<ServiceA>('k', ServiceA());
        RegistryAccess.register<ServiceB>('k', ServiceB());

        RegistryAccess.unregister<ServiceA>('k');

        expect(RegistryAccess.contains<ServiceA>('k'), isFalse);
        expect(RegistryAccess.contains<ServiceB>('k'), isTrue);
      });

      test('unregister returns ValueWithVersion for existing entry', () {
        RegistryAccess.register<ServiceA>('k', ServiceA());
        final removed = RegistryAccess.unregister<ServiceA>('k');
        expect(removed, isNotNull);
        expect(removed!.version, equals(0));
      });

      test('unregister returns null for non-existent key', () {
        expect(RegistryAccess.unregister<ServiceA>('ghost'), isNull);
      });
    });

    // ── clearRegistry / destroyAll ────────────────────────────────────────
    group('clearRegistry and destroyAll', () {
      test('destroyAll destroys all entries and empties the registry', () {
        final a = ServiceA();
        final b = ServiceB();

        RegistryAccess.register<ServiceA>('k', a);
        RegistryAccess.register<ServiceB>('k', b);

        RegistryAccess.destroyAll();

        expect(a.destroyed, isTrue);
        expect(b.destroyed, isTrue);
        expect(RegistryAccess.instance.isEmpty, isTrue);
      });

      test('clearRegistry does not call destroy', () {
        final svc = ServiceA();
        RegistryAccess.register<ServiceA>('k', svc);

        RegistryAccess.clearRegistry();

        expect(svc.destroyed, isFalse);
        expect(RegistryAccess.instance.isEmpty, isTrue);
      });
    });

    // ── instance properties ───────────────────────────────────────────────
    group('instance properties', () {
      test('isEmpty true when nothing registered', () {
        expect(RegistryAccess.instance.isEmpty, isTrue);
      });

      test('isEmpty false and isNotEmpty true after register', () {
        RegistryAccess.register<ServiceA>('k', ServiceA());
        expect(RegistryAccess.instance.isEmpty, isFalse);
        expect(RegistryAccess.instance.isNotEmpty, isTrue);
      });

      test('registrySize counts each (Type, key) independently', () {
        expect(RegistryAccess.instance.registrySize, equals(0));
        RegistryAccess.register<ServiceA>('prod', ServiceA());
        expect(RegistryAccess.instance.registrySize, equals(1));
        RegistryAccess.register<ServiceB>('prod', ServiceB());
        expect(RegistryAccess.instance.registrySize, equals(2));
      });

      test('keys returns compound (Type, String) records', () {
        RegistryAccess.register<ServiceA>('prod', ServiceA());
        RegistryAccess.register<ServiceB>('dev', ServiceB());
        final k = RegistryAccess.instance.keys;
        expect(k, hasLength(2));
        expect(k, contains((ServiceA, 'prod')));
        expect(k, contains((ServiceB, 'dev')));
      });

      test('getByKey returns null for missing entry', () {
        expect(RegistryAccess.instance.getByKey<ServiceA>('ghost'), isNull);
      });

      test('getByKey returns container for registered eager entry', () {
        RegistryAccess.register<ServiceA>('k', ServiceA());
        final entry = RegistryAccess.instance.getByKey<ServiceA>('k');
        expect(entry, isNotNull);
        expect(entry!.version, equals(0));
      });

      test('getByKey does not resolve lazy factory', () {
        var called = false;
        RegistryAccess.registerLazy<ServiceA>('lazy', () {
          called = true;
          return ServiceA();
        });
        RegistryAccess.instance.getByKey<ServiceA>('lazy');
        expect(called, isFalse);
      });
    });
  });
}
