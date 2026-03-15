/// Annotation to mark a field as requiring dependency injection.
///
/// When a field is annotated with isInjected in a class marked with isSingleton,
/// the singleton_manager_generator will automatically populate the field in the
/// generated initializeDI() method using SingletonDIAccess.get&lt;T&gt;().
///
/// Example:
/// ```dart
/// @isSingleton
/// class MyService {
///   @isInjected
///   late OtherService otherService;
/// }
/// ```
class IsInjected {
  /// Create an instance of the [IsInjected] annotation.
  const IsInjected();
}

/// Constant instance of [IsInjected] for use as an annotation.
const isInjected = IsInjected();
