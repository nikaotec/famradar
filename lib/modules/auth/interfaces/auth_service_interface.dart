// lib/modules/auth/interfaces/auth_service_interface.dart


import 'package:famradar/models/user_model.dart';

abstract class AuthServiceInterface {
  Future<UserModel?> signInWithEmail(String email, String password);
  Future<UserModel?> signInWithPhone(String phone, String password);
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String phone,
    required String password,
    String? photoPath,
  });
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
}
