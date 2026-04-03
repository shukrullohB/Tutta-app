import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/runtime_flags.dart';
import '../../../core/network/api_client.dart';
import '../data/repositories/api_notifications_repository.dart';
import '../data/repositories/fake_notifications_repository.dart';
import '../domain/models/app_notification.dart';
import '../domain/repositories/notifications_repository.dart';

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  if (!RuntimeFlags.useFakeNotifications) {
    return ApiNotificationsRepository(ref.watch(apiClientProvider));
  }
  return FakeNotificationsRepository();
});

class NotificationsController extends StateNotifier<AsyncValue<List<AppNotification>>> {
  NotificationsController(this._read) : super(const AsyncValue.loading()) {
    load();
  }

  final Ref _read;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final items = await _read.read(notificationsRepositoryProvider).list();
      state = AsyncValue.data(items);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> markRead(String notificationId) async {
    final current = state.valueOrNull ?? const <AppNotification>[];
    try {
      await _read.read(notificationsRepositoryProvider).markRead(notificationId);
      state = AsyncValue.data(
        current
            .map(
              (item) => item.id == notificationId
                  ? AppNotification(
                      id: item.id,
                      type: item.type,
                      title: item.title,
                      body: item.body,
                      isRead: true,
                      createdAt: item.createdAt,
                      payload: item.payload,
                    )
                  : item,
            )
            .toList(growable: false),
      );
    } catch (_) {
      // Keep current state untouched on best-effort failures.
    }
  }

  Future<void> markAllRead() async {
    final current = state.valueOrNull ?? const <AppNotification>[];
    try {
      await _read.read(notificationsRepositoryProvider).markAllRead();
      state = AsyncValue.data(
        current
            .map(
              (item) => AppNotification(
                id: item.id,
                type: item.type,
                title: item.title,
                body: item.body,
                isRead: true,
                createdAt: item.createdAt,
                payload: item.payload,
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {
      // Keep current state untouched on best-effort failures.
    }
  }
}

final notificationsControllerProvider = StateNotifierProvider<
    NotificationsController, AsyncValue<List<AppNotification>>>((ref) {
  return NotificationsController(ref);
});
