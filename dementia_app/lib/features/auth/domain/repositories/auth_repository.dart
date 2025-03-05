import 'package:dementia_app/features/auth/domain/entities/user_model.dart';

abstract class AuthRepository {
  Future<UserModel> signUpWithEmail(
    String email,
    String password,
    String firstName,
    String lastName,
    String dob,
    String gender,
  );

  Future<UserModel> loginWithEmail(String email, String password);

  Future<void> logout();

  Future<UserModel?> getUserFromSecureStorage();
}
