// ignore_for_file: avoid_print
import 'package:singleton_manager/singleton_manager.dart';

/// Example 4: Error Handling
///
/// Demonstrates proper error handling with:
/// - DuplicateRegistrationError (attempting to register same key twice)
/// - RegistryNotFoundError (trying to access non-existent key)

class Service implements IValueForRegistry {
  final String id;

  Service(this.id) {
    print('✓ Service($id) created');
  }

  @override
  void destroy() {
    print('✗ Service($id) destroyed');
  }
}

class ErrorHandlingRegistry with Registry<String, Service> {}

void main() {
  final registry = ErrorHandlingRegistry();

  print('=== Error Handling ===\n');

  // ========== Error 1: DuplicateRegistrationError ==========
  print('Error 1: DuplicateRegistrationError');
  print('Registering "service1"...');
  registry.register('service1', Service('A'));

  print('Attempting to register "service1" again...');
  try {
    registry.register('service1', Service('B'));
    print('ERROR: Should have thrown DuplicateRegistrationError!');
  } on DuplicateRegistrationError catch (e) {
    print('✓ Caught: $e\n');
  }

  // ========== Error 2: RegistryNotFoundError (getInstance) ==========
  print('Error 2: RegistryNotFoundError (getInstance)');
  print('Trying to get non-existent service...');
  try {
    registry.getInstance('unknown');
    print('ERROR: Should have thrown RegistryNotFoundError!');
  } on RegistryNotFoundError catch (e) {
    print('✓ Caught: $e\n');
  }

  // ========== Error 3: RegistryNotFoundError (replace) ==========
  print('Error 3: RegistryNotFoundError (replace)');
  print('Trying to replace non-existent service...');
  try {
    registry.replace('unknown', Service('C'));
    print('ERROR: Should have thrown RegistryNotFoundError!');
  } on RegistryNotFoundError catch (e) {
    print('✓ Caught: $e\n');
  }

  // ========== Error 4: RegistryNotFoundError (replaceLazy) ==========
  print('Error 4: RegistryNotFoundError (replaceLazy)');
  print('Trying to replace lazy non-existent service...');
  try {
    registry.replaceLazy('unknown', () => Service('D'));
    print('ERROR: Should have thrown RegistryNotFoundError!');
  } on RegistryNotFoundError catch (e) {
    print('✓ Caught: $e\n');
  }

  // ========== Proper Usage: Use replace() for updates ==========
  print('Proper Usage: Use replace() to update existing service');
  print('Current service: ${registry.getInstance('service1').id}');
  registry.replace('service1', Service('E'));
  print('Updated service: ${registry.getInstance('service1').id}\n');

  // ========== Proper Usage: Handle lazy factory errors ==========
  print('Proper Usage: Lazy factory that might fail');
  var attemptCount = 0;
  registry.registerLazy('lazy_service', () {
    attemptCount++;
    if (attemptCount == 1) {
      throw Exception('First attempt failed');
    }
    return Service('F');
  });

  print('First access (will fail)...');
  try {
    registry.getInstance('lazy_service');
  } catch (e) {
    print('✓ Caught: $e');
  }

  print('Second access (will fail again - lazy not cached)...');
  try {
    registry.getInstance('lazy_service');
  } catch (e) {
    print('✓ Caught: $e\n');
  }

  // ========== Safe Operations ==========
  print('Safe Operations: Check before accessing');
  print('Contains "service1": ${registry.contains('service1')}');
  print('Contains "unknown": ${registry.contains('unknown')}');
  print('Registry size: ${registry.registrySize}\n');

  // ========== Recovery ==========
  print('Recovery: Register after error');
  registry.register('service2', Service('G'));
  print('service2 registered successfully\n');

  // Cleanup
  print('Cleanup:');
  registry.destroyAll();
}
