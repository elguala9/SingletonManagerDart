import 'package:singleton_manager/singleton_manager.dart';

@isSingleton
class MyService {
  @isInjected
  late String apiKey;

  @isInjected
  late DatabaseService db;
}

class DatabaseService {}
