import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../reviews/application/review_submit_controller.dart';
import '../../../wishlist/application/favorites_controller.dart';
import '../../application/search_controller.dart';

class ListingDetailsScreen extends ConsumerStatefulWidget {
  const ListingDetailsScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingDetailsScreen> createState() =>
      _ListingDetailsScreenState();
}

enum _ReviewSort { popular, newest }

class _ListingDetailsScreenState extends ConsumerState<ListingDetailsScreen> {
  late Future<dynamic> _listingFuture;
  final Map<String, int> _reviewVotes = <String, int>{};
  _ReviewSort _reviewSort = _ReviewSort.popular;

  @override
  void initState() {
    super.initState();
    _listingFuture = ref.read(listingsRepositoryProvider).getById(widget.listingId);
  }

  List<dynamic> _sortReviews(List<dynamic> reviews) {
    final items = [...reviews];
    items.sort((a, b) {
      if (_reviewSort == _ReviewSort.newest) {
        return b.createdAt.compareTo(a.createdAt);
      }
      final popularityA = _yesCount(a.id) - _noCount(a.id);
      final popularityB = _yesCount(b.id) - _noCount(b.id);
      if (popularityA != popularityB) {
        return popularityB.compareTo(popularityA);
      }
      return b.createdAt.compareTo(a.createdAt);
    });
    return items;
  }

  Future<void> _openReviewDialog(BuildContext context, dynamic listing) async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to leave a review.')),
      );
      return;
    }
    var rating = 5;
    final controller = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(_t(dialogContext, en: 'Leave a review', ru: 'Р С›РЎРѓРЎвЂљР В°Р Р†Р С‘РЎвЂљРЎРЉ Р С•РЎвЂљР В·РЎвЂ№Р Р†', uz: 'Sharh qoldirish')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: List.generate(5, (index) {
                  final value = index + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => rating = value),
                    icon: Icon(
                      value <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                      color: const Color(0xFFE8A317),
                    ),
                  );
                }),
              ),
              TextField(
                controller: controller,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: _t(dialogContext, en: 'Tell others what you liked here', ru: 'Р В Р В°РЎРѓРЎРѓР С”Р В°Р В¶Р С‘РЎвЂљР Вµ, РЎвЂЎРЎвЂљР С• Р Р†Р В°Р С Р С—Р С•Р Р…РЎР‚Р В°Р Р†Р С‘Р В»Р С•РЎРѓРЎРЉ', uz: 'Bu joyda nima yoqqanini yozing'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(MaterialLocalizations.of(dialogContext).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(_t(dialogContext, en: 'Submit', ru: 'Р С›РЎвЂљР С—РЎР‚Р В°Р Р†Р С‘РЎвЂљРЎРЉ', uz: 'Yuborish')),
            ),
          ],
        ),
      ),
    );
    final comment = controller.text.trim();
    controller.dispose();
    if (submitted != true) return;
    await ref.read(reviewsRepositoryProvider).submitReview(
          bookingId: 'public_${listing.id}_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
          listingId: listing.id,
          reviewerUserId: user.id,
          hostUserId: listing.hostId,
          rating: rating,
          comment: comment.isEmpty ? 'Great stay and welcoming host.' : comment,
        );
    ref.invalidate(listingReviewsProvider(listing.id));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(context, en: 'Review saved. Thank you!', ru: 'Р С›РЎвЂљР В·РЎвЂ№Р Р† РЎРѓР С•РЎвЂ¦РЎР‚Р В°Р Р…Р ВµР Р…. Р РЋР С—Р В°РЎРѓР С‘Р В±Р С•!', uz: 'Sharhingiz saqlandi. Rahmat!'))),
      );
    }
  }

  Future<void> _openReviewsSheet(BuildContext context, dynamic listing, List<dynamic> reviews) {
    final sorted = _sortReviews(reviews);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFCF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.76,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFD8D1C4), borderRadius: BorderRadius.circular(999)))),
                const SizedBox(height: 18),
                Text(_t(sheetContext, en: 'Guest reviews', ru: 'Р С›РЎвЂљР В·РЎвЂ№Р Р†РЎвЂ№ Р С–Р С•РЎРѓРЎвЂљР ВµР в„–', uz: 'Mehmonlar sharhlari'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF17324D))),
                const SizedBox(height: 12),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _sortChip(label: _t(sheetContext, en: 'Popular', ru: 'Р СџР С•Р С—РЎС“Р В»РЎРЏРЎР‚Р Р…РЎвЂ№Р Вµ', uz: 'Ommabop'), active: _reviewSort == _ReviewSort.popular, onTap: () => setState(() => _reviewSort = _ReviewSort.popular)),
                  _sortChip(label: _t(sheetContext, en: 'Newest', ru: 'Р СњР С•Р Р†РЎвЂ№Р Вµ', uz: 'Yangi'), active: _reviewSort == _ReviewSort.newest, onTap: () => setState(() => _reviewSort = _ReviewSort.newest)),
                  FilledButton.tonalIcon(onPressed: () { Navigator.of(sheetContext).pop(); _openReviewDialog(context, listing); }, icon: const Icon(Icons.edit_note_rounded), label: Text(_t(sheetContext, en: 'Write review', ru: 'Р С›РЎРѓРЎвЂљР В°Р Р†Р С‘РЎвЂљРЎРЉ Р С•РЎвЂљР В·РЎвЂ№Р Р†', uz: 'Sharh yozish'))),
                ]),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.separated(
                    itemCount: sorted.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final review = sorted[index];
                      final vote = _reviewVotes[review.id] ?? 0;
                      final yesCount = _yesCount(review.id) + (vote == 1 ? 1 : 0);
                      final noCount = _noCount(review.id) + (vote == -1 ? 1 : 0);
                      return _ReviewCard(
                        reviewerLabel: _reviewerName(review.reviewerUserId),
                        rating: review.rating,
                        comment: review.comment,
                        dateLabel: _formatReviewDate(context, review.createdAt),
                        vote: vote,
                        yesCount: yesCount,
                        noCount: noCount,
                        onYes: () => setState(() => _reviewVotes[review.id] = vote == 1 ? 0 : 1),
                        onNo: () => setState(() => _reviewVotes[review.id] = vote == -1 ? 0 : -1),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _listingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return _ErrorScaffold(
            message: snapshot.error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => setState(() => _listingFuture = ref.read(listingsRepositoryProvider).getById(widget.listingId)),
          );
        }
        final listing = snapshot.data;
        if (listing == null) {
          return _ErrorScaffold(message: 'Listing not found.', onRetry: () => context.go(RouteNames.search));
        }
        final isFavorite = ref.watch(favoritesIdsProvider.select((ids) => ids.contains(listing.id)));
        final reviewsAsync = ref.watch(listingReviewsProvider(listing.id));
        return Scaffold(
          backgroundColor: const Color(0xFFF6F3EC),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(children: [
                    SizedBox(height: 260, width: double.infinity, child: _ListingImage(imageUrl: (listing.imageUrls as List).isEmpty ? null : listing.imageUrls.first)),
                    Positioned(top: 12, left: 12, child: CircleAvatar(backgroundColor: const Color(0xEFFFFFFF), child: IconButton(onPressed: () => context.canPop() ? context.pop() : context.go(RouteNames.search), icon: const Icon(Icons.arrow_back, color: Color(0xFF17324D))))),
                    Positioned(top: 12, right: 12, child: CircleAvatar(backgroundColor: const Color(0xEFFFFFFF), child: IconButton(onPressed: () => ref.read(favoritesIdsProvider.notifier).toggle(listing.id), icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? const Color(0xFFD64545) : const Color(0xFF1F2430))))),
                  ]),
                ),
                const SizedBox(height: 16),
                Text(listing.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFF17324D))),
                const SizedBox(height: 8),
                Row(children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF6D7280)),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${listing.city}, ${listing.district}', style: const TextStyle(color: Color(0xFF6D7280)))),
                ]),
                const SizedBox(height: 14),
                reviewsAsync.when(
                  loading: () => const _Panel(child: Padding(padding: EdgeInsets.symmetric(vertical: 18), child: Center(child: CircularProgressIndicator()))),
                  error: (_, _) => const _Panel(child: Text('Could not load reviews yet.', style: TextStyle(color: Color(0xFF64748B)))),
                  data: (reviews) {
                    final sorted = _sortReviews(reviews);
                    final average = reviews.isEmpty ? 0.0 : reviews.map((review) => review.rating).reduce((a, b) => a + b) / reviews.length;
                    return _Panel(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFDE8BF), Color(0xFFF7C96B)]), borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.rate_review_rounded, size: 30, color: Color(0xFF8C5A12)),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(_t(context, en: 'Guest reviews', ru: 'Р С›РЎвЂљР В·РЎвЂ№Р Р†РЎвЂ№ Р С–Р С•РЎРѓРЎвЂљР ВµР в„–', uz: 'Mehmonlar sharhlari'), style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F2430), fontSize: 20)),
                            const SizedBox(height: 4),
                            Text(reviews.isEmpty ? _t(context, en: 'No reviews yet', ru: 'Р СџР С•Р С”Р В° Р Р…Р ВµРЎвЂљ Р С•РЎвЂљР В·РЎвЂ№Р Р†Р С•Р Р†', uz: 'Hozircha sharhlar yo\'q') : '${average.toStringAsFixed(1)} / 5 РІР‚Сћ ${reviews.length} ${_t(context, en: 'reviews', ru: 'Р С•РЎвЂљР В·РЎвЂ№Р Р†Р С•Р Р†', uz: 'sharh')}', style: const TextStyle(color: Color(0xFF64748B))),
                          ])),
                        ]),
                        const SizedBox(height: 14),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _sortChip(label: _t(context, en: 'Popular', ru: 'Р СџР С•Р С—РЎС“Р В»РЎРЏРЎР‚Р Р…РЎвЂ№Р Вµ', uz: 'Ommabop'), active: _reviewSort == _ReviewSort.popular, onTap: () => setState(() => _reviewSort = _ReviewSort.popular)),
                          _sortChip(label: _t(context, en: 'Newest', ru: 'Р СњР С•Р Р†РЎвЂ№Р Вµ', uz: 'Yangi'), active: _reviewSort == _ReviewSort.newest, onTap: () => setState(() => _reviewSort = _ReviewSort.newest)),
                          ActionChip(avatar: const Icon(Icons.visibility_outlined, size: 18), label: Text(_t(context, en: 'See all', ru: 'Р вЂ™РЎРѓР Вµ Р С•РЎвЂљР В·РЎвЂ№Р Р†РЎвЂ№', uz: 'Barchasi')), onPressed: () => _openReviewsSheet(context, listing, reviews)),
                          FilledButton.tonalIcon(onPressed: () => _openReviewDialog(context, listing), icon: const Icon(Icons.edit_note_rounded), label: Text(_t(context, en: 'Write review', ru: 'Р С›РЎРѓРЎвЂљР В°Р Р†Р С‘РЎвЂљРЎРЉ Р С•РЎвЂљР В·РЎвЂ№Р Р†', uz: 'Sharh yozish'))),
                        ]),
                        const SizedBox(height: 16),
                        if (reviews.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: const Color(0xFFF8F4EA), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE7DCC8))),
                            child: Text(_t(context, en: 'Be the first guest to share what this stay feels like.', ru: 'Р РЋРЎвЂљР В°Р Р…РЎРЉРЎвЂљР Вµ Р С—Р ВµРЎР‚Р Р†РЎвЂ№Р С Р С–Р С•РЎРѓРЎвЂљР ВµР С Р С‘ Р С—Р С•Р Т‘Р ВµР В»Р С‘РЎвЂљР ВµРЎРѓРЎРЉ Р Р†Р С—Р ВµРЎвЂЎР В°РЎвЂљР В»Р ВµР Р…Р С‘РЎРЏР СР С‘ Р С•Р В± РЎРЊРЎвЂљР С•Р С Р В¶Р С‘Р В»РЎРЉР Вµ.', uz: 'Bu joy haqida birinchi bo\'lib fikr qoldiring.'), style: const TextStyle(color: Color(0xFF64748B), height: 1.4)),
                          ),
                        if (reviews.isNotEmpty)
                          ...sorted.take(2).map((review) {
                            final vote = _reviewVotes[review.id] ?? 0;
                            final yesCount = _yesCount(review.id) + (vote == 1 ? 1 : 0);
                            final noCount = _noCount(review.id) + (vote == -1 ? 1 : 0);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _ReviewCard(
                                reviewerLabel: _reviewerName(review.reviewerUserId),
                                rating: review.rating,
                                comment: review.comment,
                                dateLabel: _formatReviewDate(context, review.createdAt),
                                vote: vote,
                                yesCount: yesCount,
                                noCount: noCount,
                                onYes: () => setState(() => _reviewVotes[review.id] = vote == 1 ? 0 : 1),
                                onNo: () => setState(() => _reviewVotes[review.id] = vote == -1 ? 0 : -1),
                              ),
                            );
                          }),
                      ]),
                    );
                  },
                ),
                const SizedBox(height: 14),
                _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if ((listing.imageUrls as List).isNotEmpty) ...[
                    Text(_t(context, en: 'Photos', ru: 'Р В¤Р С•РЎвЂљР С•', uz: 'Rasmlar'), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2430))),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: listing.imageUrls.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, index) => ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(width: 108, child: _ListingImage(imageUrl: listing.imageUrls[index])),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text((listing.description ?? '').trim().isEmpty ? _t(context, en: 'No description yet.', ru: 'Р С›Р С—Р С‘РЎРѓР В°Р Р…Р С‘Р Вµ Р С—Р С•Р С”Р В° Р Р…Р Вµ Р Т‘Р С•Р В±Р В°Р Р†Р В»Р ВµР Р…Р С•.', uz: 'Tavsif hali qo\'shilmagan.') : listing.description!, style: const TextStyle(color: Color(0xFF1F2430), height: 1.4)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    _Tag(label: '${_t(context, en: 'Max guests', ru: 'Р вЂњР С•РЎРѓРЎвЂљР ВµР в„–', uz: 'Mehmonlar')} ${listing.maxGuests}'),
                    _Tag(label: '${_t(context, en: 'Min days', ru: 'Р СљР С‘Р Р…. Р Т‘Р Р…Р ВµР в„–', uz: 'Min kun')} ${listing.minDays}'),
                    _Tag(label: '${_t(context, en: 'Max days', ru: 'Р СљР В°Р С”РЎРѓ. Р Т‘Р Р…Р ВµР в„–', uz: 'Max kun')} ${listing.maxDays}'),
                    _Tag(label: listing.nightlyPriceUzs == null ? _t(context, en: 'Free stay / exchange', ru: 'Р вЂР ВµРЎРѓР С—Р В»Р В°РЎвЂљР Р…Р С•Р Вµ Р С—РЎР‚Р С•Р В¶Р С‘Р Р†Р В°Р Р…Р С‘Р Вµ', uz: 'Bepul turar joy') : '${listing.nightlyPriceUzs} UZS / night', accent: true),
                  ]),
                ])),
                const SizedBox(height: 14),
                _Panel(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_t(context, en: 'Amenities', ru: 'Р Р€Р Т‘Р С•Р В±РЎРѓРЎвЂљР Р†Р В°', uz: 'Qulayliklar'), style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1F2430))),
                  const SizedBox(height: 8),
                  if ((listing.amenities as List).isEmpty)
                    Text(_t(context, en: 'Host did not add amenities yet.', ru: 'Р ТђР С•РЎРѓРЎвЂљ Р С—Р С•Р С”Р В° Р Р…Р Вµ Р Т‘Р С•Р В±Р В°Р Р†Р С‘Р В» РЎС“Р Т‘Р С•Р В±РЎРѓРЎвЂљР Р†Р В°.', uz: 'Xost hali qulayliklarni qo\'shmagan.'), style: const TextStyle(color: Color(0xFF6D7280)))
                  else
                    Wrap(spacing: 8, runSpacing: 8, children: listing.amenities.map<Widget>((amenity) => _Tag(label: _amenityLabel(amenity))).toList(growable: false)),
                ])),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE1E3E8))),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('${RouteNames.chatList}?listingId=${listing.id}&hostId=${listing.hostId}'),
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Chat'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: () => context.push('${RouteNames.bookingRequest}/${listing.id}'),
                    icon: const Icon(Icons.event_available_outlined),
                    label: const Text('Request booking'),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Listing')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.home_work_outlined,
                size: 42,
                color: Color(0xFF6D7280),
              ),
              const SizedBox(height: 12),
              const Text(
                'This apartment could not be opened yet.',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF17324D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _placeholder();
    }
    if (imageUrl!.startsWith('assets/')) {
      return Image.asset(
        imageUrl!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _placeholder(showLoader: true);
        },
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder({bool showLoader = false}) {
    return Container(
      color: const Color(0xFFE8E2D5),
      alignment: Alignment.center,
      child: showLoader
          ? const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.image_outlined, color: Color(0xFF5E6B81)),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFCF7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6DCCB)),
      ),
      child: child,
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.reviewerLabel,
    required this.rating,
    required this.comment,
    required this.dateLabel,
    required this.vote,
    required this.yesCount,
    required this.noCount,
    required this.onYes,
    required this.onNo,
  });

  final String reviewerLabel;
  final int rating;
  final String comment;
  final String dateLabel;
  final int vote;
  final int yesCount;
  final int noCount;
  final VoidCallback onYes;
  final VoidCallback onNo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F4EA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7DCC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  reviewerLabel,
                  style: const TextStyle(
                    color: Color(0xFF17324D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...List.generate(
                5,
                (index) => Icon(
                  index < rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 16,
                  color: const Color(0xFFE8A317),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment,
            style: const TextStyle(
              color: Color(0xFF425166),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            dateLabel,
            style: const TextStyle(
              color: Color(0xFF8A91A3),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _voteChip(
                context: context,
                active: vote == 1,
                icon: Icons.thumb_up_alt_outlined,
                label: '${_t(context, en: 'Yes', ru: 'Р вЂќР В°', uz: 'Ha')} $yesCount',
                onTap: onYes,
              ),
              _voteChip(
                context: context,
                active: vote == -1,
                icon: Icons.thumb_down_alt_outlined,
                label: '${_t(context, en: 'No', ru: 'Нет', uz: "Yo'q")} $noCount',
                onTap: onNo,
              )],
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, this.accent = false});

  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent ? const Color(0xFFF7E9C2) : const Color(0xFFF0F2F6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent ? const Color(0xFFC8A84B) : const Color(0xFFD6D9E0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: accent ? const Color(0xFF6A480A) : const Color(0xFF2A3040),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

Widget _sortChip({
  required String label,
  required bool active,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? const Color(0xFF17324D) : const Color(0xFFF5EFE2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFF17324D) : const Color(0xFFE3D9C8),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? Colors.white : const Color(0xFF425166),
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

Widget _voteChip({
  required BuildContext context,
  required bool active,
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE7F0F6) : Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? const Color(0xFF3C7A89) : const Color(0xFFE3D9C8),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF425166)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF425166),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );
}

String _reviewerName(String reviewerUserId) {
  final short = reviewerUserId.length > 6
      ? reviewerUserId.substring(reviewerUserId.length - 6)
      : reviewerUserId;
  return 'Guest $short';
}

int _yesCount(String id) {
  final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);
  return 2 + (hash % 11);
}

int _noCount(String id) {
  final hash = id.codeUnits.fold<int>(0, (a, b) => a + b);
  return hash % 4;
}

String _formatReviewDate(BuildContext context, DateTime date) {
  final locale = Localizations.localeOf(context).languageCode;
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  switch (locale) {
    case 'ru':
      return 'Р С›РЎРѓРЎвЂљР В°Р Р†Р В»Р ВµР Р…Р С• $day.$month.$year';
    case 'uz':
      return 'Sharh qoldirilgan sana: $day.$month.$year';
    default:
      return 'Posted on $day.$month.$year';
  }
}

String _t(
  BuildContext context, {
  required String en,
  required String ru,
  required String uz,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      return ru;
    case 'uz':
      return uz;
    default:
      return en;
  }
}

String _amenityLabel(dynamic amenity) {
  final value = amenity.toString().split('.').last;
  switch (value) {
    case 'wifi':
      return 'Wi-Fi';
    case 'airConditioner':
      return 'Air conditioner';
    case 'kitchen':
      return 'Kitchen';
    case 'washingMachine':
      return 'Washing machine';
    case 'parking':
      return 'Parking';
    case 'privateBathroom':
      return 'Private bathroom';
    case 'kidsAllowed':
      return 'Kids allowed';
    case 'petsAllowed':
      return 'Pets allowed';
    case 'womenOnly':
      return 'Women only';
    case 'menOnly':
      return 'Men only';
    case 'hostLivesTogether':
      return 'Host lives together';
    case 'instantConfirm':
      return 'Instant confirm';
    default:
      return value;
  }
}
