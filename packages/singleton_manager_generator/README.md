# singleton_manager_generator

A CLI tool that generates Dart DI files for `@isSingleton` classes, automatically implementing dependency injection setup.

## Features

- Scans Dart source files for `@isSingleton` and `@isInjected` annotations
- Generates `extends`-based DI classes implementing `ISingletonStandardDI`
- Creates `initializeDI()` factory for pure container-resolved singletons
- Creates `initializeWithParametersDI()` factory for singletons with mandatory/optional parameters
- Named constructor `.emptyForDI()` avoids conflicts with the parent class default constructor
- Supports `@isMandatoryParameter` and `@isOptionalParameter` on both constructor params and fields
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

  MyServiceDI.emptyForDI() : super();

  factory MyServiceDI.initializeDI() {
    final instance = MyServiceDI.emptyForDI();
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

> **Note**: since v1.3.0 the generated class uses the named constructor `.emptyForDI()` instead of the default constructor, to avoid conflicts when the parent class defines its own default constructor.

Use it in your code:

```dart
// Set up dependencies
SingletonDIAccess.set<DatabaseConnection>(myConnection);
SingletonDIAccess.set<Logger>(myLogger);

// Create singleton with auto-injected dependencies
final service = MyServiceDI.initializeDI();
```

## Advanced Annotations

### Constructor parameters

Annotate constructor parameters to expose them in the generated `initializeWithParametersDI()` factory:

```dart
@isSingleton
class ApiService {
  ApiService({
    @isMandatoryParameter required String baseUrl,
    @isOptionalParameter String? timeout,
  });

  @isInjected
  late Logger logger;
}
```

Generated:

```dart
class ApiServiceDI extends ApiService implements ISingletonStandardDI {

  ApiServiceDI({required String baseUrl, String? timeout}) : super(baseUrl: baseUrl, timeout: timeout);

  factory ApiServiceDI.initializeWithParametersDI(String baseUrl, {String? timeout}) {
    final instance = ApiServiceDI(baseUrl: baseUrl, timeout: timeout);
    instance.logger = SingletonDIAccess.get<Logger>();
    return instance;
  }

  @override
  void initializeDI() {
    logger = SingletonDIAccess.get<Logger>();
  }
}
```

### Field annotations

| Annotation | Effect in `initializeDI()` | Effect in `initializeWithParametersDI()` |
|---|---|---|
| `@isInjected` | `field = SingletonDIAccess.get<T>()` | fetched from container |
| `@isMandatoryParameter` | `field = SingletonDIAccess.get<T>()` | required positional parameter |
| `@isOptionalParameter` | `if (exists<T>()) field = get<T>()` | nullable named parameter `{T? field}` |

> Fields annotated with `@isOptionalParameter` should use a nullable type (e.g., `IMyService?`).

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
