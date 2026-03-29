import 'package:singleton_manager/singleton_manager.dart';
import 'package:singleton_manager_test/singleton_manager_test.dart';
import 'package:test/test.dart';

/// Second service type for compound-key isolation tests
class OtherService implements IValueForRegistry {
  OtherService({this.name = 'OtherService'});
  final String name;
  bool _destroyed = false;
  bool get destroyed => _destroyed;

  @override
  void destroy() => _destroyed = true;
}

void main() {
  group('RegistryManager - Compound Key (Type + Key)', () {
    late IRegistry<String> registry;

    setUp(() {
      registry = createTestRegistry<String>();
    });

    tearDown(() {
      cleanupRegistry(registry);
    });

    // ── Type isolation ────────────────────────────────────────────────────
    group('type isolation', () {
      test('same key, different types do not collide', () {
        final simple = SimpleService(name: 'simple');
        final other = OtherService(name: 'other');

        registry
          ..register<SimpleService>('prod', simple)
          ..register<OtherService>('prod', other);

        expect(registry.registrySize, equals(2));
        expect(registry.getInstance<SimpleService>('prod'), same(simple));
        expect(registry.getInstance<OtherService>('prod'), same(other));
      });

      test('contains<T> is type-specific', () {
        registry.register<SimpleService>('prod', SimpleService());

        expect(registry.contains<SimpleService>('prod'), isTrue);
        expect(registry.contains<OtherService>('prod'), isFalse);
      });

      test('unregister<T> only removes the matching type', () {
        registry
          ..register<SimpleService>('env', SimpleService())
          ..register<OtherService>('env', OtherService())
          ..unregister<SimpleService>('env');

        expect(registry.contains<SimpleService>('env'), isFalse);
        expect(registry.contains<OtherService>('env'), isTrue);
        expect(registry.registrySize, equals(1));
      });

      test('replace<T> only replaces the matching type', () {
        final simple = SimpleService(name: 'old');
        final other = OtherService(name: 'original');

        registry
          ..register<SimpleService>('env', simple)
          ..register<OtherService>('env', other);

        final newSimple = SimpleService(name: 'new');
        registry.replace<SimpleService>('env', newSimple);

        expect(simple.destroyed, isTrue);
        expect(registry.getInstance<SimpleService>('env'), same(newSimple));
        expect(registry.getInstance<OtherService>('env'), same(other));
        expect(other.destroyed, isFalse);
      });

      test('DuplicateRegistrationError is type-specific', () {
        registry.register<SimpleService>('key', SimpleService());

        // Same type, same key → error
        expect(
          () => registry.register<SimpleService>('key', SimpleService()),
          throwsA(isA<DuplicateRegistrationError>()),
        );

        // Different type, same key → ok
        expect(
          () => registry.register<OtherService>('key', OtherService()),
          returnsNormally,
        );
      });

      test('getInstance<T> throws only for missing (T, key) pair', () {
        registry.register<SimpleService>('key', SimpleService());

        // Registered type works
        expect(
          () => registry.getInstance<SimpleService>('key'),
          returnsNormally,
        );

        // Unregistered type throws
        expect(
          () => registry.getInstance<OtherService>('key'),
          throwsA(isA<RegistryNotFoundError>()),
        );
      });
    });

    // ── Key isolation ─────────────────────────────────────────────────────
    group('key isolation (environment-style)', () {
      test('same type, different keys are independent', () {
        final prod = SimpleService(name: 'prod');
        final dev = SimpleService(name: 'dev');

        registry
          ..register<SimpleService>('prod', prod)
          ..register<SimpleService>('dev', dev);

        expect(registry.getInstance<SimpleService>('prod'), same(prod));
        expect(registry.getInstance<SimpleService>('dev'), same(dev));
        expect(registry.registrySize, equals(2));
      });

      test('replace on one key does not affect other keys of same type', () {
        final prod = SimpleService(name: 'prod');
        final dev = SimpleService(name: 'dev');

        registry
          ..register<SimpleService>('prod', prod)
          ..register<SimpleService>('dev', dev);

        final newProd = SimpleService(name: 'prod-v2');
        registry.replace<SimpleService>('prod', newProd);

        expect(prod.destroyed, isTrue);
        expect(registry.getInstance<SimpleService>('prod'), same(newProd));
        expect(registry.getInstance<SimpleService>('dev'), same(dev));
        expect(dev.destroyed, isFalse);
      });

      test('destroyAll destroys all types and keys', () {
        final s1 = SimpleService();
        final s2 = SimpleService();
        final o1 = OtherService();

        registry
          ..register<SimpleService>('prod', s1)
          ..register<SimpleService>('dev', s2)
          ..register<OtherService>('prod', o1)
          ..destroyAll();

        expect(s1.destroyed, isTrue);
        expect(s2.destroyed, isTrue);
        expect(o1.destroyed, isTrue);
        expect(registry.isEmpty, isTrue);
      });
    });

    // ── Compound key structure ────────────────────────────────────────────
    group('compound keys', () {
      test('keys returns (Type, Key) records', () {
        registry
          ..register<SimpleService>('prod', SimpleService())
          ..register<OtherService>('prod', OtherService())
          ..register<SimpleService>('dev', SimpleService());

        final keys = registry.keys;
        expect(keys, hasLength(3));
        expect(keys, contains((SimpleService, 'prod')));
        expect(keys, contains((OtherService, 'prod')));
        expect(keys, contains((SimpleService, 'dev')));
      });

      test('extractKeys returns only the Key dimension', () {
        registry
          ..register<SimpleService>('prod', SimpleService())
          ..register<OtherService>('staging', OtherService());

        final rawKeys = extractKeys(registry.keys);
        expect(rawKeys, containsAll(['prod', 'staging']));
      });

      test('lazy compound key is resolved correctly', () {
        registry
          ..registerLazy<SimpleService>(
            'prod',
            () => SimpleService(name: 'lazy-prod'),
          )
          ..registerLazy<OtherService>(
            'prod',
            () => OtherService(name: 'lazy-other'),
          );

        expect(
          registry.getInstance<SimpleService>('prod').name,
          equals('lazy-prod'),
        );
        expect(
          registry.getInstance<OtherService>('prod').name,
          equals('lazy-other'),
        );
      });
    });

    // ── Version tracking per compound key ─────────────────────────────────
    group('version tracking per compound key', () {
      test('versions are independent per (Type, Key)', () {
        registry
          ..register<SimpleService>('k', SimpleService())
          ..register<OtherService>('k', OtherService())
          ..replace<SimpleService>('k', SimpleService())
          ..replace<SimpleService>('k', SimpleService());

        final vSimple = registry.getByKey<SimpleService>('k')!.version;
        final vOther = registry.getByKey<OtherService>('k')!.version;

        expect(vSimple, equals(2));
        expect(vOther, equals(0));
      });
    });
  });

  // ── Integer key ───────────────────────────────────────────────────────────
  group('RegistryManager<int> - integer keys', () {
    late IRegistry<int> registry;

    setUp(() => registry = createTestRegistry<int>());
    tearDown(() => cleanupRegistry(registry));

    test('integer keys work correctly', () {
      final s1 = SimpleService(name: 'one');
      final s2 = SimpleService(name: 'two');

      registry
        ..register<SimpleService>(1, s1)
        ..register<SimpleService>(2, s2);

      expect(registry.getInstance<SimpleService>(1), same(s1));
      expect(registry.getInstance<SimpleService>(2), same(s2));
    });

    test('same integer key, different types', () {
      final simple = SimpleService();
      final other = OtherService();

      registry
        ..register<SimpleService>(42, simple)
        ..register<OtherService>(42, other);

      expect(registry.registrySize, equals(2));
      expect(registry.getInstance<SimpleService>(42), same(simple));
      expect(registry.getInstance<OtherService>(42), same(other));
    });
  });
}
