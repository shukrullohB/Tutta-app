import '../../../../core/errors/app_exception.dart';
import '../../../premium/domain/models/subscription_plan.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  static const _demoEmail = 'demo@tutta.uz';
  static const _demoPassword = 'DemoPass123!';

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (email != _demoEmail || password != _demoPassword) {
      throw const AppException('Invalid demo credentials.');
    }
    return _demoUser(
      email: email,
      accessToken: 'demo_access_token_user_demo_1',
      refreshToken: 'demo_refresh_token_user_demo_1',
    );
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phoneNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 550));
    if (email.trim().isEmpty || password.length < 8) {
      throw const AppException('Invalid register payload for demo mode.');
    }
    return AuthUser(
      id: 'user_demo_1',
      email: email,
      role: role,
      firstName: firstName,
      lastName: lastName,
      phone: phoneNumber,
      subscriptionPlan: SubscriptionPlan.free,
      countryCode: 'UZ',
    );
  }

  @override
  Future<AuthUser> me() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _demoUser(
      email: _demoEmail,
      accessToken: 'demo_access_token_user_demo_1',
      refreshToken: 'demo_refresh_token_user_demo_1',
    );
  }

  @override
  Future<Map<String, String>> refresh({required String refreshToken}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (refreshToken.isEmpty) {
      throw const AppException('Refresh token is required.');
    }
    return <String, String>{
      'access': 'demo_access_token_user_demo_1_rotated',
      'refresh': 'demo_refresh_token_user_demo_1_rotated',
    };
  }

  @override
  Future<void> signOut({required String refreshToken}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  AuthUser _demoUser({
    required String email,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthUser(
      id: 'user_demo_1',
      email: email,
      role: 'guest',
      firstName: 'Tutta',
      lastName: 'User',
      phone: '+998901112233',
      subscriptionPlan: SubscriptionPlan.free,
      countryCode: 'UZ',
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
