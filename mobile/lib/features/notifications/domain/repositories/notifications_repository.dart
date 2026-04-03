import '../models/app_notification.dart';

abstract interface class NotificationsRepository {
  Future<List<AppNotification>> list();

  Future<void> markRead(String notificationId);

  Future<void> markAllRead();

  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
    String? appVersion,
    String? locale,
    String? timezone,
  });

  Future<void> unregisterDeviceToken(String token);
}
