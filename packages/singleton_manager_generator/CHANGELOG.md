# Changelog

## [0.1.3] - 2026-03-16

### Fixed
- Removed workspace resolution (published packages shouldn't have workspace resolution)
- Analyzer ^10.0.0 is the latest version compatible with test package

## [0.1.2] - 2026-03-16

### Fixed
- Updated analyzer dependency to ^10.0.0 (latest compatible version with build package)

## [0.1.1] - 2026-03-16

### Fixed
- Updated analyzer dependency to ^8.0.0 for compatibility with test package

## [0.1.0] - 2026-03-16

### Added
- Initial release of singleton_manager_generator
- CLI tool for generating Dart augmentation files for @isSingleton classes
- Automatic code generation for ISingletonStandardDI implementations
- Support for @isInjected field annotations
- Verbose logging support
- Comprehensive test suite
- Integration tests for CLI functionality

### Features
- Scans Dart source files for @isSingleton and @isInjected annotations
- Generates augmentation files with ISingletonStandardDI implementations
- Creates initializeDI() factory methods for each singleton class
- Supports multiple injected fields per class
- Minimal overhead using Dart's analyzer package for lightweight AST parsing
- CLI options: --input, --output, --verbose, --help
