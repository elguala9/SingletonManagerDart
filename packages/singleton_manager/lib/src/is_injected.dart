/// Annotation to mark a field as requiring dependency injection.
///
/// When a field is annotated with isInjected in a class marked with
/// isSingleton, the singleton_manager_generator will automatically populate
/// the field in the generated initializeDI() method using
/// SingletonDIAccess.get&lt;T&gt;().
///
/// The annotated field must be:
/// - `late` (plain `final` is not supported)
/// - non-private (names starting with `_` are ignored by the generator)
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
