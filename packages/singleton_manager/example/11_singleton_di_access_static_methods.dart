/// Example 11: SingletonDIAccess - Static methods and instance-based
/// registration (v0.3.0+)
///
/// This example demonstrates:
/// 1. Static access methods via SingletonDIAccess
/// 2. Instance-based registration (pre-configured objects)
/// 3. Comparison with factory-based registration
///
/// When to use:
/// - Static access: Simplified code without explicit instance management
/// - Instance-based: Pre-configured services, testing with prepared
/// objects

import 'package:singleton_manager/singleton_manager.dart';

// Define service interfaces and implementations
abstract class IDatabaseService implements ISingleton<dynamic, void> {
  String query(String sql);
}

class DatabaseService implements IDatabaseService {
  final String _host;
  final int _port;

  DatabaseService({String host = 'localhost', int port = 5432})
      : _host = host, _port = port;

  @override
  Future<void> initialize(dynamic input) async {
    print('DatabaseService: Initializing with custom input');
  }

  @override
  Future<void> initializeDI() async {
    print('DatabaseService: DI initialization complete');
  }

  @override
  String query(String sql) => 'Executing on $_host:$_port - $sql';
}

abstract class IUserRepository implements ISingleton<dynamic, void> {
  String getUser(int id);
}

class UserRepository implements IUserRepository {
  final IDatabaseService _db;

  UserRepository({required IDatabaseService db}) : _db = db;



  @override
  Future<void> initialize(dynamic input) async {
    print('UserRepository: Initializing');
  }

  @override
  Future<void> initializeDI() async {
    print('UserRepository: DI initialization complete');
  }

  @override
  String getUser(int id) => _db.query('SELECT * FROM users WHERE id = $id');
}

void main() async {
  print('=== Example 11: SingletonDIAccess Static Methods (v0.3.0+) ===\n');

  // ===== Approach 1: Using static access with factory registration =====
  print('--- Approach 1: Static Access (Simplified API) ---');

  // Register factories
  SingletonDI.registerFactory<DatabaseService>(
    () => DatabaseService(host: 'prod-db', port: 5432),
  );
  SingletonDI.registerFactory<UserRepository>(
    () => UserRepository(db: SingletonDIAccess.get<DatabaseService>()),
  );

  // Use static methods - no need to get instance explicitly
  await SingletonDIAccess.add<DatabaseService>();
  await SingletonDIAccess.add<UserRepository>();

  // Retrieve and use
  final dbStatic = SingletonDIAccess.get<DatabaseService>();
  final userRepoStatic = SingletonDIAccess.get<UserRepository>();

  print('Database query: ${dbStatic.query('SELECT * FROM configs')}');
  print('User query: ${userRepoStatic.getUser(123)}\n');

  // Clean up
  SingletonDIAccess.remove<UserRepository>();
  SingletonDIAccess.remove<DatabaseService>();

  // ===== Approach 2: Instance-based registration (pre-configured) =====
  print('--- Approach 2: Instance-Based Registration (Pre-configured) ---');

  // Create pre-configured instances (useful for testing or when you need
  // to set up complex objects before registering them)
  final testDb = DatabaseService(host: 'test-db', port: 5433);
  final testUserRepo = UserRepository(db: testDb);

  // Register instances directly
  await SingletonDIAccess.addInstance<DatabaseService>(testDb);
  await SingletonDIAccess.addInstance<UserRepository>(testUserRepo);

  // Retrieve and use
  final dbInstance = SingletonDIAccess.get<DatabaseService>();
  final userRepoInstance = SingletonDIAccess.get<UserRepository>();

  print('Test DB query: ${dbInstance.query('SELECT * FROM test_data')}');
  print('Test user: ${userRepoInstance.getUser(456)}\n');

  // ===== Approach 3: Instance-based with interface registration =====
  print('--- Approach 3: Interface-Based Instance Registration ---');

  // Create a specialized database service
  final devDb = DatabaseService(host: 'dev-db', port: 5434);

  // Register as interface using instance
  await SingletonDIAccess.addInstanceAs<IDatabaseService, DatabaseService>(
    devDb,
  );

  final dbByInterface = SingletonDIAccess.get<IDatabaseService>();
  final devDbQuery =
      (dbByInterface as DatabaseService).query('SELECT * FROM dev_data');
  print('Dev DB query: $devDbQuery\n');

  // ===== Approach 4: Comparison - traditional manager access =====
  print('--- Approach 4: Traditional Manager Access (Still Works) ---');

  final manager = SingletonManager.instance;

  // Register factories
  SingletonDI.registerFactory<DatabaseService>(
    () => DatabaseService(host: 'backup-db', port: 5435),
  );

  // Traditional way - use manager instance
  await manager.add<DatabaseService>();
  final dbTraditional = manager.get<DatabaseService>();

  print('Backup DB query: ${dbTraditional.query('SELECT * FROM backups')}\n');

  // Clean up all
  manager
    ..unregister<DatabaseService>()
    ..unregister<IDatabaseService>()
    ..unregister<UserRepository>();

  // ===== Benefits Summary =====
  print('--- Benefits of v0.3.0 Features ---');
  print(
    'Static Access (SingletonDIAccess):\n'
    '  ✓ Cleaner code - no need to get manager instance\n'
    '  ✓ Shorter method calls\n'
    '  ✓ Easier in tests and utility functions\n',
  );
  print(
    'Instance-Based Registration:\n'
    '  ✓ Pre-configure complex objects before registering\n'
    '  ✓ Better for testing with controlled state\n'
    '  ✓ No need for factory functions\n'
    '  ✓ Supports interface-based registration too\n',
  );
}
