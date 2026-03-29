import 'package:singleton_manager/singleton_manager.dart';

// ignore: depend_on_referenced_packages
import 'package:test/test.dart';

/// Cleanup helper for use in tearDown()
void cleanupRegistry<Key>(IRegistry<Key> registry) {
  registry.destroyAll();
}

/// Extracts only the Key part from compound (Type, Key) registry keys.
/// Useful for assertions that don't care about the type dimension.
Set<Key> extractKeys<Key>(Set<(Type, Key)> compoundKeys) =>
    compoundKeys.map((k) => k.$2).toSet();

/// Matcher for checking if two instances are the same (identical)
Matcher isSameInstance<T>(T expected) => _SameInstanceMatcher<T>(expected);

class _SameInstanceMatcher<T> extends Matcher {
  _SameInstanceMatcher(this.expected);

  final T expected;

  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    return identical(item, expected);
  }

  @override
  Description describe(Description description) =>
      description.add('same instance as $expected');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return mismatchDescription.add('was a different instance');
  }
}

/// Matcher for checking if a value was destroyed
Matcher isDestroyed() => _DestroyedMatcher();

class _DestroyedMatcher extends Matcher {
  @override
  bool matches(Object? item, Map<dynamic, dynamic> matchState) {
    if (item is! IValueForRegistry) {
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) =>
      description.add('destroyed');

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    return mismatchDescription.add('was not destroyed');
  }
}

/// Create a test registry for the given key type.
IRegistry<Key> createTestRegistry<Key>() {
  return _TestRegistry<Key>();
}

class _TestRegistry<Key>
    with RegistryOnlyKey<Key>
    implements IRegistry<Key> {}
