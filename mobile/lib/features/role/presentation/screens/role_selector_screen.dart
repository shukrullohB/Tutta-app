import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/enums/app_role.dart';
import '../../../home/application/app_session_controller.dart';

class RoleSelectorScreen extends ConsumerWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose mode')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'How do you want to use Tutta?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text('You can switch roles later in profile settings.'),
            const SizedBox(height: 20),
            _RoleCard(
              title: 'Find a place to stay',
              subtitle: 'Renter mode',
              icon: Icons.travel_explore,
              onTap: () {
                ref
                    .read(appSessionControllerProvider.notifier)
                    .setRole(AppRole.renter);
                context.go(RouteNames.home);
              },
            ),
            _RoleCard(
              title: 'Host a room or apartment',
              subtitle: 'Host mode',
              icon: Icons.home_work_outlined,
              onTap: () {
                ref
                    .read(appSessionControllerProvider.notifier)
                    .setRole(AppRole.host);
                context.go(RouteNames.home);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
