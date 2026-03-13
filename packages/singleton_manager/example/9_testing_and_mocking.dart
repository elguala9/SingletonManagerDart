// ignore_for_file: avoid_print,unused_field,file_names,one_member_abstracts,sort_constructors_first,always_put_control_body_on_new_line,lines_longer_than_80_chars,cascade_invocations
import 'package:singleton_manager/singleton_manager.dart';

/// Example 9: Testing and Mocking Patterns
///
/// Shows how to use singleton_manager effectively in tests:
/// - Mocking services
/// - Replacing with test doubles
/// - Cleaning up between tests
/// - Testing service composition

// ============ Production Interfaces and Implementations ============

abstract interface class IEmailService {
  Future<void> sendEmail(String to, String subject, String body);
}

abstract interface class IUserRepository implements ISingleton<dynamic, dynamic> {
  Future<Map<String, dynamic>> getUserById(String id);
}

class ProductionEmailService implements IEmailService, IValueForRegistry {
  @override
  Future<void> sendEmail(String to, String subject, String body) async {
    print('  [REAL] Sending email to $to: $subject');
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  void destroy() {
    print('  ProductionEmailService destroyed');
  }
}

class ProductionUserRepository implements IUserRepository, IValueForRegistry {
  @override
  Future<Map<String, dynamic>> getUserById(String id) async {
    print('  [REAL] Fetching user $id from database');
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return {'id': id, 'name': 'John Doe', 'email': 'john@example.com'};
  }

  @override
  Future<void> initialize(dynamic input) async {}

  @override
  Future<void> initializeDI() async {}

  @override
  void destroy() {
    print('  ProductionUserRepository destroyed');
  }
}

// ============ Mock Implementations ============

class MockEmailService implements IEmailService, IValueForRegistry {
  List<({String to, String subject, String body})> sentEmails = [];

  @override
  Future<void> sendEmail(String to, String subject, String body) async {
    print('  [MOCK] Email queued to $to: $subject');
    sentEmails.add((to: to, subject: subject, body: body));
    // Instant response for tests
    await Future<void>.value();
  }

  int get emailCount => sentEmails.length;

  bool hasEmailTo(String to) => sentEmails.any((e) => e.to == to);

  @override
  void destroy() {
    print('  MockEmailService destroyed');
  }
}

class MockUserRepository implements IUserRepository, IValueForRegistry {
  final Map<String, Map<String, dynamic>> _users = {
    '1': {'id': '1', 'name': 'Alice', 'email': 'alice@test.com'},
    '2': {'id': '2', 'name': 'Bob', 'email': 'bob@test.com'},
  };

  @override
  Future<Map<String, dynamic>> getUserById(String id) async {
    print('  [MOCK] Getting user $id from mock repository');
    final user = _users[id];
    if (user == null) throw Exception('User not found');
    // Instant response for tests
    await Future<void>.value();
    return user;
  }

  void addUser(String id, Map<String, dynamic> userData) {
    _users[id] = userData;
  }

  @override
  Future<void> initialize(dynamic input) async {}

  @override
  Future<void> initializeDI() async {}

  @override
  void destroy() {
    print('  MockUserRepository destroyed');
  }
}

// ============ Service Using Dependencies ============

class NotificationService implements IValueForRegistry {
  late final IEmailService _emailService;
  late final IUserRepository _userRepository;

  NotificationService() {
    print('  NotificationService created');
  }

  void setDependencies(IEmailService email, IUserRepository users) {
    _emailService = email;
    _userRepository = users;
    print('  NotificationService: dependencies injected');
  }

  Future<void> notifyUser(String userId, String message) async {
    final user = await _userRepository.getUserById(userId);
    final email = user['email'] as String;
    await _emailService.sendEmail(email, 'Notification', message);
  }

  @override
  void destroy() {
    print('  NotificationService destroyed');
  }
}

// ============ Test Service Registry ============

class TestServiceRegistry with Registry<Type, IValueForRegistry> {
  void setupProduction() {
    print('\n--- Setting up PRODUCTION services ---');
    register(IEmailService, ProductionEmailService());
    register(IUserRepository, ProductionUserRepository());
  }

  void setupTest() {
    print('\n--- Setting up TEST (mocked) services ---');
    register(IEmailService, MockEmailService());
    register(IUserRepository, MockUserRepository());
  }

  void setupMixed() {
    print('\n--- Setting up MIXED (some real, some mock) ---');
    register(IEmailService, MockEmailService()); // Mock for fast tests
    register(IUserRepository, ProductionUserRepository()); // Real for integration
  }

  void setupNotificationService() {
    final notificationService = NotificationService();
    notificationService.setDependencies(
      getInstance(IEmailService) as IEmailService,
      getInstance(IUserRepository) as IUserRepository,
    );
    register(NotificationService, notificationService);
  }

  T getService<T>() => getInstance(T) as T;

  Future<void> teardown() async {
    print('\n--- Cleaning up ---');
    destroyAll();
  }
}

// ============ Test Examples ============

Future<void> testWithProduction() async {
  print('\n=== TEST 1: Production Services ===');
  final registry = TestServiceRegistry();
  registry.setupProduction();

  registry.setupNotificationService();
  final service = registry.getService<NotificationService>();

  print('\nExecuting test...');
  await service.notifyUser('1', 'Welcome!');

  await registry.teardown();
}

Future<void> testWithMocks() async {
  print('\n=== TEST 2: Mock Services (Fast) ===');
  final registry = TestServiceRegistry();
  registry.setupTest();

  registry.setupNotificationService();
  final service = registry.getService<NotificationService>();

  print('\nExecuting test...');
  await service.notifyUser('1', 'Welcome!');
  await service.notifyUser('2', 'Hello!');

  // Verify mock behavior
  final emailService = registry.getService<MockEmailService>();
  print('\nVerifications:');
  print('  Emails sent: ${emailService.emailCount}');
  print('  Email to alice@test.com sent: ${emailService.hasEmailTo("alice@test.com")}');

  await registry.teardown();
}

Future<void> testWithMixedSetup() async {
  print('\n=== TEST 3: Mixed Setup (Mock emails, Real database) ===');
  final registry = TestServiceRegistry();
  registry.setupMixed();

  registry.setupNotificationService();
  final service = registry.getService<NotificationService>();

  print('\nExecuting test...');
  await service.notifyUser('2', 'Important update');

  // Verify mock email service
  final emailService = registry.getService<MockEmailService>();
  print('\nVerifications:');
  print('  Mock emails captured: ${emailService.emailCount}');

  await registry.teardown();
}

Future<void> testReplacingService() async {
  print('\n=== TEST 4: Replacing Services During Test ===');
  final registry = TestServiceRegistry();

  print('\n--- Initial setup with real email ---');
  registry.register(IEmailService, ProductionEmailService());

  print('\n--- Switching to mock for specific test ---');
  final mockEmail = MockEmailService();
  registry.replace(IEmailService, mockEmail);

  print('\nUsing mocked service...');
  final emailService = registry.getService<IEmailService>();
  await emailService.sendEmail('test@test.com', 'Test', 'Testing');

  print('\nVerifying mock was used:');
  print('  Emails captured: ${mockEmail.emailCount}');

  await registry.teardown();
}

// ============ Main ============

void main() async {
  print('=== Testing and Mocking Patterns ===');

  // Run all test scenarios
  await testWithProduction();
  await testWithMocks();
  await testWithMixedSetup();
  await testReplacingService();

  print('\n✓ All test examples completed');
}
