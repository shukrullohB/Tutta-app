import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class ApiNotificationsRepository implements NotificationsRepository {
  const ApiNotificationsRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<List<AppNotification>> list() async {
    final result = await _apiClient.get(ApiEndpoints.notifications);
    return result.when(
      success: (data) => ApiResponseParser.extractList(data)
          .map(_map)
          .toList(growable: false),
      failure: _throwFailure,
    );
  }

  @override
  Future<void> markRead(String notificationId) async {
    final result = await _apiClient.post(
      ApiEndpoints.notificationMarkRead(notificationId),
      data: const <String, dynamic>{},
    );
    result.when(success: (_) => null, failure: _throwFailure);
  }

  @override
  Future<void> markAllRead() async {
    final result = await _apiClient.post(
      ApiEndpoints.notificationsMarkAllRead(),
      data: const <String, dynamic>{},
    );
    result.when(success: (_) => null, failure: _throwFailure);
  }

  @override
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
    String? locale,
    String? timezone,
  }) async {
    final result = await _apiClient.post(
      ApiEndpoints.notificationsDeviceRegister(),
      data: <String, dynamic>{
        'token': token,
        'platform': platform,
        if ((deviceId ?? '').trim().isNotEmpty) 'device_id': deviceId!.trim(),
        if ((appVersion ?? '').trim().isNotEmpty)
          'app_version': appVersion!.trim(),
        if ((locale ?? '').trim().isNotEmpty) 'locale': locale!.trim(),
        if ((timezone ?? '').trim().isNotEmpty) 'timezone': timezone!.trim(),
      },
    );
    result.when(success: (_) => null, failure: _throwFailure);
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    final result = await _apiClient.post(
      ApiEndpoints.notificationsDeviceUnregister(),
      data: <String, dynamic>{'token': token},
    );
    result.when(success: (_) => null, failure: _throwFailure);
  }

  AppNotification _map(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'].toString(),
      type: json['type']?.toString() ?? 'system',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      isRead: json['is_read'] == true,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : const <String, dynamic>{},
    );
  }

  Never _throwFailure(Failure failure) {
    throw AppException(
      failure.message,
      code: failure.code,
      statusCode: failure.statusCode,
    );
  }
}
