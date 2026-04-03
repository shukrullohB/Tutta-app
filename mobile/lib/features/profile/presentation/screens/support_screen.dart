import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(RouteNames.home),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              title: const Text('Help center'),
              subtitle: const Text('FAQs for renters and hosts'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Help center articles will be connected soon.'),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Contact support'),
              subtitle: const Text('Response within 24 hours'),
              onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Support chat is coming soon. Try again later.'),
                ),
              ),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Report listing'),
              subtitle: const Text('Moderation and safety reports'),
              onTap: () => context.go(RouteNames.notifications),
            ),
          ),
        ],
      ),
    );
  }
}
