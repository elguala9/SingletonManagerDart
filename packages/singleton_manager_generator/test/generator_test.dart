import 'package:test/test.dart';
import 'package:singleton_manager_generator/src/generator/di_class_generator.dart';
import 'package:singleton_manager_generator/src/model/injected_field_info.dart';
import 'package:singleton_manager_generator/src/model/singleton_class_info.dart';

void main() {
  group('AugmentationGenerator', () {
    group('generate()', () {
      test('should generate DI code for class with single injected field', () {
        final info = SingletonClassInfo(
          className: 'MyService',
          sourceFilePath: 'lib/src/my_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(
              fieldName: 'db',
              fieldType: 'DatabaseConnection',
            ),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        expect(code, contains("// AUTO-GENERATED - DO NOT CHANGE"));
        expect(code, contains("// ignore_for_file: directives_ordering, library_prefixes, unnecessary_import"));
        expect(code, contains("import 'my_service.dart';"));
        expect(code, contains("class MyServiceDI extends MyService implements ISingletonStandardDI {"));
        expect(code, contains("factory MyServiceDI.initializeDI() {"));
        expect(code, contains("final instance = MyService();"));
        expect(code, contains("instance.initializeDI();"));
        expect(code, contains("void initializeDI() {"));
        expect(code, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
        expect(code, contains("import 'package:singleton_manager/singleton_manager.dart';"));
      });

      test('should generate DI code for class with multiple injected fields', () {
        final info = SingletonClassInfo(
          className: 'MyService',
          sourceFilePath: 'lib/src/my_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'db', fieldType: 'DatabaseConnection'),
            InjectedFieldInfo(fieldName: 'logger', fieldType: 'Logger'),
            InjectedFieldInfo(fieldName: 'config', fieldType: 'ConfigManager'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        expect(code, contains("db = SingletonDIAccess.get<DatabaseConnection>();"));
        expect(code, contains("logger = SingletonDIAccess.get<Logger>();"));
        expect(code, contains("config = SingletonDIAccess.get<ConfigManager>();"));

        // Verify all three injections are in the correct order
        final injections = [
          "db = SingletonDIAccess.get<DatabaseConnection>();",
          "logger = SingletonDIAccess.get<Logger>();",
          "config = SingletonDIAccess.get<ConfigManager>();",
        ];

        var lastIndex = -1;
        for (final injection in injections) {
          final index = code.indexOf(injection);
          expect(index, greaterThan(lastIndex));
          lastIndex = index;
        }
      });

      test('should generate DI code for class with no injected fields', () {
        final info = SingletonClassInfo(
          className: 'EmptyService',
          sourceFilePath: 'lib/src/empty_service.dart',
          sourceFileContent: '',
          injectedFields: [],
        );

        final code = AugmentationGenerator.generate(info);

        expect(code, contains("// AUTO-GENERATED - DO NOT CHANGE"));
        expect(code, contains("class EmptyServiceDI extends EmptyService implements ISingletonStandardDI {"));
        expect(code, contains("void initializeDI() {"));
        expect(code, contains("factory EmptyServiceDI.initializeDI() {"));
        // Should not have any field assignments
        expect(code, isNot(contains("SingletonDIAccess.get")));
      });

      test('should handle class names with underscores', () {
        final info = SingletonClassInfo(
          className: 'My_Service_Impl',
          sourceFilePath: 'lib/src/my_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'dep', fieldType: 'Dependency'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        expect(code, contains("// AUTO-GENERATED - DO NOT CHANGE"));
        expect(code, contains("class My_Service_ImplDI extends My_Service_Impl implements ISingletonStandardDI {"));
        expect(code, contains("factory My_Service_ImplDI.initializeDI() {"));
        expect(code, contains("final instance = My_Service_Impl();"));
      });

      test('should handle field names with underscores', () {
        final info = SingletonClassInfo(
          className: 'MyService',
          sourceFilePath: 'lib/src/my_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: '_private_field', fieldType: 'Service'),
            InjectedFieldInfo(fieldName: 'public_field', fieldType: 'OtherService'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        expect(code, contains("_private_field = SingletonDIAccess.get<Service>();"));
        expect(code, contains("public_field = SingletonDIAccess.get<OtherService>();"));
      });

      test('should handle complex type names', () {
        final info = SingletonClassInfo(
          className: 'MyService',
          sourceFilePath: 'lib/src/my_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'cache', fieldType: 'CacheManager'),
            InjectedFieldInfo(fieldName: 'repository', fieldType: 'UserRepository'),
            InjectedFieldInfo(fieldName: 'validator', fieldType: 'InputValidator'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        expect(code, contains("cache = SingletonDIAccess.get<CacheManager>();"));
        expect(code, contains("repository = SingletonDIAccess.get<UserRepository>();"));
        expect(code, contains("validator = SingletonDIAccess.get<InputValidator>();"));
      });

      test('should have proper formatting with indentation', () {
        final info = SingletonClassInfo(
          className: 'MyService',
          sourceFilePath: 'lib/src/my_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'db', fieldType: 'DatabaseConnection'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        // Verify proper indentation
        expect(code, contains('    db = SingletonDIAccess.get<DatabaseConnection>();'));
        expect(code, contains('  factory MyServiceDI.initializeDI() {'));
        expect(code, contains('  @override'));
        expect(code, contains('  void initializeDI() {'));
      });

      test('should contain override annotation', () {
        final info = SingletonClassInfo(
          className: 'MyService',
          sourceFilePath: 'lib/src/my_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'dep', fieldType: 'Dependency'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        expect(code, contains("@override"));
        expect(code, contains("void initializeDI()"));
      });

      test('should handle nested directory paths correctly', () {
        final info = SingletonClassInfo(
          className: 'MyService',
          sourceFilePath: 'lib/src/features/auth/services/my_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'auth', fieldType: 'AuthService'),
          ],
        );

        // Output is at lib root; import must be relative from there to the source
        final code = AugmentationGenerator.generate(
          info,
          outputFilePath: 'lib/my_service_di.dart',
        );

        expect(code, contains("import 'src/features/auth/services/my_service.dart';"));
      });

      test('should handle Windows-style path separators', () {
        final info = SingletonClassInfo(
          className: 'MyService',
          sourceFilePath: 'lib\\src\\my_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'dep', fieldType: 'Dependency'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        // Should use basename only for the import
        expect(code, contains("import 'my_service.dart';"));
      });

      test('should generate valid Dart syntax for initializeDI factory method', () {
        final info = SingletonClassInfo(
          className: 'MyService',
          sourceFilePath: 'lib/src/my_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'db', fieldType: 'DatabaseConnection'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        final createMethod = RegExp(
          r'factory MyServiceDI\.initializeDI\(\) \{[^}]*final instance = MyService\(\);[^}]*instance\.initializeDI\(\);[^}]*return instance as MyServiceDI;[^}]*\}',
          dotAll: true,
        );
        expect(code, matches(createMethod));
      });

      test('should maintain field order in generated code', () {
        final info = SingletonClassInfo(
          className: 'MyService',
          sourceFilePath: 'lib/src/my_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'first', fieldType: 'FirstService'),
            InjectedFieldInfo(fieldName: 'second', fieldType: 'SecondService'),
            InjectedFieldInfo(fieldName: 'third', fieldType: 'ThirdService'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        final firstIndex = code.indexOf('first =');
        final secondIndex = code.indexOf('second =');
        final thirdIndex = code.indexOf('third =');

        expect(firstIndex, greaterThan(-1));
        expect(secondIndex, greaterThan(firstIndex));
        expect(thirdIndex, greaterThan(secondIndex));
      });
    });

    group('edge cases', () {
      test('should handle single-character class names', () {
        final info = SingletonClassInfo(
          className: 'A',
          sourceFilePath: 'lib/a.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'b', fieldType: 'B'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        expect(code, contains("// AUTO-GENERATED - DO NOT CHANGE"));
        expect(code, contains("class ADI extends A implements ISingletonStandardDI {"));
        expect(code, contains("factory ADI.initializeDI() {"));
      });

      test('should handle class names with numbers', () {
        final info = SingletonClassInfo(
          className: 'Service123',
          sourceFilePath: 'lib/service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'dep456', fieldType: 'Service789'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        expect(code, contains("// AUTO-GENERATED - DO NOT CHANGE"));
        expect(code, contains("class Service123DI extends Service123 implements ISingletonStandardDI {"));
        expect(code, contains("factory Service123DI.initializeDI() {"));
        expect(code, contains("dep456 = SingletonDIAccess.get<Service789>();"));
      });

      test('should handle very long class names', () {
        final longName = 'VeryLongServiceNameWithManyWordsForTestingPurposesOnly';
        final info = SingletonClassInfo(
          className: longName,
          sourceFilePath: 'lib/service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'dependency', fieldType: 'SomeDependency'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        expect(code, contains("// AUTO-GENERATED - DO NOT CHANGE"));
        expect(code, contains("class ${longName}DI extends $longName implements ISingletonStandardDI {"));
        expect(code, contains("factory ${longName}DI.initializeDI() {"));
      });
    });

    group('initializeDI() execution', () {
      test('initializeDI() should be callable and work', () {
        // Create a simple class that will have initializeDI called
        final info = SingletonClassInfo(
          className: 'TestService',
          sourceFilePath: 'lib/test_service.dart',
          sourceFileContent: '',
          injectedFields: [
            InjectedFieldInfo(fieldName: 'value', fieldType: 'String'),
          ],
        );

        final code = AugmentationGenerator.generate(info);

        // Verify the generated code has the factory and initializeDI method
        expect(code, contains('factory TestServiceDI.initializeDI()'));
        expect(code, contains('void initializeDI()'));
        expect(code, contains('value = SingletonDIAccess.get<String>()'));

        // The generated code should have the proper structure to call initializeDI
        expect(code, contains('instance.initializeDI()'));
      });
    });
  });
}
