import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../../premium/domain/models/subscription_plan.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

class ApiAuthRepository implements AuthRepository {
  const ApiAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.authLogin,
      data: <String, dynamic>{'email': email, 'password': password},
    );

    return result.when(
      success: (data) {
        final payload = ApiResponseParser.extractMap(data);
        final user = payload['user'];
        if (user is! Map<String, dynamic>) {
          throw const AppException(
            'Invalid login response: missing user object.',
          );
        }

        return _mapUser(
          user,
          accessToken: payload['access'] as String?,
          refreshToken: payload['refresh'] as String?,
        );
      },
      failure: _throwFailure,
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
    final result = await _apiClient.post(
      ApiEndpoints.authRegister,
      data: <String, dynamic>{
        'email': email,
        'password': password,
        'password_confirm': password,
        'first_name': firstName,
        'last_name': lastName,
        'role': role,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
      },
    );

    return result.when(
      success: (data) {
        final payload = ApiResponseParser.extractMap(data);
        return _mapUser(payload);
      },
      failure: _throwFailure,
    );
  }

  @override
  Future<AuthUser> me() async {
    final result = await _apiClient.get(ApiEndpoints.usersMe);

    return result.when(
      success: (data) => _mapUser(ApiResponseParser.extractMap(data)),
      failure: _throwFailure,
    );
  }

  @override
  Future<AuthUser> signInWithGoogle({
    required String idToken,
    String? accessToken,
    String? email,
    String? displayName,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.authGoogle,
      data: <String, dynamic>{
        'id_token': idToken,
        if (accessToken != null && accessToken.isNotEmpty)
          'access_token': accessToken,
        if (email != null && email.isNotEmpty) 'email': email,
        if (displayName != null && displayName.isNotEmpty)
          'display_name': displayName,
      },
    );

    return result.when(
      success: (data) {
        final payload = ApiResponseParser.extractMap(data);
        final user = payload['user'];
        if (user is! Map<String, dynamic>) {
          throw const AppException(
            'Invalid Google login response: missing user object.',
          );
        }

        return _mapUser(
          user,
          accessToken: payload['access'] as String?,
          refreshToken: payload['refresh'] as String?,
        );
      },
      failure: _throwFailure,
    );
  }

  @override
  Future<Map<String, String>> refresh({required String refreshToken}) async {
    final result = await _apiClient.post(
      ApiEndpoints.authRefresh,
      data: <String, dynamic>{'refresh': refreshToken},
    );

    return result.when(
      success: (data) {
        final payload = ApiResponseParser.extractMap(data);
        final access = payload['access'] as String?;
        final refresh = (payload['refresh'] as String?) ?? refreshToken;

        if (access == null || access.isEmpty) {
          throw const AppException(
            'Invalid refresh response: missing access token.',
          );
        }

        return <String, String>{'access': access, 'refresh': refresh};
      },
      failure: _throwFailure,
    );
  }

  @override
  Future<void> signOut({required String refreshToken}) async {
    final result = await _apiClient.post(
      ApiEndpoints.authLogout,
      data: <String, dynamic>{'refresh': refreshToken},
    );
    result.when(success: (_) => null, failure: _throwFailure);
  }

  AuthUser _mapUser(
    Map<String, dynamic> payload, {
    String? accessToken,
    String? refreshToken,
  }) {
    final id = payload['id']?.toString() ?? '';
    if (id.isEmpty) {
      throw const AppException('Invalid auth response: missing user id.');
    }

    final firstName = (payload['first_name'] as String?) ?? '';
    final lastName = (payload['last_name'] as String?) ?? '';
    return AuthUser(
      id: id,
      email: (payload['email'] as String?) ?? '',
      role: (payload['role'] as String?) ?? 'guest',
      firstName: firstName,
      lastName: lastName,
      phone: payload['phone_number'] as String?,
      countryCode: 'UZ',
      subscriptionPlan: _subscriptionFromRaw(payload['subscriptionPlan']),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  SubscriptionPlan _subscriptionFromRaw(Object? rawValue) {
    if (rawValue is String) {
      final normalized = rawValue.toLowerCase().trim();
      for (final value in SubscriptionPlan.values) {
        if (value.name == normalized) {
          return value;
        }
      }
    }

    return SubscriptionPlan.free;
  }

  Never _throwFailure(Failure failure) {
    throw AppException(
      failure.message,
      code: failure.code,
      statusCode: failure.statusCode,
    );
  }
}
