// ignore_for_file: avoid_print
import 'package:singleton_manager/singleton_manager.dart';

/// Example 1: Basic SingletonManager - Type-based singleton registration
///
/// The simplest way to use singleton_manager. Register values using their Type,
/// and retrieve them using getInstance<Type>().

class DatabaseConnection {
  DatabaseConnection() {
    print('DatabaseConnection created');
  }

  void query(String sql) {
    print('Executing: $sql');
  }
}

class Logger {
  Logger() {
    print('Logger created');
  }

  void log(String message) {
    print('[LOG] $message');
  }
}

void main() {
  final manager = SingletonManager.instance;

  print('=== Basic Singleton Manager Example ===\n');

  // Step 1: Register singletons by Type
  print('Step 1: Register singletons');
  final db = DatabaseConnection();
  manager.register<DatabaseConnection>(db);

  final logger = Logger();
  manager.register<Logger>(logger);
  print('Registry size: ${manager.registrySize}\n');

  // Step 2: Retrieve singletons
  print('Step 2: Retrieve and use singletons');
  final db1 = manager.getInstance<DatabaseConnection>();
  db1.query('SELECT * FROM users');

  final logger1 = manager.getInstance<Logger>();
  logger1.log('Database query executed\n');

  // Step 3: Verify singleton behavior (same instance)
  print('Step 3: Verify singleton behavior');
  final db2 = manager.getInstance<DatabaseConnection>();
  final logger2 = manager.getInstance<Logger>();
  print('Same DB instance: ${identical(db1, db2)}');
  print('Same Logger instance: ${identical(logger1, logger2)}\n');

  // Step 4: Unregister
  print('Step 4: Unregister');
  manager.unregister<Logger>();
  print('Registry size after unregister: ${manager.registrySize}\n');

  // Step 5: Clear all
  print('Step 5: Clear all');
  manager.clearRegistry();
  print('Registry size after clear: ${manager.registrySize}');
}
