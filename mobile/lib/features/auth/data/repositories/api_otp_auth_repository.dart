import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../../premium/domain/models/subscription_plan.dart';
import '../../domain/models/auth_user.dart';
import '../../domain/repositories/otp_auth_repository.dart';

class ApiOtpAuthRepository implements OtpAuthRepository {
  const ApiOtpAuthRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> sendOtp({required String phone}) async {
    final result = await _apiClient.post(
      ApiEndpoints.authOtpRequest,
      data: <String, dynamic>{'phone': phone},
    );

    result.when(success: (_) => null, failure: _throwFailure);
  }

  @override
  Future<AuthUser> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.authOtpVerify,
      data: <String, dynamic>{'phone': phone, 'code': code},
    );

    return result.when(
      success: (data) {
        final payload = ApiResponseParser.extractMap(data);
        final userPayload = payload['user'] is Map<String, dynamic>
            ? payload['user'] as Map<String, dynamic>
            : payload;

        return _mapUser(
          userPayload,
          accessToken: payload['access'] as String?,
          refreshToken: payload['refresh'] as String?,
        );
      },
      failure: _throwFailure,
    );
  }

  AuthUser _mapUser(
    Map<String, dynamic> payload, {
    String? accessToken,
    String? refreshToken,
  }) {
    final id = payload['id']?.toString() ?? 'otp_user';

    return AuthUser(
      id: id,
      email: (payload['email'] as String?) ?? 'otp.user@tutta.uz',
      role: (payload['role'] as String?) ?? 'guest',
      firstName: (payload['first_name'] as String?) ?? 'OTP',
      lastName: (payload['last_name'] as String?) ?? 'User',
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
