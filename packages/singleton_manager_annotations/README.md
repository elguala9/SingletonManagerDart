# singleton_manager_annotations

Lightweight runtime annotations for the Dart singleton manager framework.

## Features

- `@isSingleton` - Mark classes that require automatic DI setup generation
- `@isInjected` - Mark fields that should be injected by the DI container
- Zero external dependencies - just annotations

## Usage

```dart
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';
import 'package:singleton_manager/singleton_manager.dart';

// Mark a class with @isSingleton
@isSingleton
class MyService {
  // Mark fields with @isInjected
  @isInjected
  late OtherService otherService;

  Future<void> doSomething() async {
    // Use injected service
    await otherService.performAction();
  }
}

// Provide the dependency in SingletonDIAccess
final service = SingletonDIAccess.set<OtherService>(OtherService());

// Use the singleton_manager_generator to create augmentation files
// Then create instances using the generated static factory
final myService = await MyService.create();
```

## With singleton_manager_generator

This package is designed to work with `singleton_manager_generator`, which automatically creates Dart augmentation files that implement `ISingletonStandardDI.initializeDI()` for all `@isSingleton` classes.

See `singleton_manager_generator` documentation for setup instructions.
