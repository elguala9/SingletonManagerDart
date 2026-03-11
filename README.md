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
  singleton_manager: ^0.1.0
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
