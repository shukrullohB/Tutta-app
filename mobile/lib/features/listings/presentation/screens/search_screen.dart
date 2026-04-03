import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/router/route_names.dart';
import '../../application/search_controller.dart';
import '../../domain/models/listing.dart';
import '../../../wishlist/application/favorites_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final TextEditingController _cityController;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    final state = ref.read(searchControllerProvider);
    _cityController = TextEditingController(text: state.city);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchControllerProvider.notifier).search();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
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
                        IconButton(
                          onPressed: () => context.go(RouteNames.home),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppColors.text,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Tutta',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 38 / 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => context.go(RouteNames.settings),
                          icon: const CircleAvatar(
                            radius: 16,
                            backgroundColor: AppColors.primarySoft,
                            child: Icon(
                              Icons.person,
                              size: 16,
                              color: AppColors.primaryDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceTint,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: TextField(
                        controller: _cityController,
                        style: const TextStyle(color: AppColors.text),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.textMuted,
                          ),
                          hintText: 'Tashkent, Uzbekistan',
                          hintStyle: TextStyle(color: AppColors.textMuted),
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                        onChanged: _onCityChanged,
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
                              color: AppColors.surfaceTint,
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
                                          color: AppColors.textSoft,
                                        ),
                                        SizedBox(width: 6),
                                        Text('List'),
                                      ],
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () =>
                                        context.push(RouteNames.searchMap),
                                    borderRadius: BorderRadius.circular(8),
                                    child: const SizedBox(
                                      height: 32,
                                      child: Center(child: Text('Map')),
                                    ),
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
                          onTap: () {
                            ref
                                .read(searchControllerProvider.notifier)
                                .setIncludeFreeStay(!state.includeFreeStay);
                            ref
                                .read(searchControllerProvider.notifier)
                                .search();
                          },
                        ),
                        _FilterPill(
                          label: 'Guests: ${state.guests}',
                          icon: Icons.people_outline,
                          onTap: () => _pickGuests(context, state.guests),
                        ),
                        _FilterPill(
                          label: state.types.isEmpty
                              ? 'Any type'
                              : '${state.types.length} type(s)',
                          icon: Icons.home_work_outlined,
                          onTap: () => _openFiltersSheet(context, state),
                        ),
                        _FilterPill(
                          label: state.amenities.isEmpty
                              ? 'Amenities'
                              : '${state.amenities.length} amenity(s)',
                          icon: Icons.checklist_rounded,
                          onTap: () => _openFiltersSheet(context, state),
                        ),
                        _FilterPill(
                          label: _priceLabel(
                            state.minPriceUzs,
                            state.maxPriceUzs,
                          ),
                          icon: Icons.payments_outlined,
                          onTap: () => _openFiltersSheet(context, state),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 260.ms).slideY(begin: -0.1, end: 0),
            ),
            if (state.loading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(14, 8, 14, 0),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              ),
            if (state.errorMessage != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: Card(
                    color: const Color(0x22D64545),
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
                    final isFavorite = ref.watch(
                      favoritesIdsProvider.select(
                        (ids) => ids.contains(listing.id),
                      ),
                    );
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child:
                          _SearchListingTile(
                                listing: listing,
                                isFavorite: isFavorite,
                                onToggleFavorite: () => ref
                                    .read(favoritesIdsProvider.notifier)
                                    .toggle(listing.id),
                                onTap: () => context.push(
                                  RouteNames.listingDetailsById(listing.id),
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
          onPressed: () => context.push(RouteNames.searchMap),
          icon: const Icon(Icons.map_outlined),
          label: const Text('Show Map'),
          style: FilledButton.styleFrom(
            minimumSize: const Size(160, 50),
            backgroundColor: AppColors.primaryDeep,
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
    final selectedTypes = state.types.toSet();
    final selectedAmenities = state.amenities.toSet();
    var selectedPricePreset = _selectedPricePreset(
      min: state.minPriceUzs,
      max: state.maxPriceUzs,
    );
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
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
                    decoration: const InputDecoration(
                      labelText: 'District / Landmark / Metro',
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Property type',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ListingType.values
                        .where((type) => type != ListingType.freeStay)
                        .map(
                          (type) => FilterChip(
                            label: Text(_typeLabel(type)),
                            selected: selectedTypes.contains(type),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedTypes.add(type);
                                } else {
                                  selectedTypes.remove(type);
                                }
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Amenities',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _supportedAmenities
                        .map(
                          (amenity) => FilterChip(
                            label: Text(_amenityLabel(amenity)),
                            selected: selectedAmenities.contains(amenity),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  selectedAmenities.add(amenity);
                                } else {
                                  selectedAmenities.remove(amenity);
                                }
                              });
                            },
                          ),
                        )
                        .toList(growable: false),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Price range (UZS / night)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PricePresetChip(
                        label: 'Any',
                        selected: selectedPricePreset == _PricePreset.any,
                        onTap: () => setModalState(
                          () => selectedPricePreset = _PricePreset.any,
                        ),
                      ),
                      _PricePresetChip(
                        label: '< 350k',
                        selected: selectedPricePreset == _PricePreset.under350k,
                        onTap: () => setModalState(
                          () => selectedPricePreset = _PricePreset.under350k,
                        ),
                      ),
                      _PricePresetChip(
                        label: '350k - 550k',
                        selected:
                            selectedPricePreset == _PricePreset.between350k550k,
                        onTap: () => setModalState(
                          () => selectedPricePreset =
                              _PricePreset.between350k550k,
                        ),
                      ),
                      _PricePresetChip(
                        label: '550k - 800k',
                        selected:
                            selectedPricePreset == _PricePreset.between550k800k,
                        onTap: () => setModalState(
                          () => selectedPricePreset =
                              _PricePreset.between550k800k,
                        ),
                      ),
                      _PricePresetChip(
                        label: '> 800k',
                        selected: selectedPricePreset == _PricePreset.over800k,
                        onTap: () => setModalState(
                          () => selectedPricePreset = _PricePreset.over800k,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            districtController.clear();
                            setModalState(() {
                              selectedTypes.clear();
                              selectedAmenities.clear();
                              selectedPricePreset = _PricePreset.any;
                            });
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result == true) {
      final controller = ref.read(searchControllerProvider.notifier);
      controller.setDistrict(districtController.text.trim());
      controller.setTypes(selectedTypes.toList(growable: false));
      controller.setAmenities(selectedAmenities.toList(growable: false));
      final range = _priceRangeByPreset(selectedPricePreset);
      controller.setPriceRange(minPriceUzs: range.$1, maxPriceUzs: range.$2);
      controller.search();
    }
    districtController.dispose();
  }

  void _onCityChanged(String value) {
    final controller = ref.read(searchControllerProvider.notifier);
    controller.setCity(value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) {
        return;
      }
      controller.search();
    });
  }
}

String _priceLabel(int? min, int? max) {
  if (min == null && max == null) {
    return 'Any price';
  }
  if (min == null && max != null) {
    return '< ${_compactPrice(max)}';
  }
  if (min != null && max == null) {
    return '> ${_compactPrice(min)}';
  }
  return '${_compactPrice(min!)} - ${_compactPrice(max!)}';
}

String _compactPrice(int value) {
  if (value >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}m';
  }
  return '${(value / 1000).round()}k';
}

enum _PricePreset { any, under350k, between350k550k, between550k800k, over800k }

_PricePreset _selectedPricePreset({int? min, int? max}) {
  if (min == null && max == null) {
    return _PricePreset.any;
  }
  if (min == null && max == 350000) {
    return _PricePreset.under350k;
  }
  if (min == 350000 && max == 550000) {
    return _PricePreset.between350k550k;
  }
  if (min == 550000 && max == 800000) {
    return _PricePreset.between550k800k;
  }
  if (min == 800000 && max == null) {
    return _PricePreset.over800k;
  }
  return _PricePreset.any;
}

(int?, int?) _priceRangeByPreset(_PricePreset preset) {
  switch (preset) {
    case _PricePreset.any:
      return (null, null);
    case _PricePreset.under350k:
      return (null, 350000);
    case _PricePreset.between350k550k:
      return (350000, 550000);
    case _PricePreset.between550k800k:
      return (550000, 800000);
    case _PricePreset.over800k:
      return (800000, null);
  }
}

class _PricePresetChip extends StatelessWidget {
  const _PricePresetChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0x1A1A5EFF) : const Color(0xFFF2F4F8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.textSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

const List<ListingAmenity> _supportedAmenities = <ListingAmenity>[
  ListingAmenity.wifi,
  ListingAmenity.airConditioner,
  ListingAmenity.kitchen,
  ListingAmenity.washingMachine,
  ListingAmenity.parking,
  ListingAmenity.privateBathroom,
  ListingAmenity.kidsAllowed,
  ListingAmenity.petsAllowed,
  ListingAmenity.womenOnly,
  ListingAmenity.menOnly,
  ListingAmenity.hostLivesTogether,
  ListingAmenity.instantConfirm,
];

String _typeLabel(ListingType type) {
  switch (type) {
    case ListingType.apartment:
      return 'Apartment';
    case ListingType.room:
      return 'Room';
    case ListingType.homePart:
      return 'Part of home';
    case ListingType.freeStay:
      return 'Free Stay';
  }
}

String _amenityLabel(ListingAmenity amenity) {
  switch (amenity) {
    case ListingAmenity.wifi:
      return 'Wi-Fi';
    case ListingAmenity.airConditioner:
      return 'Air conditioning';
    case ListingAmenity.kitchen:
      return 'Kitchen';
    case ListingAmenity.washingMachine:
      return 'Washing machine';
    case ListingAmenity.parking:
      return 'Parking';
    case ListingAmenity.privateBathroom:
      return 'Private bathroom';
    case ListingAmenity.kidsAllowed:
      return 'Kids allowed';
    case ListingAmenity.petsAllowed:
      return 'Pets allowed';
    case ListingAmenity.womenOnly:
      return 'Women only';
    case ListingAmenity.menOnly:
      return 'Men only';
    case ListingAmenity.hostLivesTogether:
      return 'Host lives together';
    case ListingAmenity.instantConfirm:
      return 'Instant confirm';
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
          color: AppColors.surfaceTint,
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
  const _SearchListingTile({
    required this.listing,
    required this.onTap,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Listing listing;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final imageUrl = listing.imageUrls.isEmpty ? null : listing.imageUrls.first;
    final rating = _mockRatingFor(listing.id);
    final reviewsCount = _mockReviewCountFor(listing.id);
    final priceLabel = listing.type == ListingType.freeStay
        ? 'Free stay'
        : listing.nightlyPriceUzs == null
        ? 'Price on request'
        : '${_formatUzs(listing.nightlyPriceUzs!)} UZS';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
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
                  left: 12,
                  top: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xEFFFFFFF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _listingTypeLabel(listing.type),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: InkWell(
                    onTap: onToggleFavorite,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xF7FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? const Color(0xFFD64545)
                            : AppColors.text,
                        size: 20,
                      ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryDeep,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          rating.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.rate_review_outlined,
                            size: 15,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$reviewsCount reviews',
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (listing.amenities.contains(
                        ListingAmenity.instantConfirm,
                      ))
                        const Text(
                          'Instant',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          listing.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 34 / 2,
                            color: AppColors.text,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        priceLabel,
                        style: const TextStyle(
                          color: AppColors.primaryDeep,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        '/night',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${listing.district}, ${listing.city}',
                    style: const TextStyle(color: AppColors.textSoft),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ...listing.amenities
                          .take(4)
                          .map((amenity) => _AmenityTiny(amenity: amenity)),
                    ],
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

class _AmenityTiny extends StatelessWidget {
  const _AmenityTiny({required this.amenity});

  final ListingAmenity amenity;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_amenityIcon(amenity), size: 12, color: const Color(0xFF4E5568)),
          const SizedBox(width: 4),
          Text(
            _amenityTinyLabel(amenity),
            style: const TextStyle(
              color: AppColors.textSoft,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
      if (imageUrl!.startsWith('assets/')) {
        return Image.asset(
          imageUrl!,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _imageFallback(),
        );
      }
      return Image.network(
        imageUrl!,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(),
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

double _mockRatingFor(String listingId) {
  final hash = listingId.codeUnits.fold<int>(0, (acc, e) => acc + e);
  final normalized = (hash % 13) / 10.0;
  return (4.0 + normalized).clamp(4.1, 4.9);
}

int _mockReviewCountFor(String listingId) {
  final hash = listingId.codeUnits.fold<int>(0, (acc, e) => acc + e);
  return 12 + (hash % 70);
}

String _formatUzs(int value) {
  final raw = value.toString();
  final out = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    out.write(raw[i]);
    final remain = raw.length - i - 1;
    if (remain > 0 && remain % 3 == 0) {
      out.write(' ');
    }
  }
  return out.toString();
}

String _listingTypeLabel(ListingType type) {
  switch (type) {
    case ListingType.apartment:
      return 'Apartment';
    case ListingType.room:
      return 'Room';
    case ListingType.homePart:
      return 'Home Part';
    case ListingType.freeStay:
      return 'Free Stay';
  }
}

IconData _amenityIcon(ListingAmenity amenity) {
  switch (amenity) {
    case ListingAmenity.wifi:
      return Icons.wifi;
    case ListingAmenity.airConditioner:
      return Icons.ac_unit;
    case ListingAmenity.kitchen:
      return Icons.kitchen_outlined;
    case ListingAmenity.washingMachine:
      return Icons.local_laundry_service_outlined;
    case ListingAmenity.parking:
      return Icons.local_parking_outlined;
    case ListingAmenity.privateBathroom:
      return Icons.bathtub_outlined;
    case ListingAmenity.kidsAllowed:
      return Icons.child_care_outlined;
    case ListingAmenity.petsAllowed:
      return Icons.pets_outlined;
    case ListingAmenity.womenOnly:
      return Icons.female_outlined;
    case ListingAmenity.menOnly:
      return Icons.male_outlined;
    case ListingAmenity.hostLivesTogether:
      return Icons.people_alt_outlined;
    case ListingAmenity.instantConfirm:
      return Icons.bolt_outlined;
  }
}

String _amenityTinyLabel(ListingAmenity amenity) {
  switch (amenity) {
    case ListingAmenity.airConditioner:
      return 'AC';
    case ListingAmenity.privateBathroom:
      return 'Bath';
    case ListingAmenity.hostLivesTogether:
      return 'Host';
    case ListingAmenity.instantConfirm:
      return 'Instant';
    default:
      return _amenityLabel(amenity);
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
