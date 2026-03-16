# singleton_manager_generator

A CLI tool that generates Dart augmentation files for `@isSingleton` classes, automatically implementing dependency injection setup.

## Features

- Scans Dart source files for `@isSingleton` and `@isInjected` annotations
- Generates augmentation files with `ISingletonStandardDI` implementations
- Creates `initializeDI()` factory methods for each singleton class
- Supports multiple injected fields per class
- Minimal overhead - uses Dart's `analyzer` package for lightweight AST parsing

## Installation

Add both packages to your `pubspec.yaml`:

```yaml
dependencies:
  singleton_manager: any
  singleton_manager_annotations: any

dev_dependencies:
  singleton_manager_generator: any
```

## Usage

### 1. Annotate your classes

```dart
import 'package:singleton_manager_annotations/singleton_manager_annotations.dart';

@isSingleton
class MyService {
  @isInjected
  late DatabaseConnection db;

  @isInjected
  late Logger logger;
}
```

### 2. Run the generator

```bash
dart run singleton_manager_generator --input lib/src --output lib/generated
```

Or use melos if set up in your workspace:

```bash
melos run generate
```

### 3. Use the generated code

The generator creates augmentation files (e.g., `my_service_augment.dart`) with:

```dart
augment class MyService implements ISingletonStandardDI {
  factory MyService.initializeDI() {
    final instance = MyService();
    instance.initializeDI();
    return instance;
  }

  @override
  void initializeDI() {
    db = SingletonDIAccess.get<DatabaseConnection>();
    logger = SingletonDIAccess.get<Logger>();
  }
}
```

Use it in your code:

```dart
// Set up dependencies
SingletonDIAccess.set<DatabaseConnection>(myConnection);
SingletonDIAccess.set<Logger>(myLogger);

// Create singleton with auto-injected dependencies
final service = MyService.initializeDI();
```

## CLI Options

```
--input, -i       Input directory containing source Dart files (default: lib)
--output, -o      Output directory for generated augmentation files (default: input)
--verbose, -v     Enable verbose logging
--help, -h        Show help message
```

## Requirements

- Dart SDK >= 3.11.0
- `package:analyzer` for AST parsing
- `package:args` for CLI argument handling
- `package:path` for path utilities

## How it works

1. **Parsing**: Scans Dart files using the `analyzer` package to find AST nodes
2. **Annotation Detection**: Identifies classes with `@isSingleton` metadata and fields with `@isInjected` metadata
3. **Code Generation**: Creates augmentation files that implement `ISingletonStandardDI`
4. **Output**: Writes `.singleton_di.dart` files alongside the original source

## Example Project

See the root project's test files for examples of usage.
