import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app.dart';
import '../../../../app/router/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../listings/application/search_controller.dart';
import '../../../listings/domain/models/listing.dart';
import '../../application/favorites_controller.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesIdsProvider).toList(growable: false);
    final listingsFuture = Future.wait(
      ids.map((id) => ref.read(listingsRepositoryProvider).getById(id)),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EC),
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go(RouteNames.home),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(AppLocalizations.of(context).favoritesTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: ids.isEmpty
          ? const _FavoritesEmptyState()
          : FutureBuilder<List<Listing?>>(
              future: listingsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                final listings = (snapshot.data ?? const <Listing?>[])
                    .whereType<Listing>()
                    .toList(growable: false);

                if (listings.isEmpty) {
                  return const _FavoritesEmptyState();
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF3C7A89), Color(0xFF7DB4A5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x223C7A89),
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(0x33FFFFFF),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.favorite_rounded,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context).favoritesTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${listings.length} saved stays ready for quick access',
                                  style: const TextStyle(
                                    color: Color(0xE6FFFFFF),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...listings.map(
                      (listing) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _FavoriteTile(listing: listing),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final isFavorite = ref.watch(
      favoritesIdsProvider.select((ids) => ids.contains(listing.id)),
    );
    final imageUrl = listing.imageUrls.isEmpty ? null : listing.imageUrls.first;
    final rating = _mockRatingFor(listing.id);
    final reviews = _mockReviewsFor(listing.id);

    return Material(
      color: const Color(0xFFFFFCF7),
      borderRadius: BorderRadius.circular(24),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(RouteNames.listingDetailsById(listing.id)),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE7DCC8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x120F172A),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1.7,
                    child: imageUrl == null
                        ? Container(
                            color: const Color(0xFFECE4D7),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.home_work_outlined,
                              size: 34,
                            ),
                          )
                        : Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: const Color(0xFFECE4D7),
                              alignment: Alignment.center,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: Color(0xFFFFB300),
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (reviews > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '($reviews)',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Color(0xEFFFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? const Color(0xFFD64545)
                              : Colors.grey,
                        ),
                        onPressed: () {
                          ref
                              .read(favoritesIdsProvider.notifier)
                              .toggle(listing.id);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF17324D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${listing.city}${listing.district.isNotEmpty ? ', ${listing.district}' : ''}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.map_outlined, size: 18),
                          label: Text(loc.onMap),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      listing.nightlyPriceUzs != null
                          ? '${_formatUzs(listing.nightlyPriceUzs!)} ${loc.perNight}'
                          : loc.freeStay,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF7A4B18),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _openReviewDialog(context, loc),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFF2D39B),
                        foregroundColor: const Color(0xFF6F4A10),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      icon: const Icon(Icons.rate_review_rounded, size: 22),
                      label: Text(loc.leaveReview),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openReviewDialog(
    BuildContext context,
    AppLocalizations loc,
  ) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE7C7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.rate_review_rounded,
                color: Color(0xFFB7791F),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(loc.leaveReview)),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(hintText: loc.reviewHint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              MaterialLocalizations.of(dialogContext).cancelButtonLabel,
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(MaterialLocalizations.of(dialogContext).okButtonLabel),
          ),
        ],
      ),
    );

    controller.dispose();

    if (!context.mounted) {
      return;
    }

    if (result != null && result.trim().isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.reviewThanks)));
    }
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3F1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.favorite_border,
                size: 42,
                color: Color(0xFFD64545),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loc.favoritesEmptyTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: const Color(0xFF17324D),
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              loc.favoritesEmptySubtitle,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

double _mockRatingFor(String id) {
  final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);
  final delta = (hash % 9) / 10.0;
  return (4.1 + delta).clamp(4.1, 4.9);
}

int _mockReviewsFor(String id) {
  final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);
  return 10 + (hash % 90);
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
