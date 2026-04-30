import 'package:test/test.dart';
import 'package:singleton_manager/singleton_manager.dart';

abstract interface class IGeneratedService {
  String get value;
}

class ServiceWithInterface implements ISingletonStandardDI, IGeneratedService {
  @override
  late String value;

  @override
  void initializeDI() {
    value = SingletonDIAccess.get<String>();
  }
}

// Codice generato REALE estratto dai file augment
class DatabaseConnection {}

class ServiceC implements ISingletonStandardDI {
  late DatabaseConnection db;

  // Codice generato dal generator
  @override
  void initializeDI() {
    db = SingletonDIAccess.get<DatabaseConnection>();
  }
}

class ServiceConfigGenerated implements ISingletonStandardDI {
  late String environment;
  late int timeout;

  // Codice generato dal generator
  @override
  void initializeDI() {
    environment = SingletonDIAccess.get<String>();
    timeout = SingletonDIAccess.get<int>();
  }
}

void main() {
  group('initializeDI() execution with proper dependency setup', () {
    setUp(() {
      SingletonManager.instance.clearRegistry();
    });

    test(
      'ServiceConfigGenerated.initializeDI() RUNS quando dipendenze sono registrate',
      () {
        // SETUP: Registra le dipendenze nel registry
        SingletonManager.instance.register<String>('prod');
        SingletonManager.instance.register<int>(30);

        final service = ServiceConfigGenerated();

        // RUN: initializeDI() - DEVE FUNZIONARE
        expect(() {
          service.initializeDI();
        }, returnsNormally);

        // VERIFY: ServiceConfigGenerated è inizializzato
        expect(service.environment, 'prod');
        expect(service.timeout, 30);
      },
    );

    test(
      'ServiceC.initializeDI() RUNS quando DatabaseConnection è registrato',
      () {
        // SETUP: Registra DatabaseConnection
        SingletonManager.instance.register<DatabaseConnection>(
          DatabaseConnection(),
        );

        final service = ServiceC();

        // RUN: initializeDI() - DEVE FUNZIONARE
        expect(() {
          service.initializeDI();
        }, returnsNormally);

        // VERIFY: ServiceC è inizializzato
        expect(service.db, isNotNull);
      },
    );
  });

  group('Full DI pipeline: registerFactory + add<T>()', () {
    setUp(() {
      SingletonDI.clearFactories();
      SingletonManager.instance.clearRegistry();
    });

    tearDown(() {
      SingletonDI.clearFactories();
      SingletonManager.instance.clearRegistry();
    });

    test(
      'add<T>() chiama initializeDI() sulla classe generata e inietta le dipendenze',
      () {
        SingletonManager.instance.register<String>('prod');
        SingletonManager.instance.register<int>(30);

        SingletonDI.registerFactory<ServiceConfigGenerated>(
          ServiceConfigGenerated.new,
        );
        SingletonManager.instance.add<ServiceConfigGenerated>();

        final service = SingletonManager.instance.get<ServiceConfigGenerated>();
        expect(service.environment, 'prod');
        expect(service.timeout, 30);
      },
    );

    test(
      'SingletonDIAccess.add<T>() (statico) chiama initializeDI() sulla classe generata',
      () {
        SingletonManager.instance.register<DatabaseConnection>(
          DatabaseConnection(),
        );

        SingletonDI.registerFactory<ServiceC>(ServiceC.new);
        SingletonDIAccess.add<ServiceC>();

        final service = SingletonDIAccess.get<ServiceC>();
        expect(service.db, isNotNull);
        expect(service.db, isA<DatabaseConnection>());
      },
    );

    test(
      'add<T>() con classe generata restituisce singleton (stessa istanza)',
      () {
        SingletonManager.instance.register<String>('singleton-value');
        SingletonManager.instance.register<int>(99);

        SingletonDI.registerFactory<ServiceConfigGenerated>(
          ServiceConfigGenerated.new,
        );
        SingletonManager.instance.add<ServiceConfigGenerated>();

        final first = SingletonManager.instance.get<ServiceConfigGenerated>();
        final second = SingletonManager.instance.get<ServiceConfigGenerated>();

        expect(identical(first, second), isTrue);
      },
    );

    test('add<T>() lancia StateError se la factory non è registrata', () {
      expect(
        () => SingletonManager.instance.add<ServiceConfigGenerated>(),
        throwsA(isA<StateError>()),
      );
    });

    test(
      'add<T>() lancia StateError se le dipendenze non sono nel registry',
      () {
        SingletonDI.registerFactory<ServiceConfigGenerated>(
          ServiceConfigGenerated.new,
        );
        // Non registriamo String né int

        expect(
          () => SingletonManager.instance.add<ServiceConfigGenerated>(),
          throwsA(isA<StateError>()),
        );
      },
    );
  });

  group('Pattern addInstance: crea istanza + initializeDI() + addInstance', () {
    setUp(() {
      SingletonManager.instance.clearRegistry();
    });

    tearDown(() {
      SingletonManager.instance.clearRegistry();
    });

    test(
      'addInstance registra un\'istanza già inizializzata via initializeDI()',
      () {
        SingletonManager.instance.register<String>('staging');
        SingletonManager.instance.register<int>(60);

        // Simula il pattern della factory generata
        final instance = ServiceConfigGenerated();
        instance.initializeDI();

        SingletonDIAccess.addInstance<ServiceConfigGenerated>(instance);

        final retrieved = SingletonDIAccess.get<ServiceConfigGenerated>();
        expect(retrieved.environment, 'staging');
        expect(retrieved.timeout, 60);
        expect(identical(instance, retrieved), isTrue);
      },
    );

    test(
      'addInstance con ServiceC mantiene la stessa istanza di DatabaseConnection iniettata',
      () {
        final db = DatabaseConnection();
        SingletonManager.instance.register<DatabaseConnection>(db);

        final service = ServiceC();
        service.initializeDI();
        SingletonDIAccess.addInstance<ServiceC>(service);

        final retrieved = SingletonDIAccess.get<ServiceC>();
        expect(retrieved.db, isNotNull);
        expect(identical(retrieved.db, db), isTrue);
      },
    );
  });

  group(
    'Pattern addInstanceAs: classe generata registrata tramite interfaccia',
    () {
      setUp(() {
        SingletonManager.instance.clearRegistry();
      });

      tearDown(() {
        SingletonManager.instance.clearRegistry();
      });

      test(
        'addInstanceAs registra la classe generata sotto l\'interfaccia e la recupera correttamente',
        () {
          SingletonManager.instance.register<String>('interface-value');

          final instance = ServiceWithInterface();
          instance.initializeDI();
          SingletonDIAccess.addInstanceAs<
            IGeneratedService,
            ServiceWithInterface
          >(instance);

          final retrieved = SingletonDIAccess.get<IGeneratedService>();
          expect(retrieved.value, 'interface-value');
          expect(retrieved, isA<ServiceWithInterface>());
        },
      );

      test(
        'addInstanceAs sostituisce una registrazione precedente per la stessa interfaccia',
        () {
          SingletonManager.instance.register<String>('v1');
          final first = ServiceWithInterface();
          first.initializeDI();
          SingletonDIAccess.addInstanceAs<
            IGeneratedService,
            ServiceWithInterface
          >(first);
          expect(SingletonDIAccess.get<IGeneratedService>().value, 'v1');

          // Aggiorna il valore registrato e crea una nuova istanza
          SingletonManager.instance.remove<String>();
          SingletonManager.instance.register<String>('v2');
          final second = ServiceWithInterface();
          second.initializeDI();
          SingletonDIAccess.addInstanceAs<
            IGeneratedService,
            ServiceWithInterface
          >(second);

          expect(SingletonDIAccess.get<IGeneratedService>().value, 'v2');
        },
      );
    },
  );

  group('initializeDI() execution WITHOUT dependencies (CRASH)', () {
    setUp(() {
      SingletonManager.instance.clearRegistry();
    });

    test(
      'ServiceConfigGenerated.initializeDI() CRASHA quando String non è registrato',
      () {
        // SETUP: Registra solo int, non String
        SingletonManager.instance.register<int>(30);

        final service = ServiceConfigGenerated();

        // RUN: initializeDI() - DEVE CRASHARE con StateError
        expect(() {
          service.initializeDI();
        }, throwsA(isA<StateError>()));
      },
    );

    test(
      'ServiceConfigGenerated.initializeDI() CRASHA quando int non è registrato',
      () {
        // SETUP: Registra solo String, non int
        SingletonManager.instance.register<String>('prod');

        final service = ServiceConfigGenerated();

        // RUN: initializeDI() - DEVE CRASHARE con StateError
        expect(() {
          service.initializeDI();
        }, throwsA(isA<StateError>()));
      },
    );

    test(
      'ServiceC.initializeDI() CRASHA quando DatabaseConnection non è registrato',
      () {
        // SETUP: Non registro DatabaseConnection

        final service = ServiceC();

        // RUN: initializeDI() - DEVE CRASHARE con StateError
        expect(() {
          service.initializeDI();
        }, throwsA(isA<StateError>()));
      },
    );
  });
}
