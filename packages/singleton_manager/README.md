# singleton_manager

[![Pub Version](https://img.shields.io/pub/v/singleton_manager.svg)](https://pub.dev/packages/singleton_manager)

A high-performance, zero-dependency singleton manager for Dart.

## Features

- **Type-safe**: Full generic support with compile-time type checking
- **High performance**: O(1) registration and retrieval operations
- **Zero dependencies**: No external package dependencies
- **Lazy loading**: Initialize singletons only when first accessed
- **Multi-platform**: Supports VM, Web, Native, and Flutter
- **Pure Dart**: No platform-specific code required

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  singleton_manager: ^0.1.0
```

## Quick Start

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
