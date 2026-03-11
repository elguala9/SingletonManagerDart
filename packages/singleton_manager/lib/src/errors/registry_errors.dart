/// Base error for registry-related exceptions
sealed class RegistryError extends Error {
  RegistryError(this.message);

  final String message;

  @override
  String toString() => 'RegistryError: $message';
}

/// Error thrown when trying to register a duplicate key
final class DuplicateRegistrationError extends RegistryError {
  DuplicateRegistrationError(super.message);

  @override
  String toString() => 'DuplicateRegistrationError: $message';
}

/// Error thrown when a key is not found in the registry
final class RegistryNotFoundError extends RegistryError {
  RegistryNotFoundError(super.message);

  @override
  String toString() => 'RegistryNotFoundError: $message';
}
