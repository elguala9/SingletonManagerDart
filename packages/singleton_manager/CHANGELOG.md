# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.1] - 2026-03-30

### Changed
- **Internal refactoring of registry architecture**:
  - Extracted `RegistryCore<K>` as a shared backing store used by both `Registry` and `RegistryOnlyKey` (new file `registry_core.dart`, not part of the public API)
  - `Registry<Key>` mixin renamed to `RegistryOnlyKey<Key>` — compound `(Type, Key)` keyed registry with generic `T` in method signatures (`register<T>()`, `getInstance<T>()`, etc.)
  - `Registry<Key, Value>` mixin now takes an explicit second type parameter `Value extends IValueForRegistry` for value-typed registries
  - `RegistryManager` now uses `RegistryOnlyKey<String>` (public API unchanged)

### Migration (only if using `Registry` mixin directly)
- Replace `with Registry<Key>` with `with RegistryOnlyKey<Key>` to preserve the compound-key generic API
- Or use `with Registry<Key, MyValueType>` if you prefer explicit value typing

## [0.6.0] - 2026-03-29

### Added
- **`Registry<Key>` mixin** — generic compound-key registry with `(Type, Key)` compound keys, supporting any key type
  - `register<T>()` — eager registration; throws `DuplicateRegistrationError` if already present
  - `registerLazy<T>()` — lazy (factory-based) registration; factory called on first access
  - `replace<T>()` / `replaceLazy<T>()` — replace an existing entry; throws `RegistryNotFoundError` if absent; increments version
  - `getInstance<T>()` — retrieves value, resolving lazy entries transparently
  - `unregister<T>()` — removes entry and returns its `ValueWithVersion` container
  - `getByKey<T>()` — inspect the raw versioned container without resolving lazy
  - `contains<T>()`, `keys`, `isEmpty`, `isNotEmpty`, `registrySize`, `clearRegistry()`, `destroyAll()`
- **`IRegistry<Key>`** — abstract interface matching `Registry<Key>`, for dependency-inversion and testing
- **`RegistryManager`** — concrete `String`-keyed registry (`with Registry<String>`)
- **`RegistryManagerSingleton`** — global singleton instance of `RegistryManager` (factory constructor returns the same instance)
- **`RegistryAccess`** — static convenience class mirroring `SingletonDIAccess`, delegating to `RegistryManagerSingleton`
  - `RegistryAccess.register<T>(key, value)`, `registerLazy`, `replace`, `replaceLazy`, `getInstance`, `contains`, `unregister`, `destroyAll`, `clearRegistry`
- **`RegistryEntry` sealed hierarchy** — internal sealed class for registry storage
  - `EagerEntry<V>` — stores a pre-created instance
  - `LazyEntry<V>` — stores a factory; caches result on first call to `resolvedValue`
- **`ValueWithVersion<V>`** — wrapper that pairs a value with an integer version counter (incremented on `replace`)
- **Error types** (`registry_errors.dart`):
  - `RegistryError` — sealed base error
  - `DuplicateRegistrationError` — thrown by `register`/`registerLazy` when key already exists
  - `RegistryNotFoundError` — thrown by `replace`/`replaceLazy`/`getInstance` when key is absent

## [0.5.0] - 2026-03-25

### Fixed
- Doc comment lines exceeding 80-character limit in `is_mandatory_parameter.dart` and `is_optional_parameter.dart`

## [0.4.1] - 2026-03-24

### Added
- `@isMandatoryParameter` annotation (`IsMandatoryParameter`) to mark constructor parameters as required for code generation
- `@isOptionalParameter` annotation (`IsOptionalParameter`) to mark constructor parameters as optional for code generation

## [0.4.0] - 2026-03-16

### BREAKING CHANGES
- **Merged singleton_manager_annotations into singleton_manager**
  - `@isSingleton` annotation now exported from `singleton_manager` package
  - `@isInjected` annotation now exported from `singleton_manager` package
  - `singleton_manager_annotations` package is now DEPRECATED
  - Migration: Change `import 'package:singleton_manager_annotations/...'` to `import 'package:singleton_manager/singleton_manager.dart'`

### Added
- Annotations (`@isSingleton`, `@isInjected`) are now included in the main package
- Single import point for all DI functionality

### Deprecated
- `singleton_manager_annotations` package is now deprecated in favor of `singleton_manager`

## [0.3.5] - 2026-03-16

### Improved
- Code quality: Optimized cascade operators in `singleton_di_ext.dart`
  - Improved readability in `add<T>()` method
  - Improved readability in `addAs<I, T>()` method
- Resolved all dart analyze issues with zero errors or warnings

## [0.3.4] - 2026-03-14

### Changed
- Updated README and documentation to reflect flexible API (v0.3.3+ improvements)
- Enhanced examples showing registration of plain objects without interfaces
- Clarified that `ISingleton` interface is optional

### Documentation
- Added examples of registering simple objects (strings, maps, configs)
- Improved feature list highlighting API flexibility
- Updated installation instructions to v0.3.4

## [0.3.3] - 2026-03-14

### Changed
- Made `addInstance` and `addInstanceAs` more permissive by using `Object` constraint instead of `ISingletonDI<dynamic>`
- Made `get<T>()` and `remove<T>()` accept any `Object` type, not just `ISingletonDI`
- Removed mandatory `initializeDI()` calls from instance registration methods

### Improved
- **Simplified API**: No longer requires `ISingletonDI` interface for instance registration and retrieval
- `get<T>()` now works with any registered type (factory-based or instance-based)
- `remove<T>()` now works with any registered type
- More flexible for simple value objects that don't need initialization

### Benefits
- Can register and retrieve plain Dart objects without implementing interfaces
- Cleaner API for simple use cases
- Better compatibility with third-party classes

## [0.3.2] - 2026-03-14

### Changed
- Updated documentation and examples to reflect v0.3.1+ features
- Improved README with clearer feature descriptions
- Enhanced code comments and dartdoc for better API clarity
- Fixed all linting violations (100% clean)
- Updated dependencies and analysis options

### Added
- **New Documentation Sections**:
  - Comparison & Use Cases table
  - Best Practices guide with code examples
  - Examples directory reference with all available examples
  - DI Patterns comparison (Factory vs Instance vs Static)

### Documentation
- Updated Quick Start examples to show both static and instance-based registration
- Added comprehensive examples in main README
- Clarified lifecycle management with ISingleton interface
- Improved API clarity with better code examples

## [0.3.1] - 2026-03-14

### Fixed
- Fixed all dart analyzer linting issues and code style violations
  - Proper line wrapping for lines exceeding 80 characters
  - Correct member ordering (constructors before methods)
  - Used cascade operators where appropriate
  - Added missing newlines at end of files
- Excluded example files from strict linting rules
- Added ignore comment for false positive `one_member_abstracts` warning on `ISingletonDI`

## [0.3.0] - 2026-03-13

### Added
- **SingletonDIAccess**: Static convenience class for accessing the global singleton manager
  - `add<T>()` - Static method to register singleton by type
  - `addAs<I, T>()` - Static method to register implementation with interface as key
  - `addInstance<T>()` - Static method to register existing instance
  - `addInstanceAs<I, T>()` - Static method to register existing instance with interface as key
  - `get<T>()` - Static method for type-safe singleton retrieval
  - `remove<T>()` - Static method for type-safe singleton removal
- **Instance-Based Registration**: New extension methods on SingletonManager
  - `addInstance<T>()` - Register an existing singleton instance of type T
  - `addInstanceAs<I, T>()` - Register an existing instance under interface I
- **New Example**: `11_singleton_di_access_static_methods.dart` demonstrating static API patterns

### Changed
- Internal code cleanup and optimization in `SingletonDIExt`

## [0.2.0] - 2026-03-12

### Added
- **SingletonDI**: Factory registration system for dependency injection
  - `registerFactory<T>()` - Register factory functions
  - `getFactory<T>()` - Retrieve registered factories
  - `clearFactories()` - Clear all factories
  - `factoryCount` - Get number of registered factories
- **Extension Methods** on SingletonManager:
  - `add<T>()` - Register singleton with automatic factory instantiation
  - `addAs<I, T>()` - Register implementation with interface as key
  - `get<T>()` - Type-safe singleton retrieval
  - `remove<T>()` - Type-safe singleton removal
- **ISingleton Interface**: Lifecycle management for singletons
  - `initialize(input)` - Custom initialization with input
  - `initializeDI()` - DI-specific initialization
- **IValueForRegistry Interface**: Registry entry management
- **RegistryMixin** and **RegistryEntry**: Improved internal architecture
- **Registry Utilities**: Helper functions for registry operations
- **Error Handling**: Custom exceptions in `RegistryErrors`
- **Full Example**: Complete DI example with factory registration, initialization, and dependencies

### Changed
- Refactored internal structure with mixins and interfaces

## [0.1.0] - 2026-03-11

### Added
- Initial release of singleton_manager package
- SingletonManager class for registering and retrieving singletons
- Generic type-safe singleton support
- Lazy loading of singletons
- Zero external dependencies
- Complete documentation and examples

### Features
- O(1) time complexity for registration and retrieval
- Type-safe generics support
- Pure Dart implementation (multi-platform compatible)

## Roadmap

### Future Versions (v0.4.0+)

- **Scope Improvements**:
  - Better scope isolation and management
  - Automatic scope cleanup on dispose
  - Scope-specific factory overrides

- **Observable Support**:
  - Listen to singleton registration/removal events
  - Reactive notifications on lifecycle changes

- **Advanced Features**:
  - Conditional registration (factory selection based on criteria)
  - Singleton reset/re-initialization
  - Circular dependency detection

- **Performance Enhancements**:
  - Further optimization of hot paths
  - Reduced memory footprint for large registries

- **Additional Documentation**:
  - Architecture deep-dive guide
  - Performance benchmarks
  - Migration guides from other DI frameworks
