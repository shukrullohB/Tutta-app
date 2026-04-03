import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';
import '../theme/app_colors.dart';
import '../../core/utils/google_maps_launcher.dart';
import '../../core/widgets/app_error_view.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/bookings/application/booking_request_controller.dart';
import '../../features/bookings/domain/models/booking.dart';
import '../../features/reviews/application/review_submit_controller.dart';
import '../../features/reviews/domain/models/review.dart';
import '../../features/wishlist/application/favorites_controller.dart';
import '../../features/listings/application/search_controller.dart';
import '../../features/listings/domain/models/listing.dart';
import '../../features/listings/domain/models/example_listings.dart';

enum _ReviewSort { newest, popular }

class ListingDetailsScreen extends ConsumerStatefulWidget {
  const ListingDetailsScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<ListingDetailsScreen> createState() =>
      _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends ConsumerState<ListingDetailsScreen> {
  late final Future<Listing?> _future;
  final PageController _imagePageController = PageController();
  int _selectedImageIndex = 0;
  _ReviewSort _reviewSort = _ReviewSort.newest;

  @override
  void initState() {
    super.initState();
    _future = _loadListing();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<Listing?> _loadListing() async {
    final repository = ref.read(listingsRepositoryProvider);
    final remote = await repository.getById(widget.listingId);
    if (remote != null) {
      return remote;
    }
    return findExampleListingById(widget.listingId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Listing?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                _t(context, en: 'Stay', ru: 'Жильё', uz: 'Turar joy'),
              ),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final listing = snapshot.data;
        if (listing == null) {
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: _goBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(
                _t(context, en: 'Stay', ru: 'Жильё', uz: 'Turar joy'),
              ),
            ),
            body: AppErrorView(
              message: _t(
                context,
                en: 'Apartment not found.',
                ru: 'Жильё не найдено.',
                uz: 'Turar joy topilmadi.',
              ),
              onRetry: () => setState(() {}),
            ),
          );
        }

        final isFavorite = ref.watch(
          favoritesIdsProvider.select((ids) => ids.contains(listing.id)),
        );
        final currentUserId = ref
            .watch(authControllerProvider)
            .valueOrNull
            ?.user
            ?.id;
        final images = listing.imageUrls;
        final safeSelectedImageIndex = images.isEmpty
            ? 0
            : _selectedImageIndex.clamp(0, images.length - 1);
        final selectedImage = images.isEmpty
            ? null
            : images[safeSelectedImageIndex];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              onPressed: _goBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(_t(context, en: 'Stay', ru: 'Жильё', uz: 'Turar joy')),
            actions: [
              IconButton(
                onPressed: () =>
                    ref.read(favoritesIdsProvider.notifier).toggle(listing.id),
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? AppColors.danger : AppColors.text,
                ),
              ),
            ],
          ),
          body: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 124),
            children: [
              if (selectedImage != null) ...[
                RepaintBoundary(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: () =>
                          _openImageGallery(images, safeSelectedImageIndex),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: AspectRatio(
                          aspectRatio: 1.55,
                          child: PageView.builder(
                            controller: _imagePageController,
                            itemCount: images.length,
                            onPageChanged: (index) =>
                                setState(() => _selectedImageIndex = index),
                            itemBuilder: (context, index) =>
                                _ListingImage(imagePath: images[index]),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (images.length > 1) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 78,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final active = index == safeSelectedImageIndex;
                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            setState(() => _selectedImageIndex = index);
                            _imagePageController.jumpToPage(index);
                            _openImageGallery(images, index);
                          },
                          child: Container(
                            width: 92,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.borderStrong,
                                width: active ? 2 : 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: _ListingImage(imagePath: images[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 18),
              Text(
                listing.title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${listing.city}, ${listing.district}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionCard(
                accent: AppColors.primary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            (listing.description ?? '').trim().isEmpty
                                ? _t(
                                    context,
                                    en: 'No description yet.',
                                    ru: 'Описание пока не добавлено.',
                                    uz: 'Tavsif hali qo\'shilmagan.',
                                  )
                                : listing.description!.trim(),
                            style: const TextStyle(
                              color: Color(0xFF2B3445),
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _PriceBadge(label: _priceLabel(context, listing)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _InfoChip(
                          label:
                              '${_t(context, en: 'Guests', ru: 'Гости', uz: 'Mehmonlar')} ${listing.maxGuests}',
                        ),
                        _InfoChip(
                          label:
                              '${_t(context, en: 'Min days', ru: 'Мин. дней', uz: 'Min. kun')} ${listing.minDays}',
                        ),
                        _InfoChip(
                          label:
                              '${_t(context, en: 'Max days', ru: 'Макс. дней', uz: 'Max. kun')} ${listing.maxDays}',
                        ),
                        _InfoChip(label: _typeLabel(context, listing.type)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                accent: AppColors.secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        context,
                        en: 'Amenities',
                        ru: 'Удобства',
                        uz: 'Qulayliklar',
                      ),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (listing.amenities.isEmpty)
                      Text(
                        _t(
                          context,
                          en: 'Amenities are not available in this listing yet.',
                          ru: 'Удобства для этого жилья пока не указаны.',
                          uz: 'Qulayliklar hali ko\'rsatilmagan.',
                        ),
                        style: const TextStyle(color: AppColors.textMuted),
                      )
                    else
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: listing.amenities
                            .map(
                              (a) =>
                                  _InfoChip(label: _amenityLabel(context, a)),
                            )
                            .toList(growable: false),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                accent: AppColors.gold,
                child: _ReviewsSection(
                  listingId: widget.listingId,
                  sort: _reviewSort,
                  currentUserId: currentUserId,
                  onSortChanged: (value) => setState(() => _reviewSort = value),
                  onDeleteReview: _deleteReview,
                  onWriteReview: (reviews) =>
                      _openWriteReview(listing, reviews),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                accent: AppColors.primaryDeep,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        context,
                        en: 'Host contact',
                        ru: 'Контакты хозяина',
                        uz: 'Host aloqasi',
                      ),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      (listing.hostName ?? '').trim().isEmpty
                          ? _t(context, en: 'Host', ru: 'Хозяин', uz: 'Host')
                          : listing.hostName!.trim(),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      (listing.hostPhone ?? '').trim().isEmpty
                          ? _t(
                              context,
                              en: 'Please message the host in chat first.',
                              ru: 'Сначала свяжитесь с хозяином в чате.',
                              uz: 'Avval hostga chatda yozing.',
                            )
                          : '${_t(context, en: 'Phone', ru: 'Телефон', uz: 'Telefon')}: ${listing.hostPhone!.trim()}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () => _openChat(listing),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: Text(
                        _t(
                          context,
                          en: 'Message',
                          ru: 'Написать',
                          uz: 'Yozish',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                accent: AppColors.secondary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(
                        context,
                        en: 'Location',
                        ru: 'Локация',
                        uz: 'Joylashuv',
                      ),
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DetailLine(
                      label: _t(
                        context,
                        en: 'Address',
                        ru: 'Адрес',
                        uz: 'Manzil',
                      ),
                      value: '${listing.city}, ${listing.district}',
                    ),
                    if ((listing.landmark ?? '').trim().isNotEmpty)
                      _DetailLine(
                        label: _t(
                          context,
                          en: 'Landmark',
                          ru: 'Ориентир',
                          uz: 'Mo\'ljal',
                        ),
                        value: listing.landmark!.trim(),
                      ),
                    if ((listing.metro ?? '').trim().isNotEmpty)
                      _DetailLine(
                        label: _t(
                          context,
                          en: 'Metro',
                          ru: 'Метро',
                          uz: 'Metro',
                        ),
                        value: listing.metro!.trim(),
                      ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => _openMap(listing),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.primarySoft,
                              AppColors.secondarySoft,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  Icons.location_searching_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _t(
                                        context,
                                        en: 'Open in Google Maps',
                                        ru: 'Открыть в Google Maps',
                                        uz: 'Google Mapsda ochish',
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.text,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _t(
                                        context,
                                        en: 'Tap to open the location pin.',
                                        ru: 'Нажмите, чтобы открыть точку на карте.',
                                        uz: 'Xaritadagi nuqtani ochish uchun bosing.',
                                      ),
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.open_in_new_rounded,
                                color: AppColors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openChat(listing),
                      icon: const Icon(Icons.chat_bubble_outline_rounded),
                      label: Text(
                        _t(context, en: 'Chat', ru: 'Чат', uz: 'Chat'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => context.push(
                        '${RouteNames.bookingRequest}/${listing.id}',
                      ),
                      icon: const Icon(Icons.event_available_rounded),
                      label: Text(
                        _t(
                          context,
                          en: 'Request booking',
                          ru: 'Запросить бронь',
                          uz: 'Bron so\'rovi',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openWriteReview(Listing listing, List<Review> reviews) async {
    final userId = ref.read(authControllerProvider).valueOrNull?.user?.id;
    if (userId == null || userId.isEmpty) {
      _showSnack(
        _t(
          context,
          en: 'Please sign in again.',
          ru: 'Пожалуйста, войдите снова.',
          uz: 'Iltimos, qayta kiring.',
        ),
      );
      return;
    }
    if (reviews.any((review) => review.reviewerUserId == userId)) {
      _showSnack(
        _t(
          context,
          en: 'You already added a review for this stay.',
          ru: 'Вы уже оставили отзыв для этого жилья.',
          uz: 'Siz bu turar joy uchun sharh qoldirgansiz.',
        ),
      );
      return;
    }
    final bookings = await ref
        .read(bookingRepositoryProvider)
        .getGuestBookings(userId);
    if (!mounted) return;
    Booking? eligible;
    for (final booking in bookings) {
      final canReview =
          booking.listingId == listing.id &&
          booking.isReviewAllowed &&
          (booking.status == BookingStatus.completed ||
              booking.status == BookingStatus.confirmed);
      if (canReview) {
        eligible = booking;
        break;
      }
    }
    if (eligible == null) {
      _showSnack(
        _t(
          context,
          en: 'You can leave a review after a completed stay.',
          ru: 'Оставить отзыв можно после завершённого проживания.',
          uz: 'Sharhni faqat yakunlangan turardan keyin qoldirish mumkin.',
        ),
      );
      return;
    }
    await context.push('${RouteNames.reviewSubmit}/${eligible.id}');
    if (!mounted) return;
    ref.invalidate(listingReviewsProvider(widget.listingId));
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _t(
            dialogContext,
            en: 'Delete review?',
            ru: 'Удалить отзыв?',
            uz: 'Sharh o\'chirilsinmi?',
          ),
        ),
        content: Text(
          _t(
            dialogContext,
            en: 'This action cannot be undone.',
            ru: 'Это действие нельзя отменить.',
            uz: 'Bu amalni ortga qaytarib bo\'lmaydi.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              _t(dialogContext, en: 'Cancel', ru: 'Отмена', uz: 'Bekor qilish'),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              _t(dialogContext, en: 'Delete', ru: 'Удалить', uz: 'O\'chirish'),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(reviewsRepositoryProvider).deleteReview(reviewId);
    if (!mounted) return;
    ref.invalidate(listingReviewsProvider(widget.listingId));
    _showSnack(
      _t(
        context,
        en: 'Review deleted',
        ru: 'Отзыв удалён',
        uz: 'Sharh o\'chirildi',
      ),
    );
  }

  Future<void> _openChat(Listing listing) async {
    await context.push(
      '${RouteNames.chatList}?listingId=${listing.id}&hostId=${listing.hostId}',
    );
  }

  Future<void> _openMap(Listing listing) async {
    final query = <String>[
      listing.title,
      listing.city,
      listing.district,
      listing.landmark ?? '',
      listing.metro ?? '',
    ].where((item) => item.trim().isNotEmpty).join(', ');
    final opened = await openGoogleMaps(query: query);
    if (!opened && mounted) {
      _showSnack(
        _t(
          context,
          en: 'Could not open Google Maps.',
          ru: 'Не удалось открыть Google Maps.',
          uz: 'Google Mapsni ochib bo\'lmadi.',
        ),
      );
    }
  }

  Future<void> _openImageGallery(List<String> images, int initialIndex) async {
    if (images.isEmpty) {
      return;
    }
    final safeInitial = initialIndex.clamp(0, images.length - 1);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _ImageGalleryViewer(images: images, initialIndex: safeInitial),
      ),
    );
  }

  void _goBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(RouteNames.home);
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({
    required this.listingId,
    required this.sort,
    required this.currentUserId,
    required this.onSortChanged,
    required this.onDeleteReview,
    required this.onWriteReview,
  });

  final String listingId;
  final _ReviewSort sort;
  final String? currentUserId;
  final ValueChanged<_ReviewSort> onSortChanged;
  final Future<void> Function(String reviewId) onDeleteReview;
  final Future<void> Function(List<Review> reviews) onWriteReview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(listingReviewsProvider(listingId));
    return reviewsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text(
        _t(
          context,
          en: 'Could not load reviews.',
          ru: 'Не удалось загрузить отзывы.',
          uz: 'Sharhlarni yuklab bo\'lmadi.',
        ),
        style: const TextStyle(color: AppColors.textMuted),
      ),
      data: (reviews) {
        final sorted = _sortReviews(reviews, sort);
        final average = reviews.isEmpty
            ? 0.0
            : reviews.map((review) => review.rating).reduce((a, b) => a + b) /
                  reviews.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reviews.isEmpty)
              Text(
                _t(
                  context,
                  en: 'No guest reviews yet',
                  ru: 'Отзывов гостей пока нет',
                  uz: 'Hozircha sharh yo\'q',
                ),
                style: const TextStyle(color: AppColors.textMuted),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondarySoft,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.borderStrong),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 18,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _ratingText(average),
                          style: const TextStyle(
                            color: AppColors.primaryDeep,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${reviews.length} ${_t(context, en: 'reviews', ru: 'отзывов', uz: 'sharh')}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ChoiceChip(
                  label: Text(
                    _t(context, en: 'Newest', ru: 'Новые', uz: 'Yangi'),
                  ),
                  selected: sort == _ReviewSort.newest,
                  onSelected: (_) => onSortChanged(_ReviewSort.newest),
                ),
                ChoiceChip(
                  label: Text(
                    _t(context, en: 'Popular', ru: 'Популярные', uz: 'Mashhur'),
                  ),
                  selected: sort == _ReviewSort.popular,
                  onSelected: (_) => onSortChanged(_ReviewSort.popular),
                ),
                FilledButton.tonal(
                  onPressed: () => onWriteReview(reviews),
                  child: Text(
                    _t(
                      context,
                      en: 'Write review',
                      ru: 'Написать отзыв',
                      uz: 'Sharh yozish',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (reviews.isEmpty)
              Text(
                _t(
                  context,
                  en: 'This apartment does not have public reviews yet.',
                  ru: 'У этого жилья пока нет публичных отзывов.',
                  uz: 'Bu turar joyda hozircha ommaviy sharh yo\'q.',
                ),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  height: 1.45,
                ),
              )
            else ...[
              ...sorted
                  .take(2)
                  .map(
                    (review) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReviewTile(
                        review: review,
                        isOwn: review.reviewerUserId == currentUserId,
                        onDeleteReview: onDeleteReview,
                      ),
                    ),
                  ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => _showAllReviews(context, sorted),
                  icon: const Icon(Icons.reviews_outlined),
                  label: Text(
                    _t(
                      context,
                      en: 'See all reviews',
                      ru: 'Все отзывы',
                      uz: 'Barcha sharhlar',
                    ),
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  void _showAllReviews(BuildContext context, List<Review> reviews) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceSoft,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(
            children: [
              Text(
                _t(
                  context,
                  en: 'All reviews',
                  ru: 'Все отзывы',
                  uz: 'Barcha sharhlar',
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: reviews.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _ReviewTile(
                    review: reviews[index],
                    isOwn: reviews[index].reviewerUserId == currentUserId,
                    onDeleteReview: onDeleteReview,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({
    required this.review,
    required this.isOwn,
    required this.onDeleteReview,
  });

  final Review review;
  final bool isOwn;
  final Future<void> Function(String reviewId) onDeleteReview;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    (review.reviewerName ?? '').trim().isEmpty
                        ? _t(context, en: 'Guest', ru: 'Гость', uz: 'Mehmon')
                        : review.reviewerName!.trim(),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                _StarsRow(rating: review.rating),
                if (isOwn) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => onDeleteReview(review.id),
                    icon: const Icon(Icons.delete_outline_rounded),
                    tooltip: _t(
                      context,
                      en: 'Delete',
                      ru: 'Удалить',
                      uz: 'O\'chirish',
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              review.comment.trim().isEmpty
                  ? _t(
                      context,
                      en: 'No written comment.',
                      ru: 'Текст отзыва не добавлен.',
                      uz: 'Sharh matni qo\'shilmagan.',
                    )
                  : review.comment.trim(),
              style: const TextStyle(color: AppColors.textSoft, height: 1.45),
            ),
            const SizedBox(height: 6),
            Text(
              _dateLabel(review.createdAt),
              style: const TextStyle(color: AppColors.iconMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarsRow extends StatelessWidget {
  const _StarsRow({required this.rating});

  final int rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(5, (index) {
        final filled = index < rating;
        return Padding(
          padding: const EdgeInsets.only(left: 2),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: 18,
            color: AppColors.gold,
          ),
        );
      }),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120A1633),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (accent != null)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
              ),
            ),
          Padding(padding: const EdgeInsets.all(20), child: child),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(label, style: const TextStyle(color: AppColors.textSoft)),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  const _PriceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.secondarySoft, AppColors.primarySoftStrong],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderStrong),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22F2A120),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.primaryDeep,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: AppColors.textSoft,
            fontSize: 15,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    if (imagePath.startsWith('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
      );
    }
    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.low,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : const Center(child: CircularProgressIndicator()),
      errorBuilder: (_, _, _) => Container(
        color: AppColors.surfaceTint,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 36,
          color: AppColors.iconMuted,
        ),
      ),
    );
  }
}

class _ImageGalleryViewer extends StatefulWidget {
  const _ImageGalleryViewer({required this.images, required this.initialIndex});

  final List<String> images;
  final int initialIndex;

  @override
  State<_ImageGalleryViewer> createState() => _ImageGalleryViewerState();
}

class _ImageGalleryViewerState extends State<_ImageGalleryViewer> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1);
    _controller = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('${_index + 1} / ${widget.images.length}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (value) => setState(() => _index = value),
              itemBuilder: (context, index) {
                return _GalleryImage(imagePath: widget.images[index]);
              },
            ),
          ),
          if (widget.images.length > 1) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 84,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: widget.images.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final active = index == _index;
                  return GestureDetector(
                    onTap: () => _controller.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOut,
                    ),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: active ? Colors.white : Colors.white24,
                          width: active ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _ListingImage(imagePath: widget.images[index]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _GalleryImage extends StatelessWidget {
  const _GalleryImage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final imageWidget = imagePath.startsWith('assets/')
        ? Image.asset(
            imagePath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          )
        : Image.network(
            imagePath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
            loadingBuilder: (context, child, progress) => progress == null
                ? child
                : const Center(child: CircularProgressIndicator()),
            errorBuilder: (_, _, _) => const Icon(
              Icons.image_not_supported_outlined,
              size: 44,
              color: Colors.white54,
            ),
          );

    return Center(
      child: InteractiveViewer(
        panEnabled: false,
        minScale: 1,
        maxScale: 4,
        child: imageWidget,
      ),
    );
  }
}

List<Review> _sortReviews(List<Review> reviews, _ReviewSort sort) {
  final items = List<Review>.from(reviews);
  if (sort == _ReviewSort.popular) {
    items.sort((a, b) {
      final byRating = b.rating.compareTo(a.rating);
      if (byRating != 0) {
        return byRating;
      }
      return b.createdAt.compareTo(a.createdAt);
    });
  } else {
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  return items;
}

String _priceLabel(BuildContext context, Listing listing) {
  if (listing.type == ListingType.freeStay) {
    return _t(context, en: 'Free stay', ru: 'Бесплатно', uz: 'Bepul');
  }
  final price = listing.nightlyPriceUzs;
  if (price == null || price <= 0) {
    return _t(
      context,
      en: 'Price on request',
      ru: 'Цена по запросу',
      uz: 'Narx so\'rov bo\'yicha',
    );
  }
  return '${_formatUzs(price)} UZS';
}

String _typeLabel(BuildContext context, ListingType type) {
  switch (type) {
    case ListingType.room:
      return _t(context, en: 'Room', ru: 'Комната', uz: 'Xona');
    case ListingType.homePart:
      return _t(
        context,
        en: 'Home part',
        ru: 'Часть дома',
        uz: 'Uyning bir qismi',
      );
    case ListingType.freeStay:
      return _t(
        context,
        en: 'Free stay',
        ru: 'Бесплатное проживание',
        uz: 'Bepul turar joy',
      );
    case ListingType.apartment:
      return _t(context, en: 'Apartment', ru: 'Квартира', uz: 'Kvartira');
  }
}

String _amenityLabel(BuildContext context, ListingAmenity amenity) {
  switch (amenity) {
    case ListingAmenity.wifi:
      return 'Wi-Fi';
    case ListingAmenity.airConditioner:
      return _t(
        context,
        en: 'Air conditioner',
        ru: 'Кондиционер',
        uz: 'Konditsioner',
      );
    case ListingAmenity.kitchen:
      return _t(context, en: 'Kitchen', ru: 'Кухня', uz: 'Oshxona');
    case ListingAmenity.washingMachine:
      return _t(
        context,
        en: 'Washing machine',
        ru: 'Стиральная машина',
        uz: 'Kir yuvish mashinasi',
      );
    case ListingAmenity.parking:
      return _t(context, en: 'Parking', ru: 'Парковка', uz: 'Avtoturargoh');
    case ListingAmenity.privateBathroom:
      return _t(
        context,
        en: 'Private bathroom',
        ru: 'Отдельная ванная',
        uz: 'Shaxsiy hammom',
      );
    case ListingAmenity.kidsAllowed:
      return _t(
        context,
        en: 'Children allowed',
        ru: 'Можно с детьми',
        uz: 'Bolalar mumkin',
      );
    case ListingAmenity.petsAllowed:
      return _t(
        context,
        en: 'Pets allowed',
        ru: 'Можно с животными',
        uz: 'Uy hayvonlari mumkin',
      );
    case ListingAmenity.womenOnly:
      return _t(
        context,
        en: 'Women only',
        ru: 'Только для женщин',
        uz: 'Faqat ayollar uchun',
      );
    case ListingAmenity.menOnly:
      return _t(
        context,
        en: 'Men only',
        ru: 'Только для мужчин',
        uz: 'Faqat erkaklar uchun',
      );
    case ListingAmenity.hostLivesTogether:
      return _t(
        context,
        en: 'Host lives together',
        ru: 'Хозяин живёт вместе',
        uz: 'Host birga yashaydi',
      );
    case ListingAmenity.instantConfirm:
      return _t(
        context,
        en: 'Instant confirm',
        ru: 'Мгновенное подтверждение',
        uz: 'Darhol tasdiq',
      );
  }
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

String _ratingText(double rating) {
  final text = rating.toStringAsFixed(
    rating.truncateToDouble() == rating ? 0 : 1,
  );
  return '$text / 5';
}

String _dateLabel(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
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
