import 'package:singleton_manager/singleton_manager.dart';

/// A simple test service for basic registration and retrieval tests
class SimpleService implements IValueForRegistry {
  /// Constructor
  SimpleService({this.name = 'SimpleService'});

  /// Constructor that increments the counter
  factory SimpleService.counted({String name = 'SimpleService'}) {
    instantiationCount++;
    return SimpleService(name: name);
  }

  /// Name of this service instance
  final String name;

  /// Counter for tracking instantiations
  static int instantiationCount = 0;

  bool _destroyed = false;

  /// Whether this service has been destroyed
  bool get destroyed => _destroyed;

  @override
  void destroy() {
    _destroyed = true;
  }
}

/// A service designed for testing lazy loading
class LazyService implements IValueForRegistry {
  /// Constructor
  LazyService({this.name = 'LazyService'});

  /// Constructor that increments the counter
  LazyService.tracked({this.name = 'LazyService'}) {
    instantiationCount++;
    constructorCalled = true;
  }

  /// Name of this service instance
  final String name;

  /// Counter for tracking instantiations
  static int instantiationCount = 0;

  /// Flag to track if constructor was called
  static bool constructorCalled = false;

  bool _destroyed = false;

  /// Whether this service has been destroyed
  bool get destroyed => _destroyed;

  @override
  void destroy() {
    _destroyed = true;
  }

  /// Reset the counters for testing
  static void reset() {
    instantiationCount = 0;
    constructorCalled = false;
  }
}

/// A service for testing async initialization patterns
class AsyncService implements IValueForRegistry {
  /// Constructor
  AsyncService({required this.initialized, this.name = 'AsyncService'});

  /// Name of this service instance
  final String name;

  /// Whether this service has been initialized
  final bool initialized;

  /// Counter for tracking instantiations
  static int instantiationCount = 0;

  bool _destroyed = false;

  /// Whether this service has been destroyed
  bool get destroyed => _destroyed;

  /// Factory for creating an AsyncService via async initialization
  static Future<AsyncService> create({String name = 'AsyncService'}) async {
    // Simulate async initialization
    await Future<void>.delayed(const Duration(milliseconds: 10));
    instantiationCount++;
    return AsyncService(name: name, initialized: true);
  }

  @override
  void destroy() {
    _destroyed = true;
  }

  /// Reset the counter for testing
  static void reset() {
    instantiationCount = 0;
  }
}
