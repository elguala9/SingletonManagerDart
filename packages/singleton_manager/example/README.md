# Singleton Manager Examples

Comprehensive examples demonstrating all features of the `singleton_manager` package.

## Overview

This directory contains 10 progressively advanced examples showing how to use singleton_manager in different scenarios:

### 1. Basic Singleton Manager (`1_basic_singleton_manager.dart`)
**What it covers:**
- Simple Type-based singleton registration
- Using `SingletonManager` for basic patterns
- Register, retrieve, unregister, and clear operations
- Verifying singleton behavior (same instance)

**Key concepts:**
- `SingletonManager.instance` - static singleton accessor
- `register<T>(value)` - register by Type
- `getInstance<T>()` - retrieve by Type
- `unregister<T>()` - remove by Type

**When to use:**
- Simple applications with just a few singletons
- When you don't need key-value pairs or lazy loading
- Type-safe singleton pattern

---

### 2. Registry: Eager and Lazy Loading (`2_registry_eager_and_lazy.dart`)
**What it covers:**
- Key-value registry pattern with String keys
- Eager registration (create immediately)
- Lazy registration (create on first access)
- Service replacement with version tracking
- Registry queries (keys, size, contains)

**Key concepts:**
- `Registry<Key, Value>` mixin - flexible key-value registry
- `register(key, value)` - eager registration
- `registerLazy(key, factory)` - deferred initialization
- `replace(key, value)` / `replaceLazy(key, factory)` - update existing
- `getInstance(key)` - transparent lazy resolution
- `destroyAll()` - cleanup with destroy() calls

**When to use:**
- When you need string-based or enum-based keys
- For lazy loading of expensive resources
- Complex applications with many related services
- Hot-reload/hot-swap scenarios

---

### 3. Dependency Injection (`3_dependency_injection.dart`)
**What it covers:**
- Type-keyed DI container
- Interface-based service registration
- Constructor/method injection
- Service composition
- Async service usage

**Key concepts:**
- Type as registry key for interfaces/implementations
- Manual dependency injection
- Container pattern
- Proper cleanup with `destroyAll()`

**When to use:**
- Medium to large applications
- Services with multiple dependencies
- Test-friendly architecture
- Replacing implementations easily

---

### 4. Error Handling (`4_error_handling.dart`)
**What it covers:**
- `DuplicateRegistrationError` - prevent silent overwrites
- `RegistryNotFoundError` - safe access patterns
- Error handling with try-catch
- Safe pre-access checks with `contains()`
- Recovery from errors

**Key concepts:**
- Custom error types for clarity
- Using `replace()` for updates (not register again)
- Checking before accessing: `contains(key)`
- Lazy factory errors vs entry errors

**When to use:**
- Production-safe code
- Preventing bugs from duplicate registrations
- Robust error handling
- Defensive programming

---

### 5. Async Initialization (`5_async_initialization.dart`)
**What it covers:**
- `ISingleton<InitializeType, ReturnType>` interface
- Async initialization with `initializeDI()`
- Custom initialization with `initialize(input)`
- Services that need async setup (DB, files, APIs)
- Proper async/await patterns

**Key concepts:**
- `ISingleton` interface for async initialization
- Two-phase initialization: `initialize()` and `initializeDI()`
- Async resource setup
- Lifecycle management

**When to use:**
- Services requiring async initialization
- Database connections, file I/O, API calls
- Configuration loading
- Complex startup sequences

---

### 6. Version Tracking and Replacement (`6_version_tracking_and_replace.dart`)
**What it covers:**
- Version numbers for registered services
- Hot-reloading/hot-swapping services
- Tracking configuration changes
- Multiple replacements
- Mixed eager/lazy replacement

**Key concepts:**
- `ValueWithVersion<RegistryEntry<Value>>` internal structure
- Version increments on replace
- `getByKey()` for version access
- Old instance destruction on replace

**When to use:**
- Hot-reload scenarios
- Configuration updates at runtime
- A/B testing different implementations
- Dynamic service replacement

---

### 7. Complex Real-World Scenario (`7_complex_real_world_scenario.dart`)
**What it covers:**
- Multi-layer architecture (Data, Business, Presentation)
- Repository pattern
- Service composition
- Dependency graph
- Full application lifecycle

**Key concepts:**
- Data layer (Database, Repository)
- Business logic layer (Services)
- Presentation layer (Controllers)
- Dependency chain setup
- Proper initialization order

**When to use:**
- Real-world applications
- Learning best practices
- Understanding proper layering
- Complex dependency structures

---

### 8. SingletonDI Factory Pattern (`8_singleton_di_factory_pattern.dart`)
**What it covers:**
- `SingletonDI` global factory registry
- Registering factory functions
- Lazy singleton creation from factories
- Type-based factory lookup
- `getFactory<T>()` and `clearFactories()`

**Key concepts:**
- `SingletonDI.registerFactory<T>(factory)` - global registry
- `SingletonDI.getFactory<T>()` - retrieve factory
- `SingletonDI.clearFactories()` - cleanup
- `SingletonDI.factoryCount` - count registered

**When to use:**
- Large applications with many singletons
- Centralized factory configuration
- Delayed or complex singleton creation
- Plugin systems

---

### 9. Testing and Mocking (`9_testing_and_mocking.dart`)
**What it covers:**
- Mock implementations of services
- Replacing real services with mocks
- Testing with controlled dependencies
- Verification of mock calls
- Mixed production/mock setup
- Test cleanup

**Key concepts:**
- Mock implementations
- `replace()` for swapping implementations
- Verification patterns
- Test registry setup/teardown

**When to use:**
- Writing unit tests
- Mocking expensive operations (DB, network)
- Testing in isolation
- Integration tests with mixed components

---

### 10. Performance and Best Practices (`10_performance_and_best_practices.dart`)
**What it covers:**
- Lazy loading for expensive resources
- Resource pooling patterns
- Eager loading for critical services
- Batch operations
- Proper cleanup
- Error-safe operations
- Performance measurement

**Key concepts:**
- When to use lazy vs eager
- Resource pooling for connections
- Lifecycle management
- Batch registration
- Safe error handling

**When to use:**
- Learning best practices
- Optimizing application startup
- Resource management
- Performance-critical code

---

## Running the Examples

### Option 1: Run individual examples
```bash
cd packages/singleton_manager
dart run example/1_basic_singleton_manager.dart
dart run example/2_registry_eager_and_lazy.dart
# ... etc
```

### Option 2: Run all examples
```bash
cd packages/singleton_manager
dart run example/1_basic_singleton_manager.dart && \
dart run example/2_registry_eager_and_lazy.dart && \
dart run example/3_dependency_injection.dart && \
# ... continue with others
```

### Option 3: Using pub
```bash
cd packages/singleton_manager
flutter pub get  # or: dart pub get
dart run example/1_basic_singleton_manager.dart
```

---

## Learning Path

### Beginner
1. Start with `1_basic_singleton_manager.dart` - understand basics
2. Move to `3_dependency_injection.dart` - see practical usage
3. Review `4_error_handling.dart` - write safe code

### Intermediate
4. Study `2_registry_eager_and_lazy.dart` - understand all registry features
5. Learn `6_version_tracking_and_replace.dart` - hot-reload patterns
6. Practice with `9_testing_and_mocking.dart` - test-friendly code

### Advanced
7. Explore `7_complex_real_world_scenario.dart` - architectural patterns
8. Master `8_singleton_di_factory_pattern.dart` - advanced patterns
9. Optimize with `10_performance_and_best_practices.dart` - production-ready
10. Deep dive `5_async_initialization.dart` - complex async patterns

---

## Common Patterns

### Pattern: Service Locator
```dart
final manager = SingletonManager.instance;
manager.register<UserService>(UserService());
final service = manager.getInstance<UserService>();
```

### Pattern: DI Container
```dart
class AppContainer with Registry<Type, Object> {
  void setup() {
    register(IRepository, Repository());
    register(IService, Service());
  }
}
```

### Pattern: Factory Registry
```dart
SingletonDI.registerFactory<Service>(() => Service());
final service = SingletonDI.getFactory<Service>()!();
```

### Pattern: Lazy Loading
```dart
registry.registerLazy('expensive', () {
  return ExpensiveService(); // Called only on first access
});
```

### Pattern: Testing with Mocks
```dart
registry.register(IService, MockService());
final service = registry.getInstance<IService>();
// Test with mock
registry.destroyAll(); // Cleanup
```

---

## Key Takeaways

✅ **Do:**
- Use `lazy` for expensive resources
- Check with `contains()` before unsafe access
- Use `replace()` for updates, not `register()` again
- Call `destroy()` and `destroyAll()` for cleanup
- Implement `IValueForRegistry` for custom destruction

❌ **Don't:**
- Register the same key twice (use `replace()`)
- Access without checking if unsure (`contains()`)
- Forget to call `destroyAll()` in cleanup
- Mix eager and lazy inappropriately
- Ignore error handling (catch `DuplicateRegistrationError`, `RegistryNotFoundError`)

---

## Questions?

Check the main [README.md](../README.md) for package documentation and API reference.
