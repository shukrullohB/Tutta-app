import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  int _gridColumns = 2;

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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.menu, color: Color(0xFF072A73)),
                        const SizedBox(width: 14),
                        const Text(
                          'Tutta',
                          style: TextStyle(
                            color: Color(0xFF072A73),
                            fontSize: 38 / 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFFF3CDAD),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Color(0xFFB78664),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EAEE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: TextField(
                        controller: _cityController,
                        style: const TextStyle(color: Color(0xFF151A26)),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF707788),
                          ),
                          hintText: 'Paris, France',
                          hintStyle: TextStyle(color: Color(0xFF707788)),
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: ref
                            .read(searchControllerProvider.notifier)
                            .setCity,
                        onSubmitted: (_) => ref
                            .read(searchControllerProvider.notifier)
                            .search(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE9EAEE),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.list,
                                          size: 14,
                                          color: Color(0xFF475068),
                                        ),
                                        SizedBox(width: 6),
                                        Text('List'),
                                      ],
                                    ),
                                  ),
                                ),
                                const Expanded(
                                  child: SizedBox(
                                    height: 32,
                                    child: Center(child: Text('Map')),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        _FilterPill(
                          label: 'Filters',
                          icon: Icons.tune,
                          onTap: () => _openFiltersSheet(context, state),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _FilterPill(
                          label: state.includeFreeStay
                              ? 'Free Stay on'
                              : 'Free Stay off',
                          icon: Icons.swap_horiz,
                          onTap: () => ref
                              .read(searchControllerProvider.notifier)
                              .setIncludeFreeStay(!state.includeFreeStay),
                        ),
                        _FilterPill(
                          label: 'Guests: ${state.guests}',
                          icon: Icons.people_outline,
                          onTap: () => _pickGuests(context, state.guests),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.1, end: 0),
            ),
            if (state.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Card(
                    color: const Color(0x33FF6E6E),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(state.errorMessage!),
                          if (state.errorMessage!.contains('Premium'))
                            TextButton(
                              onPressed: () =>
                                  context.push(RouteNames.premiumPaywall),
                              child: const Text('Open Premium plans'),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Row(
                  children: [
                    Text('Results', style: theme.textTheme.titleMedium),
                    const Spacer(),
                    Text(
                      '${state.items.length} stays',
                      style: const TextStyle(
                        color: Color(0xFF6D7280),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 140.ms, duration: 260.ms),
            ),
            if (!state.loading && state.items.isEmpty)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14, 8, 14, 32),
                  child: _ResultsEmpty(),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final listing = state.items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child:
                          _SearchListingTile(
                                listing: listing,
                                onTap: () => context.push(
                                  '${RouteNames.listingDetails}/${listing.id}',
                                ),
                              )
                              .animate(delay: (50 * (index.clamp(0, 8))).ms)
                              .fadeIn(duration: 280.ms)
                              .slideY(begin: 0.08, end: 0),
                    );
                  }, childCount: state.items.length),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 6, 14, 12),
        child: FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.map_outlined),
          label: const Text('Show Map'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(160, 50),
            backgroundColor: const Color(0xFF072A73),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickGuests(BuildContext context, int selected) async {
    final value = await showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              8,
              (index) => ListTile(
                title: Text('${index + 1} guest${index == 0 ? '' : 's'}'),
                trailing: selected == index + 1
                    ? const Icon(Icons.check)
                    : null,
                onTap: () => Navigator.of(context).pop(index + 1),
              ),
            ),
          ),
        );
      },
    );
    if (value != null) {
      ref.read(searchControllerProvider.notifier).setGuests(value);
      ref.read(searchControllerProvider.notifier).search();
    }
  }

  Future<void> _openFiltersSheet(
    BuildContext context,
    SearchState state,
  ) async {
    final districtController = TextEditingController(text: state.district);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: districtController,
                decoration: const InputDecoration(labelText: 'District'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Apply'),
              ),
            ],
          ),
        );
      },
    );
    if (result == true) {
      ref
          .read(searchControllerProvider.notifier)
          .setDistrict(districtController.text.trim());
      ref.read(searchControllerProvider.notifier).search();
    }
    districtController.dispose();
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF0F3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: const Color(0xFF4A5163)),
            const SizedBox(width: 7),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _SearchListingTile extends StatelessWidget {
  const _SearchListingTile({required this.listing, required this.onTap});

  final Listing listing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.imageUrls.isEmpty ? null : listing.imageUrls.first;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE1E3E8)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.55,
                  child: _ListingImage(imageUrl: imageUrl, listing: listing),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: const BoxDecoration(
                      color: Color(0xF7FFFFFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Color(0xFF072A73),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 34 / 2,
                            color: Color(0xFF071E57),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        listing.nightlyPriceUzs == null
                            ? 'Free'
                            : '€${((listing.nightlyPriceUzs ?? 0) / 15000).round()}',
                        style: const TextStyle(
                          color: Color(0xFF6A480A),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        '/night',
                        style: TextStyle(color: Color(0xFF7B8191)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${listing.district}, ${listing.city}',
                    style: const TextStyle(color: Color(0xFF4E5568)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({
    required this.listing,
    required this.index,
    required this.total,
    required this.onTap,
  });

  final Listing listing;
  final int index;
  final int total;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.imageUrls.isEmpty ? null : listing.imageUrls.first;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x1FFFFFFF)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 18,
              offset: Offset(0, 12),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: _ListingImage(imageUrl: imageUrl, listing: listing),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x26C8A84B),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Color(0xFFC8A84B),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      listing.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xCCFFFFFF),
                      ),
                    ),
                  ),
                  if (total > 0)
                    Text(
                      '${index + 1}/$total',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0x669FA1B3),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.imageUrl, required this.listing});

  final String? imageUrl;
  final Listing listing;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Image.network(
        imageUrl!,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(),
      );
    }

    return _imageFallback();
  }

  Widget _imageFallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF222436), Color(0xFF151726)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.home_work_outlined, size: 30),
              const SizedBox(height: 8),
              Text(
                '${listing.city}, ${listing.district}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Color(0xE6FFFFFF)),
              ),
              const SizedBox(height: 6),
              Text(
                listing.nightlyPriceUzs == null
                    ? 'Free Stay / Exchange'
                    : '${listing.nightlyPriceUzs} UZS / night',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Color(0xB39FA1B3)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ColumnsButton extends StatelessWidget {
  const _ColumnsButton({
    required this.title,
    required this.active,
    required this.onTap,
  });

  final String title;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: 160.ms,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0x26C8A84B) : const Color(0x1AFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? const Color(0xFFC8A84B) : const Color(0x1FFFFFFF),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: active ? const Color(0xFFC8A84B) : const Color(0x809FA1B3),
          ),
        ),
      ),
    );
  }
}

class _PreviewDialog extends StatefulWidget {
  const _PreviewDialog({
    required this.listings,
    required this.initialIndex,
    required this.onOpenListing,
  });

  final List<Listing> listings;
  final int initialIndex;
  final ValueChanged<String> onOpenListing;

  @override
  State<_PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends State<_PreviewDialog> {
  late int _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final listing = widget.listings[_current];
    final imageUrl = listing.imageUrls.isEmpty ? null : listing.imageUrls.first;

    return Dialog.fullscreen(
      backgroundColor: const Color(0xF205050A),
      child: SafeArea(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 70, 16, 96),
              child: Center(
                child: AspectRatio(
                  aspectRatio: 0.56,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _ListingImage(imageUrl: imageUrl, listing: listing),
                  ),
                ),
              ),
            ),
            Container(
              height: 62,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(color: Color(0xD90E0E14)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        listing.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${_current + 1} / ${widget.listings.length}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0x669FA1B3),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0x1AFFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: const BoxDecoration(color: Color(0xD90E0E14)),
                child: Row(
                  children: [
                    _NavButton(icon: Icons.arrow_back, onTap: () => _go(-1)),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(widget.listings.length, (i) {
                            final active = i == _current;
                            return GestureDetector(
                              onTap: () => setState(() => _current = i),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: active ? 18 : 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: active
                                      ? const Color(0xFFC8A84B)
                                      : const Color(0x33FFFFFF),
                                  borderRadius: BorderRadius.circular(
                                    active ? 3 : 99,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    _NavButton(icon: Icons.arrow_forward, onTap: () => _go(1)),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => widget.onOpenListing(listing.id),
                      child: const Text('Open'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(int delta) {
    setState(() {
      _current =
          (_current + delta + widget.listings.length) % widget.listings.length;
    });
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(21),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0x1FFFFFFF)),
        ),
        child: Icon(icon),
      ),
    );
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SearchHeaderDelegate({required this.child});

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 58;

  @override
  double get minExtent => 58;

  @override
  bool shouldRebuild(covariant _SearchHeaderDelegate oldDelegate) {
    return false;
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
