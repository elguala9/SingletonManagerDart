import 'package:test/test.dart';
import 'package:singleton_manager_generator/src/model/injected_field_info.dart';
import 'package:singleton_manager_generator/src/model/singleton_class_info.dart';

void main() {
  group('InjectedFieldInfo', () {
    test('should create instance with fieldName and fieldType', () {
      final info = InjectedFieldInfo(
        fieldName: 'database',
        fieldType: 'DatabaseConnection',
      );

      expect(info.fieldName, 'database');
      expect(info.fieldType, 'DatabaseConnection');
    });

    test('should have proper toString representation', () {
      final info = InjectedFieldInfo(
        fieldName: 'logger',
        fieldType: 'Logger',
      );

      final string = info.toString();
      expect(string, contains('InjectedFieldInfo'));
      expect(string, contains('fieldName: logger'));
      expect(string, contains('fieldType: Logger'));
    });

    test('should handle special characters in field names', () {
      final info = InjectedFieldInfo(
        fieldName: '_privateField',
        fieldType: 'Service',
      );

      expect(info.fieldName, '_privateField');
    });

    test('should handle complex type names', () {
      final info = InjectedFieldInfo(
        fieldName: 'service',
        fieldType: 'MyService<T>',
      );

      expect(info.fieldType, 'MyService<T>');
    });
  });

  group('SingletonClassInfo', () {
    test('should create instance with className, sourceFilePath, and injectedFields', () {
      final fields = [
        InjectedFieldInfo(fieldName: 'db', fieldType: 'DatabaseConnection'),
        InjectedFieldInfo(fieldName: 'logger', fieldType: 'Logger'),
      ];

      final info = SingletonClassInfo(
        className: 'MyService',
        sourceFilePath: 'lib/src/my_service.dart',
        injectedFields: fields,
      );

      expect(info.className, 'MyService');
      expect(info.sourceFilePath, 'lib/src/my_service.dart');
      expect(info.injectedFields, hasLength(2));
      expect(info.injectedFields[0].fieldName, 'db');
      expect(info.injectedFields[1].fieldName, 'logger');
    });

    test('should create instance with empty injectedFields list', () {
      final info = SingletonClassInfo(
        className: 'EmptyService',
        sourceFilePath: 'lib/src/empty_service.dart',
        injectedFields: [],
      );

      expect(info.className, 'EmptyService');
      expect(info.injectedFields, isEmpty);
    });

    test('should have proper toString representation', () {
      final fields = [
        InjectedFieldInfo(fieldName: 'dep', fieldType: 'Dependency'),
      ];

      final info = SingletonClassInfo(
        className: 'TestService',
        sourceFilePath: 'lib/test.dart',
        injectedFields: fields,
      );

      final string = info.toString();
      expect(string, contains('SingletonClassInfo'));
      expect(string, contains('className: TestService'));
      expect(string, contains('sourceFilePath: lib/test.dart'));
      expect(string, contains('injectedFields'));
    });

    test('should maintain field order', () {
      final fields = [
        InjectedFieldInfo(fieldName: 'first', fieldType: 'FirstService'),
        InjectedFieldInfo(fieldName: 'second', fieldType: 'SecondService'),
        InjectedFieldInfo(fieldName: 'third', fieldType: 'ThirdService'),
      ];

      final info = SingletonClassInfo(
        className: 'MyService',
        sourceFilePath: 'lib/service.dart',
        injectedFields: fields,
      );

      expect(info.injectedFields[0].fieldName, 'first');
      expect(info.injectedFields[1].fieldName, 'second');
      expect(info.injectedFields[2].fieldName, 'third');
    });

    test('should handle many injected fields', () {
      final fields = List.generate(
        100,
        (i) => InjectedFieldInfo(
          fieldName: 'field$i',
          fieldType: 'Service$i',
        ),
      );

      final info = SingletonClassInfo(
        className: 'HeavyService',
        sourceFilePath: 'lib/service.dart',
        injectedFields: fields,
      );

      expect(info.injectedFields, hasLength(100));
      expect(info.injectedFields[0].fieldName, 'field0');
      expect(info.injectedFields[99].fieldName, 'field99');
    });

    test('should handle Windows-style paths', () {
      final info = SingletonClassInfo(
        className: 'MyService',
        sourceFilePath: 'lib\\src\\my_service.dart',
        injectedFields: [],
      );

      expect(info.sourceFilePath, 'lib\\src\\my_service.dart');
    });

    test('should handle Unix-style paths', () {
      final info = SingletonClassInfo(
        className: 'MyService',
        sourceFilePath: 'lib/src/my_service.dart',
        injectedFields: [],
      );

      expect(info.sourceFilePath, 'lib/src/my_service.dart');
    });
  });
}
