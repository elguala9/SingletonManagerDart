abstract interface class ISingleton<InitializeType, ReturnType> {
  Future<ReturnType> initialize(InitializeType input);
  Future<ReturnType> initializeDI();
}
