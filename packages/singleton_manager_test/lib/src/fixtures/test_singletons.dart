/// Test singleton implementations for testing SingletonManager.
library singleton_manager_test.src.fixtures.test_singletons;

/// A simple test service for unit tests.
class TestService {
  TestService({this.name = 'test'});

  final String name;
  int callCount = 0;

  void call() {
    callCount++;
  }

  @override
  String toString() => 'TestService(name=$name, callCount=$callCount)';
}

/// A heavier service for testing lazy loading.
class HeavyService {
  HeavyService({this.initialized = false});

  bool initialized;
  late String _data;

  void initialize() {
    initialized = true;
    _data = 'Heavy data loaded';
  }

  String getData() => _data;
}

/// A service that tracks instantiation count.
class CountedService {
  static int instanceCount = 0;

  CountedService() {
    instanceCount++;
  }

  static void reset() {
    instanceCount = 0;
  }
}

/// A disposable service for testing cleanup.
class DisposableService {
  bool isDisposed = false;

  void dispose() {
    isDisposed = true;
  }
}
