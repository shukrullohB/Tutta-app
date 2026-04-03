import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => context.go(RouteNames.auth),
                icon: const Icon(Icons.arrow_back, color: Color(0xFF072A73)),
              ),
            ),
            const Text(
              'Choose mode',
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w700,
                color: Color(0xFF072A73),
              ),
            ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: 28),
            const Text(
              'How do you want to use Tutta?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B2336),
              ),
            ).animate(delay: 60.ms).fadeIn(duration: 220.ms),
            const SizedBox(height: 10),
            const Text(
              'You can switch roles later in profile settings.',
              style: TextStyle(fontSize: 16, color: Color(0xFF4E566A)),
            ).animate(delay: 90.ms).fadeIn(duration: 220.ms),
            const SizedBox(height: 22),
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
                )
                .animate(delay: 130.ms)
                .fadeIn(duration: 240.ms)
                .slideY(begin: 0.07, end: 0),
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
                )
                .animate(delay: 180.ms)
                .fadeIn(duration: 240.ms)
                .slideY(begin: 0.07, end: 0),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FA), Color(0xFFE4EBF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFCBD6EA)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCFD9EE),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF1F2E52), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF172547),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF4F5D78),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 28,
                  color: Color(0xFF22335A),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
