import '../entities/login_methods_entity.dart';

abstract class LoginMethodsRepository {
  Future<LoginMethodsEntity> getLoginMethods();
}
