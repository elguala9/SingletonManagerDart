/// A high-performance, zero-dependency singleton manager for Dart.
///
/// This package provides a type-safe, efficient way to manage singleton
/// instances with support for lazy loading and optional scope isolation.
///
/// ## Quick Start
///
/// ```dart
/// import 'package:singleton_manager/singleton_manager.dart';
///
/// void main() {
///   final manager = SingletonManager<String>();
///   manager.register('myService', () => MyService());
///   final service = manager.get('myService');
/// }
/// ```
library singleton_manager;

export 'src/singleton_manager.dart';
