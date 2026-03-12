// ignore_for_file: avoid_print, unused_local_variable
import 'package:singleton_manager/singleton_manager.dart';

/// Example 7: Complex Real-World Scenario
///
/// A complete multi-tier application with:
/// - Data layer (Database, Repository)
/// - Business logic layer (Services)
/// - Presentation layer (Controllers)
/// - Dependency injection and error handling

// ============ DATA LAYER ============

abstract interface class IDatabase {
  Future<Map<String, dynamic>> query(String sql);
}

abstract interface class IUserRepository {
  Future<Map<String, dynamic>> getUserById(String id);
  Future<List<Map<String, dynamic>>> getAllUsers();
}

class Database implements IDatabase, IValueForRegistry {
  bool _connected = false;

  Database() {
    print('  Database: constructor called');
  }

  Future<void> connect() async {
    await Future.delayed(const Duration(milliseconds: 100));
    _connected = true;
    print('  Database: connected');
  }

  @override
  Future<Map<String, dynamic>> query(String sql) async {
    if (!_connected) throw StateError('Database not connected');
    print('  Database: executing "$sql"');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return {
      'id': '123',
      'name': 'John Doe',
      'email': 'john@example.com',
    };
  }

  @override
  void destroy() {
    _connected = false;
    print('  Database: closed');
  }
}

class UserRepository implements IUserRepository, IValueForRegistry {
  late final IDatabase _database;

  UserRepository() {
    print('  UserRepository: constructor called');
  }

  void setDatabase(IDatabase database) {
    _database = database;
    print('  UserRepository: database injected');
  }

  @override
  Future<Map<String, dynamic>> getUserById(String id) async {
    print('  UserRepository: fetching user $id');
    return _database.query('SELECT * FROM users WHERE id = $id');
  }

  @override
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    print('  UserRepository: fetching all users');
    final user = await _database.query('SELECT * FROM users');
    return [user];
  }

  @override
  void destroy() {
    print('  UserRepository: destroyed');
  }
}

// ============ BUSINESS LOGIC LAYER ============

abstract interface class IUserService {
  Future<Map<String, dynamic>> getUser(String id);
  Future<List<Map<String, dynamic>>> listUsers();
}

abstract interface class ICacheService {
  void set(String key, dynamic value);
  dynamic get(String key);
  void invalidate(String key);
}

class UserService implements IUserService, IValueForRegistry {
  late final IUserRepository _repository;

  UserService() {
    print('  UserService: constructor called');
  }

  void setRepository(IUserRepository repository) {
    _repository = repository;
    print('  UserService: repository injected');
  }

  @override
  Future<Map<String, dynamic>> getUser(String id) async {
    print('  UserService: retrieving user $id');
    return _repository.getUserById(id);
  }

  @override
  Future<List<Map<String, dynamic>>> listUsers() async {
    print('  UserService: listing all users');
    return _repository.getAllUsers();
  }

  @override
  void destroy() {
    print('  UserService: destroyed');
  }
}

class CacheService implements ICacheService, IValueForRegistry {
  final Map<String, dynamic> _cache = {};

  CacheService() {
    print('  CacheService: constructor called');
  }

  @override
  void set(String key, dynamic value) {
    _cache[key] = value;
    print('  CacheService: cached $key');
  }

  @override
  dynamic get(String key) => _cache[key];

  @override
  void invalidate(String key) {
    _cache.remove(key);
    print('  CacheService: invalidated $key');
  }

  @override
  void destroy() {
    _cache.clear();
    print('  CacheService: destroyed (${_cache.length} items cleared)');
  }
}

// ============ PRESENTATION LAYER ============

abstract interface class IUserController {
  Future<void> handleGetUser(String userId);
  Future<void> handleListUsers();
}

class UserController implements IUserController, IValueForRegistry {
  late final IUserService _userService;
  late final ICacheService _cache;

  UserController() {
    print('  UserController: constructor called');
  }

  void setDependencies(IUserService service, ICacheService cache) {
    _userService = service;
    _cache = cache;
    print('  UserController: dependencies injected');
  }

  @override
  Future<void> handleGetUser(String userId) async {
    print('UserController: handling GET /users/$userId');
    final cached = _cache.get('user:$userId');
    if (cached != null) {
      print('  [CACHE HIT] $cached');
      return;
    }
    final user = await _userService.getUser(userId);
    _cache.set('user:$userId', user);
    print('  [RESPONSE] $user');
  }

  @override
  Future<void> handleListUsers() async {
    print('UserController: handling GET /users');
    final users = await _userService.listUsers();
    print('  [RESPONSE] found ${users.length} users');
  }

  @override
  void destroy() {
    print('  UserController: destroyed');
  }
}

// ============ APPLICATION DI CONTAINER ============

class ApplicationContainer with Registry<Type, IValueForRegistry> {
  Future<void> initialize() async {
    print('\n=== Initializing Application Container ===\n');

    // 1. Register data layer
    print('1. Registering data layer...');
    final db = Database();
    register(IDatabase, db);
    await db.connect();

    final userRepo = UserRepository();
    userRepo.setDatabase(db);
    register(IUserRepository, userRepo);
    print('');

    // 2. Register business logic layer
    print('2. Registering business logic layer...');
    final cache = CacheService();
    register(ICacheService, cache);

    final userService = UserService();
    userService.setRepository(getInstance(IUserRepository) as IUserRepository);
    register(IUserService, userService);
    print('');

    // 3. Register presentation layer
    print('3. Registering presentation layer...');
    final userController = UserController();
    userController.setDependencies(
      getInstance(IUserService) as IUserService,
      getInstance(ICacheService) as ICacheService,
    );
    register(IUserController, userController);
    print('');

    print('✓ Container initialized with ${registrySize} services\n');
  }

  T get<T>() => getInstance(T) as T;

  Future<void> shutdown() async {
    print('\n=== Shutting Down Application ===\n');
    destroyAll();
    print('✓ Application shutdown complete\n');
  }
}

// ============ APPLICATION MAIN ============

void main() async {
  print('=== Complex Real-World Scenario ===');
  print('Multi-tier application with DI container\n');

  // Initialize container
  final app = ApplicationContainer();
  await app.initialize();

  // Use application
  print('=== Application Running ===\n');

  print('Test 1: Get user (with cache miss)');
  final controller = app.get<IUserController>();
  await controller.handleGetUser('123');
  print('');

  print('Test 2: Get user again (with cache hit)');
  await controller.handleGetUser('123');
  print('');

  print('Test 3: List all users');
  await controller.handleListUsers();
  print('');

  print('Test 4: Service count');
  print('Registered services: ${app.registrySize}');
  print('Service types: ${app.keys.join(", ")}\n');

  // Cleanup
  await app.shutdown();
}
