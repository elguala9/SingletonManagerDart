# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
