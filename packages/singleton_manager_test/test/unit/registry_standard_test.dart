import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

// ── Extra fixture types ────────────────────────────────────────────────────────

class AlphaService implements IValueForRegistry {
  AlphaService({this.name = 'Alpha'});
  final String name;
  bool _destroyed = false;
  bool get destroyed => _destroyed;
  @override
  void destroy() => _destroyed = true;
}

class BetaService implements IValueForRegistry {
  BetaService({this.name = 'Beta'});
  final String name;
  bool _destroyed = false;
  bool get destroyed => _destroyed;
  @override
  void destroy() => _destroyed = true;
}

class GammaService implements IValueForRegistry {
  GammaService({this.name = 'Gamma'});
  final String name;
  bool _destroyed = false;
  bool get destroyed => _destroyed;
  @override
  void destroy() => _destroyed = true;
}

// ── Helpers ────────────────────────────────────────────────────────────────────

RegistryManager fresh() => RegistryManager();

void main() {
  // ── Type contract ──────────────────────────────────────────────────────────
  group('RegistryManager — type contract', () {
    test('is assignable to IRegistry<String>', () {
      final IRegistry<String> r = RegistryManager();
      expect(r, isA<IRegistry<String>>());
    });

    test('two instances are independent', () {
      final a = fresh()..register<AlphaService>('k', AlphaService());
      final b = fresh();
      expect(b.contains<AlphaService>('k'), isFalse);
      a.destroyAll();
    });
  });

  // ── register ───────────────────────────────────────────────────────────────
  group('register', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('adds value — contains returns true', () {
      r.register<AlphaService>('prod', AlphaService());
      expect(r.contains<AlphaService>('prod'), isTrue);
    });

    test('getInstance returns the exact registered instance', () {
      final svc = AlphaService(name: 'exact');
      r.register<AlphaService>('env', svc);
      expect(r.getInstance<AlphaService>('env'), same(svc));
    });

    test('duplicate (same T + same key) throws DuplicateRegistrationError', () {
      r.register<AlphaService>('k', AlphaService());
      expect(
        () => r.register<AlphaService>('k', AlphaService()),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('same key, different type — no collision', () {
      r.register<AlphaService>('k', AlphaService());
      expect(() => r.register<BetaService>('k', BetaService()), returnsNormally);
      expect(r.registrySize, equals(2));
    });

    test('same type, different keys — both exist', () {
      r
        ..register<AlphaService>('prod', AlphaService(name: 'p'))
        ..register<AlphaService>('dev', AlphaService(name: 'd'));
      expect(r.registrySize, equals(2));
      expect(r.getInstance<AlphaService>('prod').name, equals('p'));
      expect(r.getInstance<AlphaService>('dev').name, equals('d'));
    });

    test('multiple types same key — all retrievable independently', () {
      final a = AlphaService();
      final b = BetaService();
      final g = GammaService();
      r
        ..register<AlphaService>('env', a)
        ..register<BetaService>('env', b)
        ..register<GammaService>('env', g);
      expect(r.getInstance<AlphaService>('env'), same(a));
      expect(r.getInstance<BetaService>('env'), same(b));
      expect(r.getInstance<GammaService>('env'), same(g));
    });
  });

  // ── registerLazy ───────────────────────────────────────────────────────────
  group('registerLazy', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('factory is NOT called at registration time', () {
      var called = false;
      r.registerLazy<AlphaService>('lazy', () {
        called = true;
        return AlphaService();
      });
      expect(called, isFalse);
    });

    test('factory IS called on first getInstance', () {
      var called = false;
      r
        ..registerLazy<AlphaService>('lazy', () {
          called = true;
          return AlphaService();
        })
        ..getInstance<AlphaService>('lazy');
      expect(called, isTrue);
    });

    test('factory called exactly once — result cached on repeated gets', () {
      var count = 0;
      r.registerLazy<AlphaService>('lazy', () {
        count++;
        return AlphaService();
      });
      final first = r.getInstance<AlphaService>('lazy');
      final second = r.getInstance<AlphaService>('lazy');
      final third = r.getInstance<AlphaService>('lazy');
      expect(count, equals(1));
      expect(identical(first, second), isTrue);
      expect(identical(second, third), isTrue);
    });

    test('duplicate lazy key throws DuplicateRegistrationError', () {
      r.registerLazy<AlphaService>('k', AlphaService.new);
      expect(
        () => r.registerLazy<AlphaService>('k', AlphaService.new),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('duplicate of eager-as-lazy throws DuplicateRegistrationError', () {
      r.register<AlphaService>('k', AlphaService());
      expect(
        () => r.registerLazy<AlphaService>('k', AlphaService.new),
        throwsA(isA<DuplicateRegistrationError>()),
      );
    });

    test('lazy + eager same key different type — both resolve correctly', () {
      final eager = BetaService(name: 'eager-beta');
      r
        ..register<BetaService>('env', eager)
        ..registerLazy<AlphaService>('env', () => AlphaService(name: 'lazy-alpha'));
      expect(r.getInstance<BetaService>('env'), same(eager));
      expect(r.getInstance<AlphaService>('env').name, equals('lazy-alpha'));
    });
  });

  // ── replace ────────────────────────────────────────────────────────────────
  group('replace', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('replace swaps the value', () {
      final v1 = AlphaService(name: 'v1');
      final v2 = AlphaService(name: 'v2');
      r
        ..register<AlphaService>('k', v1)
        ..replace<AlphaService>('k', v2);
      expect(r.getInstance<AlphaService>('k'), same(v2));
    });

    test('replace calls destroy on the old value', () {
      final old = AlphaService();
      r
        ..register<AlphaService>('k', old)
        ..replace<AlphaService>('k', AlphaService());
      expect(old.destroyed, isTrue);
    });

    test('replace increments version', () {
      r.register<AlphaService>('k', AlphaService());
      expect(r.getByKey<AlphaService>('k')!.version, equals(0));
      r.replace<AlphaService>('k', AlphaService());
      expect(r.getByKey<AlphaService>('k')!.version, equals(1));
      r.replace<AlphaService>('k', AlphaService());
      expect(r.getByKey<AlphaService>('k')!.version, equals(2));
    });

    test('replace on missing key throws RegistryNotFoundError', () {
      expect(
        () => r.replace<AlphaService>('missing', AlphaService()),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('replace on one type does not touch another type at same key', () {
      final beta = BetaService(name: 'untouched');
      r
        ..register<AlphaService>('k', AlphaService())
        ..register<BetaService>('k', beta)
        ..replace<AlphaService>('k', AlphaService(name: 'v2'));
      expect(r.getInstance<BetaService>('k'), same(beta));
      expect(beta.destroyed, isFalse);
    });
  });

  // ── replaceLazy ────────────────────────────────────────────────────────────
  group('replaceLazy', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('replaceLazy swaps factory — new factory used on next get', () {
      r
        ..register<AlphaService>('k', AlphaService(name: 'v1'))
        ..replaceLazy<AlphaService>('k', () => AlphaService(name: 'lazy-v2'));
      expect(r.getInstance<AlphaService>('k').name, equals('lazy-v2'));
    });

    test('replaceLazy calls destroy on the old eager value', () {
      final old = AlphaService();
      r
        ..register<AlphaService>('k', old)
        ..replaceLazy<AlphaService>('k', AlphaService.new);
      expect(old.destroyed, isTrue);
    });

    test('replaceLazy on missing key throws RegistryNotFoundError', () {
      expect(
        () => r.replaceLazy<AlphaService>('missing', AlphaService.new),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('replaceLazy increments version', () {
      r
        ..register<AlphaService>('k', AlphaService())
        ..replaceLazy<AlphaService>('k', AlphaService.new);
      expect(r.getByKey<AlphaService>('k')!.version, equals(1));
    });

    test('replaceLazy factory cached after first call', () {
      var count = 0;
      r
        ..register<AlphaService>('k', AlphaService())
        ..replaceLazy<AlphaService>('k', () {
          count++;
          return AlphaService();
        })
        ..getInstance<AlphaService>('k')
        ..getInstance<AlphaService>('k');
      expect(count, equals(1));
    });
  });

  // ── getInstance ────────────────────────────────────────────────────────────
  group('getInstance', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('throws RegistryNotFoundError for completely missing key', () {
      expect(
        () => r.getInstance<AlphaService>('ghost'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('throws RegistryNotFoundError for wrong type at existing key', () {
      r.register<BetaService>('k', BetaService());
      expect(
        () => r.getInstance<AlphaService>('k'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('resolves lazy on demand and returns correct instance', () {
      final svc = AlphaService(name: 'on-demand');
      r.registerLazy<AlphaService>('k', () => svc);
      expect(r.getInstance<AlphaService>('k'), same(svc));
    });

    test('returns same lazy instance across calls', () {
      r.registerLazy<AlphaService>('k', AlphaService.new);
      expect(
        identical(
          r.getInstance<AlphaService>('k'),
          r.getInstance<AlphaService>('k'),
        ),
        isTrue,
      );
    });
  });

  // ── unregister ─────────────────────────────────────────────────────────────
  group('unregister', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('removes the entry — contains returns false afterwards', () {
      r
        ..register<AlphaService>('k', AlphaService())
        ..unregister<AlphaService>('k');
      expect(r.contains<AlphaService>('k'), isFalse);
    });

    test('returns the removed ValueWithVersion', () {
      final svc = AlphaService();
      r.register<AlphaService>('k', svc);
      final removed = r.unregister<AlphaService>('k');
      expect(removed, isNotNull);
    });

    test('returns null for non-existent key', () {
      expect(r.unregister<AlphaService>('ghost'), isNull);
    });

    test('removes only the matching type — sibling type untouched', () {
      r
        ..register<AlphaService>('k', AlphaService())
        ..register<BetaService>('k', BetaService())
        ..unregister<AlphaService>('k');
      expect(r.contains<AlphaService>('k'), isFalse);
      expect(r.contains<BetaService>('k'), isTrue);
    });

    test('registrySize decrements after unregister', () {
      r.register<AlphaService>('k', AlphaService());
      expect(r.registrySize, equals(1));
      r.unregister<AlphaService>('k');
      expect(r.registrySize, equals(0));
    });

    test('getInstance throws after unregister', () {
      r
        ..register<AlphaService>('k', AlphaService())
        ..unregister<AlphaService>('k');
      expect(
        () => r.getInstance<AlphaService>('k'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('can re-register after unregister', () {
      r
        ..register<AlphaService>('k', AlphaService(name: 'v1'))
        ..unregister<AlphaService>('k');
      final v2 = AlphaService(name: 'v2');
      r.register<AlphaService>('k', v2);
      expect(r.getInstance<AlphaService>('k'), same(v2));
    });
  });

  // ── getByKey ───────────────────────────────────────────────────────────────
  group('getByKey', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('returns null for missing key', () {
      expect(r.getByKey<AlphaService>('ghost'), isNull);
    });

    test('returns container for existing eager entry', () {
      r.register<AlphaService>('k', AlphaService());
      expect(r.getByKey<AlphaService>('k'), isNotNull);
    });

    test('returns container without resolving lazy', () {
      var called = false;
      r
        ..registerLazy<AlphaService>('k', () {
          called = true;
          return AlphaService();
        })
        ..getByKey<AlphaService>('k');
      expect(called, isFalse);
    });

    test('version starts at 0 for fresh registration', () {
      r.register<AlphaService>('k', AlphaService());
      expect(r.getByKey<AlphaService>('k')!.version, equals(0));
    });

    test('versions are independent per (Type, key)', () {
      r
        ..register<AlphaService>('k', AlphaService())
        ..register<BetaService>('k', BetaService())
        ..replace<AlphaService>('k', AlphaService())
        ..replace<AlphaService>('k', AlphaService());
      expect(r.getByKey<AlphaService>('k')!.version, equals(2));
      expect(r.getByKey<BetaService>('k')!.version, equals(0));
    });
  });

  // ── contains ──────────────────────────────────────────────────────────────
  group('contains', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('false when registry is empty', () {
      expect(r.contains<AlphaService>('any'), isFalse);
    });

    test('true only for registered (T, key) pair', () {
      r.register<AlphaService>('prod', AlphaService());
      expect(r.contains<AlphaService>('prod'), isTrue);
      expect(r.contains<AlphaService>('dev'), isFalse);
      expect(r.contains<BetaService>('prod'), isFalse);
    });

    test('true for lazy entry even before first get', () {
      r.registerLazy<AlphaService>('k', AlphaService.new);
      expect(r.contains<AlphaService>('k'), isTrue);
    });

    test('false after unregister', () {
      r
        ..register<AlphaService>('k', AlphaService())
        ..unregister<AlphaService>('k');
      expect(r.contains<AlphaService>('k'), isFalse);
    });
  });

  // ── keys ──────────────────────────────────────────────────────────────────
  group('keys', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('empty when nothing registered', () {
      expect(r.keys, isEmpty);
    });

    test('contains compound (Type, String) records', () {
      r
        ..register<AlphaService>('prod', AlphaService())
        ..register<BetaService>('prod', BetaService())
        ..register<AlphaService>('dev', AlphaService());
      final k = r.keys;
      expect(k, hasLength(3));
      expect(k, contains((AlphaService, 'prod')));
      expect(k, contains((BetaService, 'prod')));
      expect(k, contains((AlphaService, 'dev')));
    });

    test('extractKeys helper returns only the String dimension', () {
      r
        ..register<AlphaService>('prod', AlphaService())
        ..register<BetaService>('staging', BetaService());
      expect(extractKeys(r.keys), containsAll(['prod', 'staging']));
    });

    test('shrinks after unregister', () {
      r
        ..register<AlphaService>('k', AlphaService())
        ..register<BetaService>('k', BetaService())
        ..unregister<AlphaService>('k');
      expect(r.keys, hasLength(1));
      expect(r.keys, contains((BetaService, 'k')));
    });
  });

  // ── isEmpty / isNotEmpty / registrySize ────────────────────────────────────
  group('isEmpty / isNotEmpty / registrySize', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('isEmpty true and isNotEmpty false on fresh instance', () {
      expect(r.isEmpty, isTrue);
      expect(r.isNotEmpty, isFalse);
    });

    test('isEmpty false and isNotEmpty true after first register', () {
      r.register<AlphaService>('k', AlphaService());
      expect(r.isEmpty, isFalse);
      expect(r.isNotEmpty, isTrue);
    });

    test('registrySize counts each (Type, key) entry independently', () {
      expect(r.registrySize, equals(0));
      r.register<AlphaService>('prod', AlphaService());
      expect(r.registrySize, equals(1));
      r.register<BetaService>('prod', BetaService());
      expect(r.registrySize, equals(2));
      r.register<AlphaService>('dev', AlphaService());
      expect(r.registrySize, equals(3));
    });

    test('registrySize drops to 0 after clearRegistry', () {
      r
        ..register<AlphaService>('k', AlphaService())
        ..register<BetaService>('k', BetaService())
        ..clearRegistry();
      expect(r.registrySize, equals(0));
      expect(r.isEmpty, isTrue);
    });
  });

  // ── clearRegistry ─────────────────────────────────────────────────────────
  group('clearRegistry', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('removes all entries', () {
      r
        ..register<AlphaService>('a', AlphaService())
        ..register<BetaService>('b', BetaService())
        ..clearRegistry();
      expect(r.isEmpty, isTrue);
    });

    test('does NOT call destroy on values', () {
      final svc = AlphaService();
      r
        ..register<AlphaService>('k', svc)
        ..clearRegistry();
      expect(svc.destroyed, isFalse);
    });

    test('getInstance throws after clearRegistry', () {
      r
        ..register<AlphaService>('k', AlphaService())
        ..clearRegistry();
      expect(
        () => r.getInstance<AlphaService>('k'),
        throwsA(isA<RegistryNotFoundError>()),
      );
    });

    test('can register again after clearRegistry', () {
      r
        ..register<AlphaService>('k', AlphaService(name: 'old'))
        ..clearRegistry();
      final fresh = AlphaService(name: 'new');
      r.register<AlphaService>('k', fresh);
      expect(r.getInstance<AlphaService>('k'), same(fresh));
    });
  });

  // ── destroyAll ────────────────────────────────────────────────────────────
  group('destroyAll', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.clearRegistry());

    test('calls destroy on all eager values', () {
      final a = AlphaService();
      final b = BetaService();
      r
        ..register<AlphaService>('k', a)
        ..register<BetaService>('k', b)
        ..destroyAll();
      expect(a.destroyed, isTrue);
      expect(b.destroyed, isTrue);
    });

    test('calls destroy on a resolved lazy value', () {
      final svc = AlphaService();
      r
        ..registerLazy<AlphaService>('k', () => svc)
        ..getInstance<AlphaService>('k') // resolve first
        ..destroyAll();
      expect(svc.destroyed, isTrue);
    });

    test('leaves registry empty', () {
      r
        ..register<AlphaService>('a', AlphaService())
        ..register<BetaService>('b', BetaService())
        ..destroyAll();
      expect(r.isEmpty, isTrue);
    });

    test('second destroyAll on empty registry does not throw', () {
      r
        ..register<AlphaService>('k', AlphaService())
        ..destroyAll();
      expect(() => r.destroyAll(), returnsNormally);
    });

    test('can register fresh values after destroyAll', () {
      r
        ..register<AlphaService>('k', AlphaService(name: 'old'))
        ..destroyAll();
      final next = AlphaService(name: 'next');
      r.register<AlphaService>('k', next);
      expect(r.getInstance<AlphaService>('k'), same(next));
    });

    test('does NOT call destroy on an unresolved lazy entry', () {
      var called = false;
      r.registerLazy<AlphaService>('unresolved', () {
        called = true;
        return AlphaService();
      });
      // destroyAll without ever calling getInstance — factory must not be invoked
      r.destroyAll();
      expect(called, isFalse);
    });
  });

  // ── compound key isolation ─────────────────────────────────────────────────
  group('compound key isolation', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('10 types at same key — all retrievable without collision', () {
      // use SimpleService + fixtures for 3 types, rest with Alpha/Beta/Gamma
      final services = <String, IValueForRegistry>{};

      final a = AlphaService(name: 'a');
      final b = BetaService(name: 'b');
      final g = GammaService(name: 'g');

      r
        ..register<AlphaService>('shared', a)
        ..register<BetaService>('shared', b)
        ..register<GammaService>('shared', g);

      services['alpha'] = r.getInstance<AlphaService>('shared');
      services['beta'] = r.getInstance<BetaService>('shared');
      services['gamma'] = r.getInstance<GammaService>('shared');

      expect(identical(services['alpha'], a), isTrue);
      expect(identical(services['beta'], b), isTrue);
      expect(identical(services['gamma'], g), isTrue);
    });

    test('replace on one type at shared key does not affect others', () {
      final b = BetaService(name: 'intact');
      final g = GammaService(name: 'intact');
      r
        ..register<AlphaService>('env', AlphaService())
        ..register<BetaService>('env', b)
        ..register<GammaService>('env', g)
        ..replace<AlphaService>('env', AlphaService(name: 'new-alpha'));
      expect(r.getInstance<BetaService>('env'), same(b));
      expect(r.getInstance<GammaService>('env'), same(g));
      expect(b.destroyed, isFalse);
      expect(g.destroyed, isFalse);
    });

    test('unregister one type leaves siblings intact', () {
      r
        ..register<AlphaService>('env', AlphaService())
        ..register<BetaService>('env', BetaService())
        ..register<GammaService>('env', GammaService())
        ..unregister<BetaService>('env');
      expect(r.contains<BetaService>('env'), isFalse);
      expect(r.contains<AlphaService>('env'), isTrue);
      expect(r.contains<GammaService>('env'), isTrue);
      expect(r.registrySize, equals(2));
    });
  });

  // ── RegistryManagerSingleton ───────────────────────────────────────────────
  group('RegistryManagerSingleton', () {
    tearDown(RegistryManagerSingleton.instance.clearRegistry);

    test('factory constructor returns the same instance every time', () {
      final a = RegistryManagerSingleton();
      final b = RegistryManagerSingleton();
      expect(identical(a, b), isTrue);
    });

    test('instance getter returns the same object as factory constructor', () {
      expect(identical(RegistryManagerSingleton(), RegistryManagerSingleton.instance), isTrue);
    });

    test('repeated calls to instance getter are identical', () {
      expect(
        identical(RegistryManagerSingleton.instance, RegistryManagerSingleton.instance),
        isTrue,
      );
    });

    test('is a RegistryManager', () {
      expect(RegistryManagerSingleton.instance, isA<RegistryManager>());
    });

    test('is an IRegistry<String>', () {
      expect(RegistryManagerSingleton.instance, isA<IRegistry<String>>());
    });

    test('is NOT the same object as a fresh RegistryManager()', () {
      expect(identical(RegistryManagerSingleton.instance, RegistryManager()), isFalse);
    });

    test('shared state — register via factory, retrieve via instance getter', () {
      final svc = AlphaService(name: 'shared');
      RegistryManagerSingleton().register<AlphaService>('env', svc);
      expect(RegistryManagerSingleton.instance.getInstance<AlphaService>('env'), same(svc));
    });

    test('shared state — register via instance getter, retrieve via factory', () {
      final svc = BetaService(name: 'also-shared');
      RegistryManagerSingleton.instance.register<BetaService>('env', svc);
      expect(RegistryManagerSingleton().getInstance<BetaService>('env'), same(svc));
    });

    test('clearRegistry empties the shared state', () {
      RegistryManagerSingleton.instance.register<AlphaService>('k', AlphaService());
      RegistryManagerSingleton.instance.clearRegistry();
      expect(RegistryManagerSingleton.instance.isEmpty, isTrue);
    });

    test('destroyAll calls destroy on all values and empties the registry', () {
      final svc = AlphaService();
      RegistryManagerSingleton.instance.register<AlphaService>('k', svc);
      RegistryManagerSingleton.instance.destroyAll();
      expect(svc.destroyed, isTrue);
      expect(RegistryManagerSingleton.instance.isEmpty, isTrue);
    });
  });

  // ── stress / edge cases ────────────────────────────────────────────────────
  group('stress and edge cases', () {
    late RegistryManager r;
    setUp(() => r = fresh());
    tearDown(() => r.destroyAll());

    test('100 different string keys — all resolved correctly', () {
      final entries = <String, AlphaService>{};
      for (var i = 0; i < 100; i++) {
        final svc = AlphaService(name: 'svc-$i');
        entries['key-$i'] = svc;
        r.register<AlphaService>('key-$i', svc);
      }
      for (var i = 0; i < 100; i++) {
        expect(r.getInstance<AlphaService>('key-$i'), same(entries['key-$i']));
      }
      expect(r.registrySize, equals(100));
    });

    test('repeated replace 50 times — final value is correct, version is 50', () {
      r.register<AlphaService>('k', AlphaService(name: 'v0'));
      AlphaService? last;
      for (var i = 1; i <= 50; i++) {
        last = AlphaService(name: 'v$i');
        r.replace<AlphaService>('k', last);
      }
      expect(r.getInstance<AlphaService>('k'), same(last));
      expect(r.getByKey<AlphaService>('k')!.version, equals(50));
    });

    test('register-unregister-register cycle 20 times — no stale state', () {
      for (var i = 0; i < 20; i++) {
        final svc = AlphaService(name: 'cycle-$i');
        r.register<AlphaService>('cycle', svc);
        expect(r.getInstance<AlphaService>('cycle'), same(svc));
        r.unregister<AlphaService>('cycle');
        expect(r.contains<AlphaService>('cycle'), isFalse);
      }
      expect(r.isEmpty, isTrue);
    });

    test('empty string key is valid', () {
      final svc = AlphaService(name: 'empty-key');
      r.register<AlphaService>('', svc);
      expect(r.getInstance<AlphaService>(''), same(svc));
    });

    test('very long string key is valid', () {
      final longKey = 'k' * 10000;
      final svc = AlphaService();
      r.register<AlphaService>(longKey, svc);
      expect(r.getInstance<AlphaService>(longKey), same(svc));
    });

    test('keys() returns a snapshot — subsequent mutations do not affect it', () {
      r
        ..register<AlphaService>('a', AlphaService())
        ..register<BetaService>('b', BetaService());
      final snapshot = r.keys;
      r.register<GammaService>('c', GammaService());
      expect(snapshot, hasLength(2));
      expect(r.keys, hasLength(3));
    });
  });
}
