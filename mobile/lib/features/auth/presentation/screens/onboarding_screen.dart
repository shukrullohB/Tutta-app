import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../home/application/app_session_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Tutta',
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Short-term rentals in Uzbekistan only.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              const _ValueTile(
                title: 'Find rooms, apartments, and shared homes',
                subtitle: 'Up to 30 days per booking',
              ),
              const _ValueTile(
                title: 'Switch between renter and host modes',
                subtitle: 'One account, both roles',
              ),
              const _ValueTile(
                title: 'Free Stay / Language Exchange',
                subtitle: 'Premium access for renters',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  ref
                      .read(appSessionControllerProvider.notifier)
                      .completeOnboarding();
                  context.go(RouteNames.auth);
                },
                child: const Text('Get started'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
