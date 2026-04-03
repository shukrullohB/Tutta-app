import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/router/route_names.dart';
import '../../../../core/enums/app_role.dart';
import '../../../home/application/app_session_controller.dart';

class RoleSelectorScreen extends ConsumerWidget {
  const RoleSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                onPressed: () => context.go(RouteNames.auth),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.primaryDeep,
                ),
              ),
            ),
            const Text(
              'Choose mode',
              style: TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDeep,
              ),
            ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.08, end: 0),
            const SizedBox(height: 28),
            const Text(
              'How do you want to use Tutta?',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ).animate(delay: 60.ms).fadeIn(duration: 220.ms),
            const SizedBox(height: 10),
            const Text(
              'You can switch roles later in profile settings.',
              style: TextStyle(fontSize: 16, color: AppColors.textMuted),
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
          colors: [AppColors.surface, AppColors.surfaceTint],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10E36A3A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
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
                    color: AppColors.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryDeep, size: 20),
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
                          color: AppColors.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 28,
                  color: AppColors.primaryDeep,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
