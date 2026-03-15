/// Annotation to mark a class as a singleton requiring automatic DI setup.
///
/// When a class is annotated with isSingleton, the singleton_manager_generator
/// will create an augmentation file that generates:
/// - A static create() factory method
/// - An implementation of ISingletonStandardDI.initializeDI()
///
/// Example:
/// ```dart
/// @isSingleton
/// class MyService {
///   @isInjected
///   late OtherService otherService;
/// }
/// ```
class IsSingleton {
  /// Create an instance of the [IsSingleton] annotation.
  const IsSingleton();
}

/// Constant instance of [IsSingleton] for use as an annotation.
const isSingleton = IsSingleton();
