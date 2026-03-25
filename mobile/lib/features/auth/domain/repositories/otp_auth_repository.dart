import '../models/auth_user.dart';

abstract interface class OtpAuthRepository {
  Future<void> sendOtp({required String phone});

  Future<AuthUser> verifyOtp({required String phone, required String code});
}
