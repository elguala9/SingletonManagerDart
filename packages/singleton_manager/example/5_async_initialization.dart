// ignore_for_file: avoid_print
import 'package:singleton_manager/singleton_manager.dart';

/// Example 5: Async Initialization with ISingleton
///
/// The ISingleton interface allows services to perform async initialization
/// before being used. Useful for:
/// - Loading configuration from files/APIs
/// - Establishing database connections
/// - Warming up caches

// ============ Service Interfaces ============

abstract interface class IDatabase {
  Future<String> query(String sql);
  void close();
}

abstract interface class IAuthService {
  Future<bool> authenticate(String username, String password);
}

// ============ Implementations ============

class Database implements IDatabase, ISingleton<String, void> {
  late String connectionString;
  bool _connected = false;

  Database() {
    print('✓ Database instance created');
  }

  @override
  Future<void> initialize(String input) async {
    print('  Initializing with: $input');
    connectionString = input;
  }

  @override
  Future<void> initializeDI() async {
    print('  Establishing connection...');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _connected = true;
    print('  Connected to: $connectionString');
  }

  @override
  Future<String> query(String sql) async {
    if (!_connected) throw StateError('Database not initialized');
    await Future.delayed(const Duration(milliseconds: 100));
    return 'Result: $sql executed';
  }

  @override
  void close() {
    _connected = false;
    print('✗ Database connection closed');
  }
}

class AuthService implements IAuthService, ISingleton<Map<String, String>, void> {
  late Map<String, String> _config;

  AuthService() {
    print('✓ AuthService instance created');
  }

  @override
  Future<void> initialize(Map<String, String> input) async {
    print('  Loading config: ${input.keys.join(", ")}');
    _config = input;
  }

  @override
  Future<void> initializeDI() async {
    print('  Setting up authentication...');
    // In real app, would get from DI container
    await Future<void>.delayed(const Duration(milliseconds: 150));
    print('  Auth initialized with realm: ${_config['realm']}');
  }

  @override
  Future<bool> authenticate(String username, String password) async {
    print('  Authenticating $username...');
    await Future.delayed(const Duration(milliseconds: 100));
    return username.isNotEmpty && password.length >= 6;
  }
}

class CacheService implements ISingleton<int, void> {
  final Map<String, dynamic> _cache = {};
  int maxSize = 100;

  CacheService() {
    print('✓ CacheService instance created');
  }

  @override
  Future<void> initialize(int input) async {
    print('  Setting max cache size: $input');
    maxSize = input;
  }

  @override
  Future<void> initializeDI() async {
    print('  Warming up cache...');
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _cache['startup_time'] = DateTime.now();
    _cache['startup_count'] = 1;
    print('  Cache warmed up');
  }

  void set(String key, dynamic value) {
    if (_cache.length >= maxSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[key] = value;
  }

  dynamic get(String key) => _cache[key];

  void clear() {
    _cache.clear();
    print('✗ Cache cleared');
  }
}

// ============ Application ============

void main() async {
  print('=== Async Initialization with ISingleton ===\n');

  print('Step 1: Create service instances');
  final db = Database();
  final auth = AuthService();
  final cache = CacheService();
  print('');

  print('Step 2: Initialize services with config');
  await db.initialize('postgresql://localhost:5432/appdb');
  await db.initializeDI();
  print('');

  await auth.initialize({
    'realm': 'MyApp',
    'provider': 'OAuth2',
  });
  await auth.initializeDI();
  print('');

  await cache.initialize(500);
  await cache.initializeDI();
  print('');

  // ========== Use Services ==========
  print('Step 3: Use initialized services\n');

  print('Database:');
  final result = await db.query('SELECT * FROM users');
  print('  $result\n');

  print('Authentication:');
  final valid1 = await auth.authenticate('john', 'secret123');
  print('  john/secret123 valid: $valid1');
  final valid2 = await auth.authenticate('jane', 'no');
  print('  jane/no valid: $valid2\n');

  print('Cache:');
  cache.set('user:123', {'name': 'John', 'email': 'john@example.com'});
  print('  Stored user:123');
  final user = cache.get('user:123');
  print('  Retrieved: $user\n');

  // ========== Cleanup ==========
  print('Step 4: Cleanup');
  db.close();
  cache.clear();
  print('Application shutdown complete');
}
