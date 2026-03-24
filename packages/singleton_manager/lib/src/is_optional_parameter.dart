/// Annotation to mark a constructor parameter as optional for code generation.
///
/// When a constructor parameter is annotated with [isOptionalParameter] in a
/// class marked with [isSingleton], the singleton_manager_generator will
/// treat it as an optional argument when building the generated class.
///
/// Example:
/// ```dart
/// @isSingleton
/// class MyService {
///   MyService({@isOptionalParameter String? timeout});
/// }
/// ```
class IsOptionalParameter {
  /// Create an instance of the [IsOptionalParameter] annotation.
  const IsOptionalParameter();
}

/// Constant instance of [IsOptionalParameter] for use as an annotation.
const isOptionalParameter = IsOptionalParameter();
