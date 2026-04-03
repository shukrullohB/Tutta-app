import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../application/notifications_controller.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsControllerProvider);
    final notifier = ref.read(notificationsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.home),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => notifier.markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Failed to load notifications'),
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: notifier.load,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }
          return RefreshIndicator(
            onRefresh: notifier.load,
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  onTap: () => notifier.markRead(item.id),
                  leading: Icon(
                    item.isRead
                        ? Icons.notifications_none_outlined
                        : Icons.notifications_active_outlined,
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(item.body),
                  trailing: item.isRead
                      ? null
                      : const Icon(Icons.circle, size: 10, color: Colors.blue),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
