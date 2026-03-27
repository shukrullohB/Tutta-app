import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
            appBar: AppBar(
              leading: IconButton(
                onPressed: () => context.canPop()
                    ? context.pop()
                    : context.go(RouteNames.search),
                icon: const Icon(Icons.arrow_back),
              ),
              title: const Text('Listing'),
            ),
            body: const Center(child: Text('Listing not found.')),
          );
        }

        final hasPremium =
            ref.watch(authControllerProvider).valueOrNull?.user?.isPremium ??
            false;
        final currentUserId =
            ref.watch(authControllerProvider).valueOrNull?.user?.id;
        final isOwner = currentUserId != null && currentUserId == listing.hostId;

        final freeStayLocked =
            listing.type == ListingType.freeStay && !hasPremium;

        final imageUrl = listing.imageUrls.isEmpty
            ? null
            : listing.imageUrls.first;

        return Scaffold(
          backgroundColor: const Color(0xFF0E0E14),
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 280,
                leading: const BackButton(),
                actions: [
                  if (isOwner)
                    IconButton(
                      onPressed: () => context.push(
                        '${RouteNames.listingAvailability}/${listing.id}',
                      ),
                      icon: const Icon(Icons.calendar_month_outlined),
                    ),
                  if (isOwner)
                    IconButton(
                      onPressed: () =>
                          context.push('${RouteNames.editListing}/${listing.id}'),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: _ListingHero(
                    imageUrl: imageUrl,
                    city: listing.city,
                    district: listing.district,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                            listing.title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          )
                          .animate()
                          .fadeIn(duration: 220.ms)
                          .slideY(begin: 0.08, end: 0),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: Color(0xFFB9BBC9),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${listing.city}, ${listing.district}',
                            style: const TextStyle(
                              color: Color(0xFFB9BBC9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ).animate(delay: 60.ms).fadeIn(duration: 220.ms),
                      const SizedBox(height: 14),
                      _InfoPanel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  listing.description ?? 'No description yet.',
                                  style: const TextStyle(
                                    color: Color(0xFFE7E9F3),
                                    height: 1.45,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    _SoftTag(
                                      label: 'Max guests: ${listing.maxGuests}',
                                    ),
                                    _SoftTag(
                                      label: 'Min days: ${listing.minDays}',
                                    ),
                                    _SoftTag(
                                      label: 'Max days: ${listing.maxDays}',
                                    ),
                                    _SoftTag(
                                      label: listing.nightlyPriceUzs == null
                                          ? 'Free stay / exchange'
                                          : '${listing.nightlyPriceUzs} UZS / night',
                                      isAccent: true,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                          .animate(delay: 110.ms)
                          .fadeIn(duration: 240.ms)
                          .slideY(begin: 0.06, end: 0),
                      if (freeStayLocked) ...[
                        const SizedBox(height: 14),
                        _InfoPanel(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.workspace_premium_outlined,
                                    color: Color(0xFFC8A84B),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Premium required',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFFF5F5FA),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'Free Stay bookings are available only for Premium users.',
                                          style: TextStyle(
                                            color: Color(0xFFB9BBC9),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: () => context.push(
                                            RouteNames.premiumPaywall,
                                          ),
                                          child: const Text('Upgrade'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate(delay: 170.ms)
                            .fadeIn(duration: 240.ms)
                            .slideY(begin: 0.06, end: 0),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF14141E),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0x33FFFFFF)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x44000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: FilledButton.icon(
                onPressed: freeStayLocked
                    ? null
                    : () {
                        context.push(
                          '${RouteNames.bookingRequest}/${listing.id}',
                        );
                      },
                icon: const Icon(Icons.event_available_outlined),
                label: Text(
                  freeStayLocked ? 'Premium required' : 'Request booking',
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.3, end: 0),
          ),
        );
      },
    );
  }
}

class _ListingHero extends StatelessWidget {
  const _ListingHero({
    required this.imageUrl,
    required this.city,
    required this.district,
  });

  final String? imageUrl;
  final String city;
  final String district;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallback(),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x26000000), Color(0x8A000000)],
              ),
            ),
          ),
        ],
      );
    }

    return _fallback();
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF222436), Color(0xFF151726)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.home_work_outlined, size: 34, color: Colors.white),
            const SizedBox(height: 8),
            Text(
              '$city, $district',
              style: const TextStyle(color: Color(0xD9FFFFFF)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF14141E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: child,
    );
  }
}

class _SoftTag extends StatelessWidget {
  const _SoftTag({required this.label, this.isAccent = false});

  final String label;
  final bool isAccent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAccent ? const Color(0x33C8A84B) : const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isAccent ? const Color(0x66C8A84B) : const Color(0x33FFFFFF),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isAccent ? const Color(0xFFF4DE9B) : const Color(0xFFE7E9F3),
          fontWeight: isAccent ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
