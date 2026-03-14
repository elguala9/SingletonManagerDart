// ignore: one_member_abstracts
abstract interface class ISingletonDI<ReturnType> {
  Future<ReturnType> initializeDI();
}

abstract interface class ISingletonStandardDI extends ISingletonDI<void> {
  @override
  Future<void> initializeDI();
}

abstract interface class ISingleton<InitializeType, ReturnType>
    extends ISingletonDI<ReturnType> {
  Future<ReturnType> initialize(InitializeType input);
}

abstract interface class ISingletonStandard<InitializeType>
    extends ISingleton<InitializeType, void> {
  @override
  Future<void> initialize(InitializeType input);
}
