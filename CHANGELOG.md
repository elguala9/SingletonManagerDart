# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## Monorepo Updates - 2026-03-26 (patch)

### singleton_manager_generator [1.3.1]

- **Fixed**: parser now preserves generic type arguments in `@isInjected` / `@isMandatoryParameter` / `@isOptionalParameter` fields — `IErmesBookRepository<BookData>` was incorrectly stripped to `IErmesBookRepository`, causing `SingletonDIAccess.get<IErmesBookRepository>()` (missing type param) in the generated DI file
- **Added**: tests covering single, multi-parameter, nested, and nullable generic field types (parser, generator, and integration tests)

## Monorepo Updates - 2026-03-26

### singleton_manager_generator [1.3.0]

- **Breaking**: generated DI class no longer uses the default constructor — replaced with named constructor `.emptyForDI()` to avoid conflicts with the parent class default constructor
  - `ClassName DI() : super()` → `ClassNameDI.emptyForDI() : super()`
  - All generated factory methods (`initializeDI`, `initializeWithParametersDI`) now instantiate via `.emptyForDI()`
- Added test artifact `id_handler_storage_repository_no_ctor_params` covering the full combination of `@isMandatoryParameter`, `@isOptionalParameter`, and `@isInjected` fields with an empty constructor

## Monorepo Updates - 2026-03-16

### singleton_manager_generator [1.0.0]
**First stable release** - Production-ready CLI tool for generating Dart augmentation files

- Removed dependency on `singleton_manager_annotations` (consolidated into `singleton_manager`)
- **CRITICAL FIX**: Fixed undefined getter 'name2' that caused generator crashes
- Fixed unused imports and analyzer warnings
- All tests passing with zero analyzer errors
- Ready for production use

### singleton_manager [0.3.5] - Code Quality Update
- Optimized cascade operators for improved code readability
- No functional changes

## [0.3.0] - 2026-03-13

### Added
- **SingletonDIAccess**: Static convenience class for accessing the global singleton manager
  - Provides static methods without needing explicit instance access
  - Supports all DI operations: `add`, `addAs`, `addInstance`, `addInstanceAs`, `get`, `remove`
- **Instance-Based Registration**: New extension methods for registering existing instances
  - `addInstance<T>()` - Register an existing singleton instance
  - `addInstanceAs<I, T>()` - Register existing instance under interface
  - Useful for pre-configured objects and testing

### Changed
- Internal code optimization and cleanup

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
- Better separation of concerns with dedicated packages for errors, interfaces, and utilities

## [0.1.0] - 2026-03-11

### Added
- Initial release of singleton_manager package
- SingletonManager class for registering and retrieving singletons
- Generic type-safe singleton support
- Lazy loading of singletons
- Comprehensive test suite with unit and functional tests
- Complete documentation and examples
- CI/CD pipeline with GitHub Actions
- MIT License

### Features
- Zero external dependencies
- O(1) time complexity for registration and retrieval
- Type-safe generics support
- Pure Dart implementation (multi-platform compatible)
