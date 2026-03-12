# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
