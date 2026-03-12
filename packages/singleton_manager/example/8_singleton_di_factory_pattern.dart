// ignore_for_file: avoid_print,unused_local_variable,file_names,sort_constructors_first,always_put_control_body_on_new_line,unnecessary_lambdas,cast_nullable_to_non_nullable,lines_longer_than_80_chars
import 'package:singleton_manager/singleton_manager.dart';

/// Example 8: SingletonDI - Factory Pattern
///
/// SingletonDI allows you to register factory functions globally,
/// then create singletons on-demand from those factories.
/// Useful for:
/// - Delayed initialization
/// - Circular dependencies
/// - Complex construction logic

// ============ Services ============

class ApiClient {
  final String baseUrl;

  ApiClient(this.baseUrl) {
    print('✓ ApiClient created (baseUrl: $baseUrl)');
  }

  Future<String> request(String endpoint) async {
    print('  Requesting: $baseUrl$endpoint');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return 'Response from $endpoint';
  }
}

class AppConfig {
  final String appName;
  final String environment;
  final String apiBaseUrl;

  AppConfig({
    required this.appName,
    required this.environment,
    required this.apiBaseUrl,
  }) {
    print('✓ AppConfig created (app: $appName, env: $environment)');
  }
}

class DatabasePool {
  final int maxConnections;
  List<String> _connections = [];

  DatabasePool({required this.maxConnections}) {
    print('✓ DatabasePool created (max connections: $maxConnections)');
    _connections = List.generate(maxConnections, (i) => 'connection_$i');
  }

  String getConnection() {
    if (_connections.isEmpty) throw Exception('No connections available');
    return _connections.removeAt(0);
  }

  void releaseConnection(String connection) {
    _connections.add(connection);
  }
}

class Logger {
  final String name;

  Logger(this.name) {
    print('✓ Logger created (name: $name)');
  }

  void log(String message) {
    print('  [$name] $message');
  }
}

class NotificationService {
  late final ApiClient _apiClient;
  late final Logger _logger;

  NotificationService() {
    print('✓ NotificationService created');
  }

  void injectDependencies(ApiClient apiClient, Logger logger) {
    _apiClient = apiClient;
    _logger = logger;
    print('  NotificationService: dependencies injected');
  }

  Future<void> sendNotification(String userId, String message) async {
    _logger.log('Sending notification to $userId');
    final response = await _apiClient.request('/notifications/send');
    _logger.log('Notification response: $response');
  }
}

// ============ Factory Setup ============

void setupFactories() {
  print('Registering factories...\n');

  // Register factory for ApiClient
  SingletonDI.registerFactory<ApiClient>(
    () => ApiClient('https://api.example.com'),
  );
  print('  Factory registered: ApiClient');

  // Register factory for AppConfig
  SingletonDI.registerFactory<AppConfig>(
    () => AppConfig(
      appName: 'MyApp',
      environment: 'production',
      apiBaseUrl: 'https://api.example.com',
    ),
  );
  print('  Factory registered: AppConfig');

  // Register factory for DatabasePool
  SingletonDI.registerFactory<DatabasePool>(
    () => DatabasePool(maxConnections: 10),
  );
  print('  Factory registered: DatabasePool');

  // Register factory for Logger
  SingletonDI.registerFactory<Logger>(
    () => Logger('App'),
  );
  print('  Factory registered: Logger');

  // Register factory for NotificationService
  SingletonDI.registerFactory<NotificationService>(
    () => NotificationService(),
  );
  print('  Factory registered: NotificationService');

  print('Total factories: ${SingletonDI.factoryCount}\n');
}

// ============ DI Container using Factories ============

class DIContainer {
  final Map<Type, Object> _instances = {};

  Future<T> get<T extends Object>() async {
    // Return existing singleton if already created
    if (_instances.containsKey(T)) {
      return _instances[T] as T;
    }

    // Create singleton from factory
    final factory = SingletonDI.getFactory<T>();
    if (factory == null) {
      throw StateError('No factory registered for type $T');
    }

    print('Creating singleton for $T...');
    final instance = factory();

    // Special initialization for NotificationService
    if (instance is NotificationService) {
      final apiClient = await get<ApiClient>();
      final logger = await get<Logger>();
      instance.injectDependencies(apiClient, logger);
    }

    _instances[T] = instance;
    return instance;
  }

  int get instanceCount => _instances.length;

  void printInstances() {
    print('\nSingleton instances:');
    for (final entry in _instances.entries) {
      print('  - ${entry.key}: ${entry.value.runtimeType}');
    }
  }
}

// ============ Application ============

void main() async {
  print('=== SingletonDI Factory Pattern ===\n');

  // Step 1: Register all factories
  setupFactories();

  // Step 2: Create DI container
  print('Step 1: Create DI container');
  final container = DIContainer();
  print('Container created\n');

  // Step 3: Request services (lazy creation)
  print('Step 2: Request services (lazy initialization)');
  print('Getting AppConfig...');
  final config = await container.get<AppConfig>();
  print('');

  print('Getting ApiClient...');
  final apiClient = await container.get<ApiClient>();
  print('');

  print('Getting DatabasePool...');
  final dbPool = await container.get<DatabasePool>();
  print('');

  print('Getting Logger...');
  final logger = await container.get<Logger>();
  print('');

  // Step 4: Request again (gets cached instance)
  print('Step 3: Request again (cached instances)');
  final config2 = await container.get<AppConfig>();
  print('Same instance: ${identical(config, config2)}\n');

  // Step 5: Use services
  print('Step 4: Use services');
  logger.log('Application started');
  final response = await apiClient.request('/status');
  print('API response: $response\n');

  // Step 6: Service with dependencies
  print('Step 5: Service with dependencies');
  print('Getting NotificationService...');
  final notificationService = await container.get<NotificationService>();
  print('');

  print('Using NotificationService...');
  await notificationService.sendNotification('user123', 'Hello!');
  print('');

  // Step 7: Summary
  print('Step 6: Summary');
  container.printInstances();
  print('Total instances: ${container.instanceCount}');
  print('Registered factories: ${SingletonDI.factoryCount}\n');

  // Step 8: Clear
  print('Step 7: Clear factories');
  SingletonDI.clearFactories();
  print('Factories cleared: ${SingletonDI.factoryCount}');
}
