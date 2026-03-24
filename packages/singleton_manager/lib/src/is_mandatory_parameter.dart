/// Annotation to mark a constructor parameter as mandatory for code generation.
///
/// When a constructor parameter is annotated with [isMandatoryParameter] in a
/// class marked with [IsMandatoryParameter], the singleton_manager_generator will
/// include it as a required argument when building the generated class.
///
/// Example:
/// ```dart
/// @isSingleton
/// class MyService {
///   MyService({@isMandatoryParameter required String apiUrl});
/// }
/// ```
class IsMandatoryParameter {
  /// Create an instance of the [IsMandatoryParameter] annotation.
  const IsMandatoryParameter();
}

/// Constant instance of [IsMandatoryParameter] for use as an annotation.
const isMandatoryParameter = IsMandatoryParameter();
