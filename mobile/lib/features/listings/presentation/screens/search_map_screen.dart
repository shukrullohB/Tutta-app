import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/utils/google_maps_launcher.dart';
import '../../application/search_controller.dart';
import '../../domain/models/listing.dart';

class SearchMapScreen extends ConsumerWidget {
  const SearchMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(searchControllerProvider).items;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.search),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Google Maps'),
      ),
      body: items.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No listings to show on map for current filters.'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4EC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE8DCCB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.map_outlined, color: Color(0xFF374151)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Google Maps mode',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Open any stay in Google Maps directly from this list.',
                        style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () =>
                            _openListingInMaps(context, items.first),
                        icon: const Icon(Icons.place_outlined),
                        label: const Text('Open first result in Google Maps'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      tileColor: const Color(0xFFFDF9F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE7DCCB)),
                      ),
                      leading: const Icon(Icons.place_outlined),
                      title: Text(item.title),
                      subtitle: Text(_locationLabel(item)),
                      trailing: IconButton(
                        tooltip: 'Open in Google Maps',
                        onPressed: () => _openListingInMaps(context, item),
                        icon: const Icon(Icons.map_outlined),
                      ),
                      onTap: () =>
                          context.push(RouteNames.listingDetailsById(item.id)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _openListingInMaps(BuildContext context, Listing item) async {
    final query = <String>[
      item.title,
      item.city,
      item.district,
      item.landmark ?? '',
      item.metro ?? '',
      'Uzbekistan',
    ].where((part) => part.trim().isNotEmpty).join(', ');

    final opened = await openGoogleMaps(query: query);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Maps.')),
      );
    }
  }
}

String _locationLabel(Listing item) {
  final district = item.district.trim();
  if (district.isEmpty) {
    return item.city;
  }
  return '${item.city}, $district';
}
