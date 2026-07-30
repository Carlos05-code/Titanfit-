import '../models/user_model.dart';

class AuthRepositoryImpl {
  Future<UserModel> login(String email, String password) async {
    throw UnimplementedError('login not implemented');
  }

  Future<void> register(String email, String password, String name) async {
    throw UnimplementedError('register not implemented');
  }

  Future<void> logout() async {
    throw UnimplementedError('logout not implemented');
  }
}
