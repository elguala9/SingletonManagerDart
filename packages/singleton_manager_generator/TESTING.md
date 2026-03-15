# Testing Guide - singleton_manager_generator

Comprehensive test suite with 63 tests covering all aspects of the singleton manager generator.

## Running Tests

### Run all tests
```bash
dart test
```

### Run specific test file
```bash
dart test test/parser_test.dart
dart test test/generator_test.dart
dart test test/integration_test.dart
dart test test/model_test.dart
dart test test/cli_test.dart
```

### Run with verbose output
```bash
dart test --reporter expanded
```

### Run with coverage
```bash
dart test --coverage=coverage
```

## Test Organization

### 1. **parser_test.dart** (20 tests)
Tests the `SourceParser` class that scans Dart files for annotations.

**Key scenarios:**
- ✓ Single `@isSingleton` class with single `@isInjected` field
- ✓ Multiple `@isSingleton` classes in same file
- ✓ Multiple `@isInjected` fields per class
- ✓ Classes with no injected dependencies
- ✓ Ignoring non-singleton classes
- ✓ Generic field types (e.g., `List<String>`)
- ✓ Nullable field types (e.g., `String?`)
- ✓ Field modifiers (`late`, `final`)
- ✓ Recursive file discovery
- ✓ Syntax error handling (graceful recovery)
- ✓ Multiple files processing

**Example:**
```dart
@isSingleton
class MyService {
  @isInjected
  late DatabaseConnection db;

  @isInjected
  late Logger logger;
}
```

Parser correctly identifies:
- Class name: `MyService`
- 2 injected fields: `db`, `logger`
- Field types: `DatabaseConnection`, `Logger`

---

### 2. **generator_test.dart** (20 tests)
Tests the `AugmentationGenerator` class that creates augmentation file content.

**Key scenarios:**
- ✓ Single injected field → proper `SingletonDIAccess.get<T>()` call
- ✓ Multiple injected fields → all generated in correct order
- ✓ Empty classes (no injected fields) → `initializeDI()` exists but is empty
- ✓ Class names with underscores
- ✓ Field names with underscores (including private `_field`)
- ✓ Complex type names
- ✓ Windows-style path conversion (`\` → `/`)
- ✓ Proper indentation and formatting
- ✓ `@override` annotation presence
- ✓ `ISingletonStandardDI` interface implementation
- ✓ Static `create()` factory method with async/await
- ✓ Field ordering preservation
- ✓ Single-character class names
- ✓ Very long class names
- ✓ Class names with numbers

**Generated code example:**
```dart
augment class MyService implements ISingletonStandardDI {
  static Future<MyService> create() async {
    final instance = MyService();
    await instance.initializeDI();
    return instance;
  }

  @override
  Future<void> initializeDI() async {
    db = SingletonDIAccess.get<DatabaseConnection>();
    logger = SingletonDIAccess.get<Logger>();
  }
}
```

---

### 3. **integration_test.dart** (12 tests)
End-to-end tests combining parser and generator.

**Key scenarios:**
- ✓ Single singleton class → complete augmentation file
- ✓ Multiple files → all processed correctly
- ✓ Nested directory structures
- ✓ Classes with no dependencies
- ✓ Complex dependency chains (A → B → C → DB)
- ✓ Heavy services with 15+ injected fields
- ✓ Mixed singleton and regular classes
- ✓ Classes with constructors and methods
- ✓ Inheritance scenarios
- ✓ Source file path preservation in augment library

**Example: Complex dependency chain**
```dart
@isSingleton
class ServiceA {
  @isInjected
  late ServiceB serviceB;
}

@isSingleton
class ServiceB {
  @isInjected
  late ServiceC serviceC;
}

@isSingleton
class ServiceC {
  @isInjected
  late DatabaseConnection db;
}
```

All three generate correct augmentation files with proper dependency injection.

---

### 4. **model_test.dart** (5 tests)
Unit tests for data model classes.

**Coverage:**
- `InjectedFieldInfo` creation and properties
- `SingletonClassInfo` creation and properties
- Field order maintenance
- Large field lists (100+ fields)
- Path format handling (Windows vs Unix)
- toString() representations

---

### 5. **cli_test.dart** (6 tests)
Simulated CLI integration tests.

**Coverage:**
- File discovery and processing
- Multiple file handling
- Non-singleton class filtering
- Output filename format validation
- Verbose output behavior

---

## Test Statistics

| Test File | Count | Status |
|-----------|-------|--------|
| parser_test.dart | 20 | ✓ PASS |
| generator_test.dart | 20 | ✓ PASS |
| integration_test.dart | 12 | ✓ PASS |
| model_test.dart | 5 | ✓ PASS |
| cli_test.dart | 6 | ✓ PASS |
| **TOTAL** | **63** | **✓ PASS** |

## Edge Cases Covered

### Parser edge cases
- Empty Dart files
- Files with syntax errors
- Deeply nested classes
- Generic types with multiple type parameters
- Nullable types with `?`
- Private fields with `_` prefix
- Fields with both `late` and other modifiers

### Generator edge cases
- Classes with 0 injected fields
- Classes with 15+ injected fields
- Single-character identifiers
- Very long identifiers (100+ chars)
- Identifiers with numbers
- Windows path separators in file paths
- Relative and absolute paths

### Integration edge cases
- Files with multiple classes (only some are singletons)
- Inheritance hierarchies
- Classes with constructors and methods
- Circular dependency patterns (A → B → A)
- Mixed source and generated code

## Adding New Tests

When adding new tests:

1. **Identify the category:** Parser, Generator, Integration, Model, or CLI
2. **Create a temporary test directory:**
   ```dart
   late Directory tempDir;

   setUp(() {
     tempDir = Directory.systemTemp.createTempSync('test_name_');
   });

   tearDown(() {
     tempDir.deleteSync(recursive: true);
   });
   ```

3. **Write test cases with clear assertions:**
   ```dart
   test('should describe the behavior', () {
     // Arrange
     final input = /* ... */;

     // Act
     final result = /* ... */;

     // Assert
     expect(result, matches(expectation));
   });
   ```

4. **Test both happy path and edge cases**

## Debugging Tests

### Run a single test
```bash
dart test test/parser_test.dart -t "should find @isSingleton"
```

### Run with filtering
```bash
dart test -k "parser" # Run all tests with 'parser' in name
```

### Verbose output for debugging
```bash
dart test --reporter expanded test/parser_test.dart
```

## CI/CD Integration

The test suite is designed to be run in CI/CD pipelines:

```bash
# In melos
melos run test

# In GitHub Actions / CI
dart pub get
dart test --coverage=coverage
```

## Test Quality Metrics

- **Coverage:** Core parser and generator logic is thoroughly tested
- **Edge cases:** 15+ edge case scenarios covered
- **Error handling:** Graceful degradation tested
- **Performance:** Tests handle files with 100+ fields
- **Isolation:** Each test uses isolated temporary directories

## Known Limitations

1. **CLI tests are simulated** - They don't use actual `Process.run()` to avoid path issues in test environments. The real CLI is tested by running the generator manually.

2. **Type resolution** - The parser uses lightweight AST analysis without full type resolution. Complex generic types may be simplified.

3. **Syntax errors** - Only common syntax errors are tested. The parser relies on the Dart analyzer for complete validation.

## Future Test Enhancements

- [ ] Add performance benchmarks for large codebases
- [ ] Add tests for custom generator configurations
- [ ] Add tests for watch mode / file monitoring
- [ ] Add tests for incremental generation
- [ ] Add snapshot/goldenfile tests for generated output
