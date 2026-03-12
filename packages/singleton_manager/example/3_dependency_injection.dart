// ignore_for_file: avoid_print,file_names,one_member_abstracts,sort_constructors_first,cascade_invocations,unnecessary_brace_in_string_interps,lines_longer_than_80_chars
import 'package:singleton_manager/singleton_manager.dart';

/// Example 3: Dependency Injection Pattern
///
/// Shows how to build a DI container with service dependencies.
/// Services implement interfaces and depend on other services.

// ============ Interfaces ============

abstract interface class IRepository {
  Future<String> fetchData(String id);
}

abstract interface class ILogger {
  void log(String message);
  void error(String message);
}

abstract interface class IUserService {
  Future<String> getUserName(String userId);
}

// ============ Implementations ============

class Repository implements IRepository, IValueForRegistry {
  Repository() {
    print('✓ Repository initialized');
  }

  @override
  Future<String> fetchData(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return 'Data for $id';
  }

  @override
  void destroy() {
    print('✗ Repository destroyed');
  }
}

class ConsoleLogger implements ILogger, IValueForRegistry {
  int logCount = 0;

  ConsoleLogger() {
    print('✓ ConsoleLogger initialized');
  }

  @override
  void log(String message) {
    logCount++;
    print('[INFO #$logCount] $message');
  }

  @override
  void error(String message) {
    print('[ERROR] $message');
  }

  @override
  void destroy() {
    print('✗ ConsoleLogger destroyed (logged $logCount messages)');
  }
}

class UserService implements IUserService, IValueForRegistry {
  late final IRepository _repository;
  late final ILogger _logger;

  UserService() {
    print('✓ UserService initialized');
  }

  void injectDependencies(IRepository repo, ILogger logger) {
    _repository = repo;
    _logger = logger;
    _logger.log('UserService dependencies injected');
  }

  @override
  Future<String> getUserName(String userId) async {
    _logger.log('Fetching user: $userId');
    final data = await _repository.fetchData(userId);
    _logger.log('Retrieved: $data');
    return data;
  }

  @override
  void destroy() {
    print('✗ UserService destroyed');
  }
}

// ============ DI Container ============

class DIContainer with Registry<Type, IValueForRegistry> {
  void registerServices() {
    print('Registering services...');

    // Register concrete implementations
    register(IRepository, Repository());
    register(ILogger, ConsoleLogger());

    // Register service that depends on others
    final userService = UserService();
    register(IUserService, userService);

    // Inject dependencies
    userService.injectDependencies(
      getInstance(IRepository) as IRepository,
      getInstance(ILogger) as ILogger,
    );

    print('Services registered: ${registrySize}\n');
  }

  T getService<T>() => getInstance(T) as T;

  void shutdown() {
    print('\nShutting down services...');
    destroyAll();
  }
}

void main() async {
  print('=== Dependency Injection Pattern ===\n');

  // Create and configure container
  final container = DIContainer();
  container.registerServices();

  // Use services
  print('Step 1: Get logger and log messages');
  final logger = container.getService<ILogger>();
  logger.log('Application started');
  logger.log('Initializing user service');
  print('');

  print('Step 2: Use UserService with dependencies');
  final userService = container.getService<IUserService>();
  final userName = await userService.getUserName('user123');
  print('User name: $userName\n');

  print('Step 3: Verify singleton behavior');
  final logger2 = container.getService<ILogger>();
  print('Same logger instance: ${identical(logger, logger2)}\n');

  print('Step 4: List all registered services');
  for (final serviceType in container.keys) {
    print('  - $serviceType');
  }

  // Cleanup
  container.shutdown();
}
