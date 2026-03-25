import '../../../../core/errors/app_exception.dart';
import '../../../premium/domain/models/subscription_plan.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/otp_auth_repository.dart';

class FakeOtpAuthRepository implements OtpAuthRepository {
  static const devCode = '123456';

  @override
  Future<void> sendOtp({required String phone}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!_isValidUzPhone(phone)) {
      throw const AppException('Invalid phone number. Use +998XXXXXXXXX.');
    }
  }

  @override
  Future<AuthUser> verifyOtp({
    required String phone,
    required String code,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!_isValidUzPhone(phone)) {
      throw const AppException('Invalid phone number.');
    }

    if (code != devCode) {
      throw const AppException('Invalid code');
    }

    return AuthUser(
      id: 'otp_demo_user_1',
      email: 'otp.demo@tutta.uz',
      role: 'guest',
      firstName: 'Dev',
      lastName: 'User',
      phone: phone,
      subscriptionPlan: SubscriptionPlan.free,
      countryCode: 'UZ',
      accessToken: 'otp_dev_access_token',
      refreshToken: 'otp_dev_refresh_token',
    );
  }

  bool _isValidUzPhone(String phone) {
    final normalized = phone.trim();
    return RegExp(r'^\+998\d{9}$').hasMatch(normalized);
  }
}
