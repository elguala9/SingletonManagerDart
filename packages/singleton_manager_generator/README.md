# singleton_manager_generator

A CLI tool that generates Dart DI files for `@isSingleton` classes, automatically implementing dependency injection setup.

## Features

- Scans Dart source files for `@isSingleton` and `@isInjected` annotations
- Generates `extends`-based DI classes implementing `ISingletonStandardDI`
- Creates `initializeDI()` factory methods for each singleton class
- Supports multiple injected fields per class
- Minimal overhead - uses Dart's `analyzer` package for lightweight AST parsing

## Installation

Add the packages to your `pubspec.yaml`:

```yaml
dependencies:
  singleton_manager: ^1.0.0

dev_dependencies:
  singleton_manager_generator: ^2.0.0
```

Note: Annotations are included in `singleton_manager` v1.0.0+. No separate annotations package needed!

### Global Installation

To install `singleton_manager_generator` globally and use it across multiple projects:

```bash
dart pub global activate singleton_manager_generator
```

Then use it directly from anywhere:

```bash
singleton_manager_generator --input lib/src --output lib/generated
```

To update the global installation:

```bash
dart pub global activate singleton_manager_generator
```

To deactivate the global installation:

```bash
dart pub global deactivate singleton_manager_generator
```

## Usage

### 1. Annotate your classes

```dart
import 'package:singleton_manager/singleton_manager.dart';

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

The generator creates a DI file (e.g., `my_service_di.dart`) with:

```dart
class MyServiceDI extends MyService implements ISingletonStandardDI {
  factory MyServiceDI.initializeDI() {
    final instance = MyServiceDI();
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
final service = MyServiceDI.initializeDI();
```

## CLI Options

```
--input, -i       Input directory containing source Dart files (default: lib)
--output, -o      Output directory for generated DI files (default: input)
--verbose, -v     Enable verbose logging
--help, -h        Show help message
```

## Requirements

- Dart SDK >= 3.11.0
- `package:singleton_manager` ^1.0.0 (for annotations)
- `package:analyzer` ^10.0.0 for AST parsing
- `package:args` ^2.5.0 for CLI argument handling
- `package:path` ^1.9.0 for path utilities

## How it works

1. **Parsing**: Scans Dart files using the `analyzer` package to find AST nodes
2. **Annotation Detection**: Identifies classes with `@isSingleton` metadata and fields with `@isInjected` metadata
3. **Code Generation**: Creates `extends`-based DI classes that implement `ISingletonStandardDI`
4. **Output**: Writes `_di.dart` files alongside the original source

## Example Project

See the root project's test files for examples of usage.
