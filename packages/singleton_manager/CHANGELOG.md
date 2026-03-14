# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
