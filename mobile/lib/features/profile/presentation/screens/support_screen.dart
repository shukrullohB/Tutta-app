import 'package:flutter/material.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Card(
            child: ListTile(
              title: Text('Help center'),
              subtitle: Text('FAQs for renters and hosts'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Contact support'),
              subtitle: Text('Response within 24 hours'),
            ),
          ),
          Card(
            child: ListTile(
              title: Text('Report listing'),
              subtitle: Text('Moderation and safety reports'),
            ),
          ),
        ],
      ),
    );
  }
}
