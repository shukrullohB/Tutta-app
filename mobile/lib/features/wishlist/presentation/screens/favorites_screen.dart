import 'package:flutter/material.dart';

import '../../../../core/widgets/empty_state_view.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: const EmptyStateView(
        title: 'No favorites yet',
        subtitle: 'Save listings to compare options later.',
      ),
    );
  }
}
