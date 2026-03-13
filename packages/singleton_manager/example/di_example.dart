// ignore_for_file: avoid_print, one_member_abstracts
import 'package:singleton_manager/singleton_manager.dart';

/// Example service interface
abstract interface class IUserRepository
    implements ISingleton<dynamic, dynamic> {
  Future<String> getUser(int id);
}

/// Example implementation
class UserRepository implements IUserRepository, ISingleton<dynamic, void> {
  UserRepository() {
    print('UserRepository created');
  }

  static int instanceCount = 0;

  @override
  Future<String> getUser(int id) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    return 'User $id';
  }

  @override
  Future<void> initialize(dynamic input) async {
    print('UserRepository initialized with input: $input');
  }

  @override
  Future<void> initializeDI() async {
    instanceCount++;
    print('UserRepository DI initialization #$instanceCount');
  }
}

/// Another service that depends on UserRepository
class UserService implements ISingleton<dynamic, void> {
  UserService() {
    print('UserService created');
  }

  late IUserRepository repository;

  @override
  Future<void> initialize(dynamic input) async {
    print('UserService initialized with input: $input');
  }

  @override
  Future<void> initializeDI() async {
    print('UserService resolving dependencies...');
    // Get the repository from the singleton manager
    repository =
        SingletonManager.instance.getInstance<IUserRepository>();
    print('UserService initialized with repository');
  }

  Future<String> getUserInfo(int id) => repository.getUser(id);
}

void main() async {
  final manager = SingletonManager.instance;

  // Step 1: Register factories
  print('=== Step 1: Register Factories ===');
  SingletonDI.registerFactory<UserRepository>(UserRepository.new);
  SingletonDI.registerFactory<UserService>(UserService.new);
  print('Factories registered: ${SingletonDI.factoryCount}\n');

  // Step 2: Register by type
  print('=== Step 2: Register UserRepository by Type ===');
  await manager.add<UserRepository>();
  print('UserRepository registered\n');

  // Step 3: Register implementation with interface as key
  print('=== Step 3: Register UserRepository with IUserRepository ===');
  await manager.addAs<IUserRepository, UserRepository>();
  print('UserRepository registered as IUserRepository\n');

  // Step 4: Register another service that depends on the first
  print('=== Step 4: Register UserService ===');
  await manager.add<UserService>();
  print('UserService registered\n');

  // Step 5: Retrieve and use
  print('=== Step 5: Use the Services ===');
  final userService = manager.get<UserService>();
  final user = await userService.getUserInfo(123);
  print('Got user: $user\n');

  // Step 6: Verify we get the same instance (singleton)
  print('=== Step 6: Verify Singleton Behavior ===');
  final userService2 = manager.get<UserService>();
  print('Same instance: ${identical(userService, userService2)}\n');

  // Step 7: Access via interface
  print('=== Step 7: Access via Interface ===');
  final repo = manager.get<IUserRepository>();
  final user2 = await repo.getUser(456);
  print('Got user via interface: $user2\n');

  // Step 8: Remove singleton
  print('=== Step 8: Remove Services ===');
  manager.remove<UserService>();
  print('UserService removed\n');

  // Step 9: Clear factories
  print('=== Step 9: Clear Factories ===');
  SingletonDI.clearFactories();
  print('Factories cleared: ${SingletonDI.factoryCount}');
}
