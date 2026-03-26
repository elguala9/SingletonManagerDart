# Changelog

## [1.3.1] - 2026-03-26

### Fixed
- Parser now correctly preserves generic type arguments in field types (e.g. `IErmesBookRepository<BookData>` was stripped to `IErmesBookRepository`)
  - `_extractFieldType` is now recursive and captures `NamedType.typeArguments`
  - Supports single generics (`IRepository<BookData>`), multi-parameter generics (`IMap<String, BookData>`), nested generics (`ICache<Map<String, int>>`), and nullable generics (`IRepository<BookData>?`)
  - Generated `SingletonDIAccess.get<T>()` calls now include the full generic type, e.g. `get<IErmesBookRepository<BookData>>()`

### Added
- Tests for generic type support: parser tests, generator tests, and integration tests (including artifact files in `lib/test_artifacts/integration_tests/lib/src/params/`)

## [1.3.0] - 2026-03-26

### Changed
- **Breaking**: generated DI class no longer uses the default constructor — renamed to `.emptyForDI()` to avoid conflicts when the parent class also defines a default constructor
  - `ClassNameDI() : super()` → `ClassNameDI.emptyForDI() : super()`
  - `initializeDI()` factory instantiates via `ClassNameDI.emptyForDI()`
  - `initializeWithParametersDI()` factory instantiates via `ClassNameDI.emptyForDI()` when no constructor parameters are present, or via `ClassNameDI(params)` when constructor parameters exist

## [1.2.0] - 2026-03-25

### Added
- `@isOptionalParameter` annotation now supported on **fields** (in addition to constructor parameters)
  - Parser sets a new `isOptional` flag on `InjectedFieldInfo` when `@isOptionalParameter` is found on a field
  - In `initializeDI()`: optional fields are guarded with `if (SingletonDIAccess.exists<T>())` before injection
  - In `initializeWithParametersDI()`: optional fields appear as nullable named parameters `{T? fieldName}`; assigned directly if provided

### Changed
- `initializeDI()` now injects **all** annotated fields including `@isMandatoryParameter` fields (previously excluded). This makes `initializeDI()` a full singleton factory where every dependency is resolved from the container
- `initializeWithParametersDI()` no longer calls `initializeDI()` internally. Instead it injects each category of field explicitly:
  - `@isInjected` fields → always fetched from container via `SingletonDIAccess.get<T>()`
  - `@isOptionalParameter` fields → assigned from the optional named parameter
  - `@isMandatoryParameter` fields → assigned from the required positional parameter

## [1.1.3] - 2026-03-25

### Changed
- Parser now emits a warning when a field annotated with `@isOptionalParameter` has a non-nullable type (e.g., `String` instead of `String?`)

## [1.1.0] - 2026-03-24

### Added
- Support for `@isMandatoryParameter` and `@isOptionalParameter` annotations on constructor parameters
- New `ConstructorParameterInfo` model to represent annotated constructor parameters
- Parser now extracts constructor parameters annotated with `@isMandatoryParameter` / `@isOptionalParameter`
- Generator creates a typed DI constructor that mirrors the original constructor signature
- New `initializeWithParametersDI()` factory generated for classes with annotated constructor parameters
  - Mandatory parameters become positional arguments in the factory
  - Optional parameters become named optional arguments in the factory
- No-arg `initializeDI()` factory is omitted when mandatory constructor parameters are present (avoids compile error)
- `initializeWithParametersDI()` and `@isInjected` field injection can be combined in the same class

## [1.0.5] - 2026-03-24

### Changed
- Generated files now include `// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import, unused_import, lines_longer_than_80_chars, cascade_invocations` to suppress analyzer warnings in generated code

## [1.0.4] - 2026-03-18

### Changed
- Generated factory `initializeDI()` now instantiates `ClassNameDI()` directly instead of casting `ClassName() as ClassNameDI`
- Generated DI class now includes an explicit default constructor `ClassNameDI() : super()` to ensure correct subclass instantiation

## [1.0.3] - 2026-03-17

### Changed
- `unused_import` is now treated as an error (moved to `analyzer.errors` in `analysis_options.yaml`)

## [1.0.2] - 2026-03-16

### Fixed
- Combined instance creation and cast into a single statement in the generated `initializeDI()` factory — `as ClassDI` is now on the same line as the constructor call

## [1.0.1] - 2026-03-16

### Fixed
- Generated DI files now use the correct relative import path for the source class when the output directory differs from the source directory (e.g. `import 'impl/socket/my_service.dart'` instead of `import 'my_service.dart'`)
- Generated DI files now include all imports from the source file, rebased relative to the output file's location — field types referenced by `@isInjected` (e.g. interface types) are therefore always resolvable

## [1.0.0] - 2026-03-16

**First stable release** - The singleton_manager_generator API is now stable and ready for production use.

### Changed
- Removed dependency on `singleton_manager_annotations` (now part of `singleton_manager`)
- Annotations are now referenced from `singleton_manager` package

### Fixed
- **CRITICAL**: Fixed undefined getter 'name2' in source_parser.dart that caused generator to crash
  - Changed `typeAnnotation.name2.lexeme` to `typeAnnotation.name.lexeme`
  - Generator now correctly extracts field type names from class declarations
- Fixed unused imports in test files
- Resolved all dart analyze issues (cascade invocations, deprecated member usage)

### Improved
- Simplified dependency chain by removing intermediate annotation package
- Code quality: Optimized cascade operators in test suite
- All tests pass with zero analyzer errors or warnings

## [0.1.4] - 2026-03-16

### Fixed
- **CRITICAL**: Fixed undefined getter 'name2' in source_parser.dart that caused generator to crash
  - Changed `typeAnnotation.name2.lexeme` to `typeAnnotation.name.lexeme`
  - Generator now correctly extracts field type names from class declarations
- Fixed unused imports in test files
- Added `singleton_manager` as dev dependency for integration tests
- Resolved all dart analyze issues (cascade invocations, deprecated member usage)
- Added ignore comments for analyzer deprecation warnings that are not yet available in analyzer ^10.0.0

### Improved
- Code quality: Optimized cascade operators in test suite
- All tests pass with zero analyzer errors or warnings

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
