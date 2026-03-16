# singleton_manager

[![Pub Version](https://img.shields.io/pub/v/singleton_manager.svg)](https://pub.dev/packages/singleton_manager)

A high-performance, zero-dependency singleton manager for Dart with built-in code generation annotations.

## Features

- **Type-safe**: Full generic support with compile-time type checking
- **High performance**: O(1) registration and retrieval operations
- **Zero runtime dependencies**: No external package dependencies
- **Flexible API**: Register any Dart objects, not just `ISingleton` implementations (v0.3.3+)
- **Dependency Injection**: Factory-based DI with `SingletonDI` and static access with `SingletonDIAccess` (v0.2.0+, enhanced v0.3.0+)
- **Code Generation Annotations** (v0.4.0+): Built-in `@isSingleton` and `@isInjected` annotations for automatic DI setup
- **Optional Lifecycle Management**: `ISingleton` interface for initialization and cleanup (optional, v0.2.0+)
- **Lazy loading**: Initialize singletons only when first accessed
- **Multi-platform**: Supports VM, Web, Native, and Flutter
- **Pure Dart**: No platform-specific code required

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  singleton_manager: ^0.4.0
```

## Quick Start

### Dependency Injection (v0.2.0+, v0.3.0 enhancements)

```dart
import 'package:singleton_manager/singleton_manager.dart';

// 1. Define your service
class UserService implements ISingleton<dynamic, void> {
  @override
  Future<void> initialize(dynamic input) async => print('init');

  @override
  void initializeDI() => print('di init');
}

void main() {
  // 2. Register factory (factory-based DI)
  SingletonDI.registerFactory<UserService>(UserService.new);
  final manager = SingletonManager.instance;
  manager.add<UserService>();

  // OR register pre-configured instance (v0.3.0+)
  final userService = UserService();
  manager.addInstance<UserService>(userService);

  // 3. Get service
  final service = manager.get<UserService>();

  // OR use static API (v0.3.0+)
  SingletonDI.registerFactory<UserService>(UserService.new);
  SingletonDIAccess.add<UserService>();
  final svc = SingletonDIAccess.get<UserService>();
}
```

### Basic Usage

```dart
import 'package:singleton_manager/singleton_manager.dart';

void main() {
  // Create a manager
  final manager = SingletonManager<String>();

  // Register a singleton
  manager.register('myService', () => MyService());

  // Retrieve it (same instance always)
  final service = manager.get('myService'); // Returns MyService
  final serviceSame = manager.get('myService'); // Same instance
}

class MyService {
  void doSomething() => print('Hello from Service!');
}
```

### Lazy Loading

```dart
// Singleton only created when first accessed
manager.registerLazy('expensiveService',
  () => ExpensiveResourceService()
);
```

### Code Generation with Annotations (v0.4.0+)

Use `@isSingleton` and `@isInjected` annotations with `singleton_manager_generator` for automatic DI setup:

```dart
@isSingleton
class UserService {
  @isInjected
  late DatabaseConnection db;

  @isInjected
  late Logger logger;
}

void main() {
  // Register dependencies
  SingletonDI.registerFactory<DatabaseConnection>(() => DatabaseConnection());
  SingletonDI.registerFactory<Logger>(() => Logger());

  // Generator creates initializeDI() factory automatically
  final service = UserService.initializeDI();
}
```

See [singleton_manager_generator](../singleton_manager_generator/README.md) for setup instructions.

## Documentation

For more information, see the [main project documentation](../../README.md).

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.

## License

MIT License - see [LICENSE](../../LICENSE) file for details.
