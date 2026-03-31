import '../../../../core/errors/app_exception.dart';
import '../../../premium/domain/models/subscription_plan.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  static const _demoEmail = 'demo@tutta.uz';
  static const _demoPassword = 'DemoPass123!';
  AuthUser? _currentUser;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (email != _demoEmail || password != _demoPassword) {
      throw const AppException('Invalid demo credentials.');
    }
    _currentUser = _demoUser(
      email: email,
      accessToken: 'demo_access_token_user_demo_1',
      refreshToken: 'demo_refresh_token_user_demo_1',
    );
    return _currentUser!;
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
    _currentUser = AuthUser(
      id: 'user_demo_1',
      email: email,
      role: role,
      firstName: firstName,
      lastName: lastName,
      phone: phoneNumber,
      subscriptionPlan: SubscriptionPlan.free,
      countryCode: 'UZ',
    );
    return _currentUser!;
  }

  @override
  Future<AuthUser> me() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    _currentUser ??= _demoUser(
      email: _demoEmail,
      accessToken: 'demo_access_token_user_demo_1',
      refreshToken: 'demo_refresh_token_user_demo_1',
    );
    return _currentUser!;
  }

  @override
  Future<AuthUser> signInWithGoogle({
    required String idToken,
    String? accessToken,
    String? email,
    String? displayName,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    final resolvedEmail = (email != null && email.trim().isNotEmpty)
        ? email
        : _demoEmail;
    final names = (displayName ?? 'Google User').trim().split(RegExp(r'\s+'));
    final firstName = names.isNotEmpty ? names.first : 'Google';
    final lastName = names.length > 1 ? names.sublist(1).join(' ') : 'User';

    _currentUser = AuthUser(
      id: 'user_google_demo_1',
      email: resolvedEmail,
      role: 'guest',
      firstName: firstName,
      lastName: lastName,
      phone: '+998901112233',
      subscriptionPlan: SubscriptionPlan.free,
      countryCode: 'UZ',
      accessToken: accessToken ?? 'demo_google_access_token_user_google_demo_1',
      refreshToken: 'demo_google_refresh_token_user_google_demo_1',
    );
    return _currentUser!;
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
    _currentUser = null;
  }

  @override
  Future<AuthUser> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final current =
        _currentUser ??
        _demoUser(
          email: _demoEmail,
          accessToken: 'demo_access_token_user_demo_1',
          refreshToken: 'demo_refresh_token_user_demo_1',
        );
    _currentUser = AuthUser(
      id: current.id,
      email: current.email,
      role: current.role,
      firstName: firstName,
      lastName: lastName,
      phone: phoneNumber?.trim().isEmpty == true ? null : phoneNumber,
      subscriptionPlan: current.subscriptionPlan,
      countryCode: current.countryCode,
      accessToken: current.accessToken,
      refreshToken: current.refreshToken,
    );
    return _currentUser!;
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
