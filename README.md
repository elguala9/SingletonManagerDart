# Singleton Manager

[![Pub Version](https://img.shields.io/pub/v/singleton_manager.svg)](https://pub.dev/packages/singleton_manager)
[![Dart CI](https://github.com/elguala9/SingletonManagerDart/workflows/CI/badge.svg)](https://github.com/elguala9/SingletonManagerDart/actions)
[![codecov](https://codecov.io/gh/elguala9/SingletonManagerDart/branch/main/graph/badge.svg)](https://codecov.io/gh/elguala9/SingletonManagerDart)

A high-performance, zero-dependency singleton manager for Dart with:

- **Type-safe**: Full generic support with compile-time type checking
- **High performance**: O(1) registration and retrieval operations
- **Zero dependencies**: No external package dependencies
- **Lazy loading**: Initialize singletons only when first accessed
- **Scope management**: Optional support for scoped singletons
- **Multi-platform**: Supports VM, Web, Native, and Flutter
- **Pure Dart**: No platform-specific code required

## Packages

This is a monorepo containing:

### [singleton_manager](packages/singleton_manager)
Core library providing singleton registration, retrieval, and lifecycle management.

- **Publishable** on pub.dev
- **Zero dependencies**
- **Production-ready**

### [singleton_manager_test](packages/singleton_manager_test)
Comprehensive test suite and utilities for `singleton_manager`.

- **Not publishable** (internal test package)
- **Includes fixtures and helpers**
- **Full coverage validation**

## Quick Start

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  singleton_manager: ^0.3.1
```

## Features (v0.3.2+)

### Core Features

- **Type-Safe Registration**: Generic support with compile-time type checking
- **Factory-Based DI**: Register factory functions via `SingletonDI`
- **Instance-Based Registration**: Register pre-configured objects (v0.3.0+)
- **Static API Access**: Simplified `SingletonDIAccess` for static method access (v0.3.0+)
- **Lifecycle Management**: `ISingleton` interface for initialization/cleanup
- **Zero Dependencies**: No external package dependencies

### Dependency Injection with SingletonDI and SingletonDIAccess

Register factories and use type-safe extension methods:

```dart
// Register factories
SingletonDI.registerFactory<MyService>(() => MyService());
SingletonDI.registerFactory<RepositoryImpl>(() => RepositoryImpl());

// Register by type (factory-based)
final manager = SingletonManager.instance;
await manager.add<MyService>();

// Register with interface (factory-based)
await manager.addAs<IRepository, RepositoryImpl>();

// Register pre-configured instance (v0.3.0+)
final service = MyService();
await manager.addInstance<MyService>(service);

// Register instance with interface (v0.3.0+)
final repo = RepositoryImpl();
await manager.addInstanceAs<IRepository, RepositoryImpl>(repo);

// Retrieve
final service = manager.get<MyService>();

// Remove
manager.remove<MyService>();

// Or use static API without instance (v0.3.0+)
await SingletonDIAccess.add<MyService>();
final svc = SingletonDIAccess.get<MyService>();
SingletonDIAccess.remove<MyService>();
```

### Lifecycle Management with ISingleton

Implement `ISingleton` for initialization and cleanup:

```dart
class MyService implements ISingleton<dynamic, void> {
  @override
  Future<void> initialize(dynamic input) async {
    // Called by manager.register() with custom input
  }

  @override
  Future<void> initializeDI() async {
    // Called by manager.add() - great for DI setup
  }
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

### Scoped Singletons (Advanced)

```dart
// Create scope for request handling
final scope = manager.createScope();
scope.register('requestId', () => Uuid().v4());

// Singletons in scope are isolated
final id1 = scope.get('requestId');
final id2 = scope.get('requestId'); // Same ID

// Cleanup when done
scope.clear();
```

## Comparison & Use Cases

### When to Use SingletonManager

| Scenario | Use Case |
|----------|----------|
| **Service Locator** | Register and retrieve services globally |
| **Dependency Injection** | Use with `SingletonDI` for factory-based DI |
| **Testing** | Pre-configure instances for controlled testing |
| **Scoped Resources** | Isolate singletons per request/scope |

### DI Patterns

**Factory-Based (v0.2.0+)**
- Define factories upfront
- Lazy instantiation
- Good for complex initialization logic

**Instance-Based (v0.3.0+)**
- Pre-configure objects
- Better for testing
- Direct control over instantiation

**Static API (v0.3.0+)**
- No need to manage manager instance
- Cleaner code in utility functions
- Ideal for small/medium projects

## Best Practices

1. **Define Interfaces**: Use `ISingleton` for lifecycle management
   ```dart
   class MyService implements ISingleton<dynamic, void> {
     @override
     Future<void> initializeDI() async => print('Initialized');
   }
   ```

2. **Register Factories Early**: Before using `add<T>()`
   ```dart
   SingletonDI.registerFactory<MyService>(() => MyService());
   ```

3. **Use Scopes for Isolation**: For request-scoped data
   ```dart
   final scope = manager.createScope();
   // Isolated singletons in scope
   scope.clear(); // Cleanup
   ```

4. **Prefer Static API**: For simpler use cases (v0.3.0+)
   ```dart
   await SingletonDIAccess.add<MyService>();
   final svc = SingletonDIAccess.get<MyService>();
   ```

## Examples

See the [examples directory](packages/singleton_manager/example) for complete working examples:

- **00-basic.dart**: Basic singleton registration and retrieval
- **01-lazy-loading.dart**: Lazy-loaded singletons
- **02-di.dart**: Dependency injection with factories
- **10-static-access.dart**: Static API access patterns
- **11-singleton_di_access_static_methods.dart**: Advanced static API with instance-based registration

## Development

### Setup

```bash
# Clone repository
git clone https://github.com/elguala9/SingletonManagerDart.git
cd SingletonManagerDart

# Install Melos
dart pub global activate melos

# Bootstrap workspace
melos bootstrap
```

### Running Tests

```bash
# All tests
melos run test

# Unit tests only
melos run test:unit

# With coverage
melos run test:coverage

# Verbose output
melos run test:verbose
```

### Code Quality

```bash
# Analyze code
melos run analyze

# Check formatting
melos run format:check

# Fix formatting
melos run format

# Quick check (analyze + unit tests)
melos run check

# Complete CI pipeline
melos run ci
```

## Architecture

See [packages/singleton_manager/doc/architecture.md](packages/singleton_manager/doc/architecture.md) for detailed architectural documentation.

## Publishing

### Prerequisites

1. Pub.dev account (create at https://pub.dev)
2. Configure authentication:
   ```bash
   dart pub login
   ```

### Process

```bash
# Verify publication will work (dry run)
melos run publish:dry-run

# Actual publication
melos run publish
```

See [PUBLISHING.md](PUBLISHING.md) for detailed instructions.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Author

Luca Gualandi
- GitHub: [@elguala9](https://github.com/elguala9)
- Pub.dev: [singleton_manager](https://pub.dev/packages/singleton_manager)
