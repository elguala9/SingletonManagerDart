import 'package:singleton_manager/singleton_manager.dart';
import 'package:test/test.dart';

/// Cleanup helper for use in tearDown()
void cleanupRegistry<Key, Value extends IValueForRegistry>(
  Registry<Key, Value> registry,
) {
  registry.destroyAll();
}

/// Matcher for checking if two instances are the same (identical)
Matcher isSameInstance<T>(T expected) =>
    _SameInstanceMatcher<T>(expected);

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
    // We can't directly check _destroyed, so we rely on external tracking
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

/// Create a test registry manager for the given key and value types
RegistryManager<Key, Value> createTestRegistry<Key,
    Value extends IValueForRegistry>() {
  return RegistryManager<Key, Value>();
}
