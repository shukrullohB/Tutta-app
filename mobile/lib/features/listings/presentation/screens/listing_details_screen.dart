import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/application/auth_controller.dart';
import '../../application/search_controller.dart';
import '../../domain/models/listing.dart';

class ListingDetailsScreen extends ConsumerWidget {
  const ListingDetailsScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<Listing?>(
      future: ref.read(listingsRepositoryProvider).getById(listingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final listing = snapshot.data;
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Listing')),
            body: const Center(child: Text('Listing not found.')),
          );
        }

        final hasPremium =
            ref.watch(authControllerProvider).valueOrNull?.user?.isPremium ??
            false;

        final freeStayLocked =
            listing.type == ListingType.freeStay && !hasPremium;

        return Scaffold(
          appBar: AppBar(title: Text(listing.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${listing.city}, ${listing.district}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(listing.description ?? 'No description yet.'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('Max guests: ${listing.maxGuests}')),
                          Chip(label: Text('Min days: ${listing.minDays}')),
                          Chip(label: Text('Max days: ${listing.maxDays}')),
                          Chip(
                            label: Text(
                              listing.nightlyPriceUzs == null
                                  ? 'Free stay'
                                  : '${listing.nightlyPriceUzs} UZS / night',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (freeStayLocked)
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.workspace_premium_outlined),
                    title: const Text('Premium required'),
                    subtitle: const Text(
                      'Free Stay bookings are available only for Premium users.',
                    ),
                    trailing: TextButton(
                      onPressed: () => context.push(RouteNames.premiumPaywall),
                      child: const Text('Upgrade'),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: freeStayLocked
                    ? null
                    : () {
                        context.push(
                          '${RouteNames.bookingRequest}/${listing.id}',
                        );
                      },
                child: const Text('Request booking'),
              ),
            ],
          ),
        );
      },
    );
  }
}
