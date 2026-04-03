import '../../domain/models/app_notification.dart';
import '../../domain/repositories/notifications_repository.dart';

class FakeNotificationsRepository implements NotificationsRepository {
  static final List<AppNotification> _items = <AppNotification>[
    AppNotification(
      id: 'n1',
      type: 'system',
      title: 'Welcome to Tutta',
      body: 'Your account is ready. Start searching in Uzbekistan.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AppNotification(
      id: 'n2',
      type: 'booking_confirmed',
      title: 'Booking confirmed',
      body: 'Host approved your recent booking request.',
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      payload: <String, dynamic>{'bookingId': 'b-demo'},
    ),
  ];

  @override
  Future<List<AppNotification>> list() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
    return _items.toList(growable: false);
  }

  @override
  Future<void> markRead(String notificationId) async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.id == notificationId && !item.isRead) {
        _items[i] = AppNotification(
          id: item.id,
          type: item.type,
          title: item.title,
          body: item.body,
          isRead: true,
          createdAt: item.createdAt,
          payload: item.payload,
        );
      }
    }
  }

  @override
  Future<void> markAllRead() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (!item.isRead) {
        _items[i] = AppNotification(
          id: item.id,
          type: item.type,
          title: item.title,
          body: item.body,
          isRead: true,
          createdAt: item.createdAt,
          payload: item.payload,
        );
      }
    }
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
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }

  @override
  Future<void> unregisterDeviceToken(String token) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
  }
}
