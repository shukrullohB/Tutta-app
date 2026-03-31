import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../application/search_controller.dart';
import '../../domain/models/listing.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _cityController;
  late final TextEditingController _districtController;

  @override
  void initState() {
    super.initState();
    final state = ref.read(searchControllerProvider);
    _cityController = TextEditingController(text: state.city);
    _districtController = TextEditingController(text: state.district);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchControllerProvider.notifier).search();
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Search stays')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'City'),
            onChanged: ref.read(searchControllerProvider.notifier).setCity,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _districtController,
            decoration: const InputDecoration(labelText: 'District'),
            onChanged: ref.read(searchControllerProvider.notifier).setDistrict,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Guests'),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: state.guests,
                items: List.generate(
                  8,
                  (index) => DropdownMenuItem(
                    value: index + 1,
                    child: Text('${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(searchControllerProvider.notifier)
                        .setGuests(value);
                  }
                },
              ),
            ],
          ),
          SwitchListTile(
            value: state.includeFreeStay,
            onChanged: ref
                .read(searchControllerProvider.notifier)
                .setIncludeFreeStay,
            title: const Text('Include Free Stay / Language Exchange'),
            subtitle: const Text('Requires Premium for renters'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: state.loading
                ? null
                : ref.read(searchControllerProvider.notifier).search,
            child: Text(state.loading ? 'Searching...' : 'Search'),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 10),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(state.errorMessage!),
              ),
            ),
            if (state.errorMessage!.contains('Premium'))
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => context.push(RouteNames.premiumPaywall),
                  child: const Text('Open Premium plans'),
                ),
              ),
          ],
          const SizedBox(height: 18),
          Text(
            'Results (${state.items.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (!state.loading && state.items.isEmpty)
            const _ResultsEmpty()
          else
            ...state.items.map((listing) => _ListingCard(listing: listing)),
        ],
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final priceLabel = listing.nightlyPriceUzs == null
        ? 'Free stay'
        : '${listing.nightlyPriceUzs} UZS/night';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(listing.title),
        subtitle: Text('${listing.city}, ${listing.district} • $priceLabel'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('${RouteNames.listingDetails}/${listing.id}'),
      ),
    );
  }
}

class _ResultsEmpty extends StatelessWidget {
  const _ResultsEmpty();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'No listings found. Try changing city, district, or filters.',
        ),
      ),
    );
  }
}
