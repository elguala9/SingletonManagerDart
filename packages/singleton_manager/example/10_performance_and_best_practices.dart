// ignore_for_file: avoid_print,file_names,one_member_abstracts,avoid_catching_errors,sort_constructors_first,cascade_invocations,omit_local_variable_types,unnecessary_lambdas,lines_longer_than_80_chars,unnecessary_brace_in_string_interps
import 'package:singleton_manager/singleton_manager.dart';

/// Example 10: Performance and Best Practices
///
/// Demonstrates:
/// - Lazy loading for expensive resources
/// - Resource pooling
/// - Proper cleanup and lifecycle management
/// - Performance considerations

// ============ Resource Models ============

class DatabaseConnection implements IValueForRegistry {
  static int _idCounter = 0;
  final int _id = ++_idCounter;
  final String server;
  late int _createdAt;

  DatabaseConnection({required this.server}) {
    _createdAt = DateTime.now().millisecondsSinceEpoch;
    print('  ✓ DatabaseConnection#$_id created on $server');
  }

  Future<String> query(String sql) async {
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return 'Result from connection#$_id';
  }

  @override
  void destroy() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final lifetime = now - _createdAt;
    print('  ✗ DatabaseConnection#$_id destroyed (lifetime: ${lifetime}ms)');
  }
}

class HeavyComputeService implements IValueForRegistry {
  static int _instanceCount = 0;
  final int _id = ++_instanceCount;

  HeavyComputeService() {
    print('  ✓ HeavyComputeService#$_id created (expensive initialization)');
  }

  Future<int> compute(int value) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return value * value;
  }

  @override
  void destroy() {
    print('  ✗ HeavyComputeService#$_id destroyed');
  }
}

class ConnectionPool implements IValueForRegistry {
  static const int maxConnections = 5;
  final List<DatabaseConnection> _available = [];
  final Set<DatabaseConnection> _inUse = {};

  ConnectionPool() {
    print('  ✓ ConnectionPool created (max: $maxConnections)');
  }

  DatabaseConnection acquire() {
    if (_available.isEmpty) {
      print('  Creating new connection (${_available.length + _inUse.length}/$maxConnections)');
      _available.add(DatabaseConnection(server: 'localhost:5432'));
    }
    final conn = _available.removeLast();
    _inUse.add(conn);
    return conn;
  }

  void release(DatabaseConnection conn) {
    _inUse.remove(conn);
    _available.add(conn);
    print('  Connection returned to pool (available: ${_available.length})');
  }

  @override
  void destroy() {
    for (final conn in _available) {
      conn.destroy();
    }
    for (final conn in _inUse) {
      conn.destroy();
    }
    _available.clear();
    _inUse.clear();
    print('  ✗ ConnectionPool destroyed');
  }
}

// ============ Registry with Best Practices ============

class OptimizedRegistry with Registry<String, IValueForRegistry> {
  final Stopwatch _timer = Stopwatch();

  void printRegistryStats() {
    print('\nRegistry Stats:');
    print('  Total entries: ${registrySize}');
    print('  Is empty: $isEmpty');
    print('  Keys: ${keys.join(", ")}');
  }

  void timeOperation(String name, void Function() fn) {
    _timer.reset();
    _timer.start();
    fn();
    _timer.stop();
    print('  Time: ${_timer.elapsedMilliseconds}ms');
  }
}

// ============ Best Practices Demonstration ============

class BestPracticesDemo {
  // BEST PRACTICE 1: Lazy loading for expensive resources
  static void demonstrateLazyLoading(OptimizedRegistry registry) {
    print('\n=== BEST PRACTICE 1: Lazy Loading ===');
    print('Registering expensive services lazily...');

    registry.registerLazy('compute', () {
      print('  [LAZY] Creating HeavyComputeService on demand');
      return HeavyComputeService();
    });
    print('Service registered but NOT created yet!\n');

    print('First access to "compute" (creates instance)...');
    registry.timeOperation('getInstance', () {
      registry.getInstance('compute');
    });

    print('Second access to "compute" (uses cached instance)...');
    registry.timeOperation('getInstance', () {
      registry.getInstance('compute');
    });
  }

  // BEST PRACTICE 2: Resource pooling
  static void demonstrateResourcePooling(OptimizedRegistry registry) {
    print('\n=== BEST PRACTICE 2: Resource Pooling ===');
    print('Creating connection pool...');

    final pool = ConnectionPool();
    registry.register('pool', pool);

    print('Acquiring connections...');
    final conn1 = pool.acquire();
    final conn2 = pool.acquire();
    final conn3 = pool.acquire();

    print('Releasing connections...');
    pool.release(conn1);
    pool.release(conn2);
    pool.release(conn3);

    print('Reusing released connections...');
    final conn4 = pool.acquire();
    print('Got same connection instance: ${identical(conn1, conn4)}');
  }

  // BEST PRACTICE 3: Eager loading for critical services
  static void demonstrateEagerLoading(OptimizedRegistry registry) {
    print('\n=== BEST PRACTICE 3: Eager Loading ===');
    print('Registering critical services eagerly...');

    print('Creating DatabaseConnection...');
    registry.timeOperation('register', () {
      registry.register('primary_db', DatabaseConnection(server: 'localhost:5432'));
    });

    print('Accessing immediately (no creation delay)...');
    registry.timeOperation('getInstance', () {
      registry.getInstance('primary_db');
    });
  }

  // BEST PRACTICE 4: Batch operations
  static void demonstrateBatchOperations(OptimizedRegistry registry) {
    print('\n=== BEST PRACTICE 4: Batch Operations ===');
    print('Registering multiple services...');

    registry.timeOperation('batch register', () {
      for (int i = 1; i <= 10; i++) {
        registry.registerLazy('service_$i', () => HeavyComputeService());
      }
    });

    print('Accessing multiple services...');
    registry.timeOperation('batch getInstance', () {
      for (int i = 1; i <= 10; i++) {
        registry.getInstance('service_$i');
      }
    });

    registry.printRegistryStats();
  }

  // BEST PRACTICE 5: Proper cleanup
  static void demonstrateProperCleanup(OptimizedRegistry registry) {
    print('\n=== BEST PRACTICE 5: Proper Cleanup ===');
    print('Current registry state before cleanup:');
    registry.printRegistryStats();

    print('\nCleaning up all resources...');
    registry.timeOperation('destroyAll', () {
      registry.destroyAll();
    });

    print('After cleanup:');
    print('  Registry empty: ${registry.isEmpty}');
    print('  Size: ${registry.registrySize}');
  }

  // BEST PRACTICE 6: Error-safe operations
  static void demonstrateErrorSafeOperations(OptimizedRegistry registry) {
    print('\n=== BEST PRACTICE 6: Error-Safe Operations ===');

    print('Safe check before access:');
    if (registry.contains('non_existent')) {
      print('  Found');
    } else {
      print('  Not found (safe)');
    }

    print('Try-catch for uncertain operations:');
    try {
      registry.getInstance('non_existent');
    } on RegistryNotFoundError catch (e) {
      print('  Handled: $e');
    }

    print('Check registry state:');
    print('  Is empty: ${registry.isEmpty}');
    print('  Size: ${registry.registrySize}');
  }
}

// ============ Main ============

void main() async {
  print('=== Performance and Best Practices ===\n');

  // Demo 1: Lazy loading
  var registry = OptimizedRegistry();
  BestPracticesDemo.demonstrateLazyLoading(registry);
  registry.destroyAll();

  // Demo 2: Eager loading and pooling
  registry = OptimizedRegistry();
  BestPracticesDemo.demonstrateEagerLoading(registry);
  BestPracticesDemo.demonstrateResourcePooling(registry);
  registry.destroyAll();

  // Demo 3: Batch operations
  registry = OptimizedRegistry();
  BestPracticesDemo.demonstrateBatchOperations(registry);
  BestPracticesDemo.demonstrateProperCleanup(registry);

  // Demo 4: Error safety
  registry = OptimizedRegistry();
  BestPracticesDemo.demonstrateErrorSafeOperations(registry);

  print('\n✓ All best practices demonstrated');
}
