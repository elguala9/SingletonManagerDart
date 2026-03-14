# singleton_manager

[![Pub Version](https://img.shields.io/pub/v/singleton_manager.svg)](https://pub.dev/packages/singleton_manager)

A high-performance, zero-dependency singleton manager for Dart.

## Features

- **Type-safe**: Full generic support with compile-time type checking
- **High performance**: O(1) registration and retrieval operations
- **Zero dependencies**: No external package dependencies
- **Dependency Injection**: Factory-based DI with `SingletonDI` and static access with `SingletonDIAccess` (v0.2.0+, enhanced v0.3.0+)
- **Lifecycle Management**: `ISingleton` interface for initialization and cleanup
- **Lazy loading**: Initialize singletons only when first accessed
- **Multi-platform**: Supports VM, Web, Native, and Flutter
- **Pure Dart**: No platform-specific code required

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  singleton_manager: ^0.3.1
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
  Future<void> initializeDI() async => print('di init');
}

void main() async {
  // 2. Register factory (factory-based DI)
  SingletonDI.registerFactory<UserService>(UserService.new);
  final manager = SingletonManager.instance;
  await manager.add<UserService>();

  // OR register pre-configured instance (v0.3.0+)
  final userService = UserService();
  await manager.addInstance<UserService>(userService);

  // 3. Get service
  final service = manager.get<UserService>();

  // OR use static API (v0.3.0+)
  SingletonDI.registerFactory<UserService>(UserService.new);
  await SingletonDIAccess.add<UserService>();
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

## Documentation

For more information, see the [main project documentation](../../README.md).

## Contributing

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for contribution guidelines.

## License

MIT License - see [LICENSE](../../LICENSE) file for details.
