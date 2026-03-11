/// Test helper functions and utilities.
library singleton_manager_test.src.helpers.test_helpers;

import 'package:singleton_manager/singleton_manager.dart';

/// Creates a fresh SingletonManager for testing.
SingletonManager<String> createTestManager() {
  return SingletonManager<String>();
}

/// Creates a fresh SingletonManager with a custom key type.
SingletonManager<K> createTestManagerWithKeyType<K>() {
  return SingletonManager<K>();
}

/// Verifies that two singleton instances are the same object.
void expectSameInstance<T>(T instance1, T instance2) {
  if (identical(instance1, instance2)) {
    return;
  }
  throw AssertionError(
    'Expected instances to be identical, but they were different objects',
  );
}

/// Verifies that two singleton instances are not the same object.
void expectDifferentInstances<T>(T instance1, T instance2) {
  if (!identical(instance1, instance2)) {
    return;
  }
  throw AssertionError(
    'Expected instances to be different objects, but they were identical',
  );
}
