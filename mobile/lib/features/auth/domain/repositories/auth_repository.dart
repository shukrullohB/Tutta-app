import '../models/auth_user.dart';

abstract interface class AuthRepository {
  Future<AuthUser> login({
    required String email,
    required String password,
  });

  Future<AuthUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phoneNumber,
  });

  Future<AuthUser> me();

  Future<Map<String, String>> refresh({
    required String refreshToken,
  });

  Future<void> signOut({
    required String refreshToken,
  });
}
