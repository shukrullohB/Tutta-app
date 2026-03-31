import 'package:flutter/material.dart';

class PremiumPaywallScreen extends StatelessWidget {
  const PremiumPaywallScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutta Premium')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Unlock Free Stay search',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Premium gives access to Free Stay / Language Exchange listings and early features.',
            ),
            const SizedBox(height: 20),
            const Card(
              child: ListTile(
                title: Text('Premium Monthly'),
                subtitle: Text('Click / Payme integration in Phase 3'),
                trailing: Text('TBD UZS'),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () {},
              child: const Text('Continue to payment'),
            ),
          ],
        ),
      ),
    );
  }
}
