import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/utils/google_maps_launcher.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../reviews/application/review_submit_controller.dart';
import '../../../reviews/domain/models/review.dart';
import '../../../wishlist/application/favorites_controller.dart';
import '../../application/search_controller.dart';
import '../../domain/models/listing.dart';

class ListingDetailsScreen extends ConsumerStatefulWidget {
  const ListingDetailsScreen({super.key, required this.listingId});
  final String listingId;
  @override
  ConsumerState<ListingDetailsScreen> createState() =>
      _ListingDetailsScreenState();
}

enum _ReviewSort { popular, newest }

class _ListingDetailsScreenState extends ConsumerState<ListingDetailsScreen> {
  late Future<Listing?> _listingFuture;
  _ReviewSort _reviewSort = _ReviewSort.popular;

  @override
  void initState() {
    super.initState();
    _listingFuture = _loadListing();
  }

  Future<Listing?> _loadListing() async =>
      (await ref.read(listingsRepositoryProvider).getById(widget.listingId))
          as Listing?;

  List<Review> _sort(List<Review> reviews) {
    final items = [...reviews];
    items.sort((a, b) {
      if (_reviewSort == _ReviewSort.newest)
        return b.createdAt.compareTo(a.createdAt);
      if (a.rating != b.rating) return b.rating.compareTo(a.rating);
      return b.createdAt.compareTo(a.createdAt);
    });
    return items;
  }

  Future<void> _writeReview(BuildContext context, Listing listing) async {
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              context,
              en: 'Please sign in first.',
              ru: 'Сначала войдите в аккаунт.',
              uz: 'Avval akkauntga kiring.',
            ),
          ),
        ),
      );
      return;
    }
    var rating = 5;
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => StatefulBuilder(
        builder: (d, setDialogState) => AlertDialog(
          title: Text(
            _t(d, en: 'Write review', ru: 'Оставить отзыв', uz: 'Sharh yozish'),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final v = i + 1;
                  return IconButton(
                    onPressed: () => setDialogState(() => rating = v),
                    icon: Icon(
                      v <= rating
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: const Color(0xFFE0A82E),
                    ),
                  );
                }),
              ),
              TextField(
                controller: c,
                minLines: 3,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: _t(
                    d,
                    en: 'Tell others what stood out during your stay',
                    ru: 'Расскажите, что вам понравилось во время проживания',
                    uz: 'Bu joyda sizga nimalar yoqqanini yozing',
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(d).pop(false),
              child: Text(MaterialLocalizations.of(d).cancelButtonLabel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(d).pop(true),
              child: Text(_t(d, en: 'Save', ru: 'Сохранить', uz: 'Saqlash')),
            ),
          ],
        ),
      ),
    );
    final text = c.text.trim();
    c.dispose();
    if (ok != true) return;
    await ref
        .read(reviewsRepositoryProvider)
        .submitReview(
          bookingId:
              'public_${listing.id}_${user.id}_${DateTime.now().millisecondsSinceEpoch}',
          listingId: listing.id,
          reviewerUserId: user.id,
          hostUserId: listing.hostId,
          rating: rating,
          comment: text.isEmpty
              ? _t(
                  context,
                  en: 'Clean apartment and smooth stay.',
                  ru: 'Чистые апартаменты и комфортное проживание.',
                  uz: 'Toza apartament va qulay turar joy.',
                )
              : text,
        );
    ref.invalidate(listingReviewsProvider(listing.id));
  }

  Future<void> _deleteReview(BuildContext context, Review review) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(
          _t(
            d,
            en: 'Delete review?',
            ru: 'Удалить отзыв?',
            uz: 'Sharh o‘chirilsinmi?',
          ),
        ),
        content: Text(
          _t(
            d,
            en: 'You can remove only your own review.',
            ru: 'Можно удалить только свой отзыв.',
            uz: 'Faqat o‘zingizning sharhingizni o‘chira olasiz.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(d).pop(false),
            child: Text(MaterialLocalizations.of(d).cancelButtonLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(d).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD64545),
            ),
            child: Text(_t(d, en: 'Delete', ru: 'Удалить', uz: 'O‘chirish')),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(reviewsRepositoryProvider).deleteReview(review.id);
    ref.invalidate(listingReviewsProvider(review.listingId));
  }

  Future<void> _openReviews(
    BuildContext context,
    Listing listing,
    List<Review> reviews,
  ) {
    final me = ref.read(authControllerProvider).valueOrNull?.user?.id ?? '';
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFFFFCF7),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheet) {
        final sorted = _sort(reviews);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SizedBox(
              height: MediaQuery.of(sheet).size.height * 0.82,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD9D2C5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFE0A82E)),
                      const SizedBox(width: 8),
                      Text(
                        _t(sheet, en: 'Reviews', ru: 'Отзывы', uz: 'Sharhlar'),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17324D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _SortChip(
                        label: _t(
                          sheet,
                          en: 'Popular',
                          ru: 'Популярные',
                          uz: 'Ommabop',
                        ),
                        active: _reviewSort == _ReviewSort.popular,
                        onTap: () =>
                            setState(() => _reviewSort = _ReviewSort.popular),
                      ),
                      _SortChip(
                        label: _t(
                          sheet,
                          en: 'Newest',
                          ru: 'Новые',
                          uz: 'Yangi',
                        ),
                        active: _reviewSort == _ReviewSort.newest,
                        onTap: () =>
                            setState(() => _reviewSort = _ReviewSort.newest),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () {
                          Navigator.of(sheet).pop();
                          _writeReview(context, listing);
                        },
                        icon: const Icon(Icons.edit_note_rounded),
                        label: Text(
                          _t(
                            sheet,
                            en: 'Write review',
                            ru: 'Оставить отзыв',
                            uz: 'Sharh yozish',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: sorted.isEmpty
                        ? Center(
                            child: Text(
                              _t(
                                sheet,
                                en: 'No reviews yet.',
                                ru: 'Пока нет отзывов.',
                                uz: 'Hozircha sharhlar yo‘q.',
                              ),
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                          )
                        : ListView.separated(
                            itemCount: sorted.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final r = sorted[index];
                              return _ReviewCard(
                                reviewerLabel: r.reviewerUserId == me
                                    ? 'You'
                                    : _reviewerLabel(r.reviewerUserId),
                                rating: r.rating,
                                comment: r.comment,
                                dateLabel: _reviewDate(context, r.createdAt),
                                onDelete: r.reviewerUserId == me
                                    ? () => _deleteReview(context, r)
                                    : null,
                              );
                            },
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Listing?>(
      future: _listingFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        if (snap.hasError)
          return _ErrorScaffold(
            message: snap.error.toString().replaceFirst('Exception: ', ''),
            onRetry: () => setState(() => _listingFuture = _loadListing()),
          );
        final listing = snap.data;
        if (listing == null)
          return _ErrorScaffold(
            message: _t(
              context,
              en: 'Apartment not found.',
              ru: 'Апартаменты не найдены.',
              uz: 'Apartament topilmadi.',
            ),
            onRetry: () => context.go(RouteNames.search),
          );
        final isFavorite = ref.watch(
          favoritesIdsProvider.select((ids) => ids.contains(listing.id)),
        );
        final reviewsAsync = ref.watch(listingReviewsProvider(listing.id));
        final host = _HostContact.fromListing(listing);
        return Scaffold(
          backgroundColor: const Color(0xFFF6F3EC),
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: SizedBox(
                        height: 320,
                        child: _ImageGallery(images: listing.imageUrls),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      listing.title,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF17324D),
                          ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 18,
                          color: Color(0xFF6D7280),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _location(listing),
                            style: const TextStyle(
                              color: Color(0xFF6D7280),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _Panel(
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
                                          uz: 'Tavsif hali qo‘shilmagan.',
                                        )
                                      : listing.description!,
                                  style: const TextStyle(
                                    color: Color(0xFF1F2430),
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7E9C2),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFFD8B45B),
                                  ),
                                ),
                                child: Text(
                                  listing.nightlyPriceUzs == null
                                      ? _t(
                                          context,
                                          en: 'Free stay',
                                          ru: 'Бесплатно',
                                          uz: 'Bepul',
                                        )
                                      : '${listing.nightlyPriceUzs} UZS',
                                  style: const TextStyle(
                                    color: Color(0xFF6A480A),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _Tag(
                                label:
                                    '${_t(context, en: 'Guests', ru: 'Гости', uz: 'Mehmonlar')} ${listing.maxGuests}',
                              ),
                              _Tag(
                                label:
                                    '${_t(context, en: 'Min days', ru: 'Мин. дней', uz: 'Min kun')} ${listing.minDays}',
                              ),
                              _Tag(
                                label:
                                    '${_t(context, en: 'Max days', ru: 'Макс. дней', uz: 'Max kun')} ${listing.maxDays}',
                              ),
                              _Tag(label: _type(context, listing.type)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Panel(
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
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2430),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (listing.amenities.isEmpty)
                            Text(
                              _t(
                                context,
                                en: 'No amenities added yet.',
                                ru: 'Удобства пока не добавлены.',
                                uz: 'Qulayliklar hali qo‘shilmagan.',
                              ),
                              style: const TextStyle(color: Color(0xFF6D7280)),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: listing.amenities
                                  .map((a) => _Tag(label: _amenity(context, a)))
                                  .toList(growable: false),
                            ),
                        ],
                      ),
                    ),
                    if (listing.imageUrls.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t(
                                context,
                                en: 'Photos',
                                ru: 'Фотографии',
                                uz: 'Rasmlar',
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1F2430),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 92,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: listing.imageUrls.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) => ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: SizedBox(
                                    width: 116,
                                    child: _ListingImage(
                                      imageUrl: listing.imageUrls[index],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    _Panel(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _t(
                                    context,
                                    en: 'Host contact',
                                    ru: 'Контакты арендодателя',
                                    uz: 'Host kontakti',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1F2430),
                                  ),
                                ),
                              ),
                              FilledButton.tonalIcon(
                                onPressed: () => context.push(
                                  '${RouteNames.chatList}?listingId=${listing.id}&hostId=${listing.hostId}',
                                ),
                                icon: const Icon(Icons.chat_bubble_outline),
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
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.person_outline,
                            label: _t(
                              context,
                              en: 'Name',
                              ru: 'Имя',
                              uz: 'Ism',
                            ),
                            value: host.name,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.phone_outlined,
                            label: _t(
                              context,
                              en: 'Phone',
                              ru: 'Телефон',
                              uz: 'Telefon',
                            ),
                            value: host.phone,
                          ),
                          const SizedBox(height: 8),
                          _InfoRow(
                            icon: Icons.badge_outlined,
                            label: _t(
                              context,
                              en: 'About this stay',
                              ru: 'По какому объекту',
                              uz: 'Qaysi e’lon bo‘yicha',
                            ),
                            value: listing.title,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _Panel(
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
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2430),
                            ),
                          ),
                          const SizedBox(height: 10),
                          if ((listing.landmark ?? '').trim().isNotEmpty)
                            _InfoRow(
                              icon: Icons.place_outlined,
                              label: _t(
                                context,
                                en: 'Landmark',
                                ru: 'Ориентир',
                                uz: 'Mo‘ljal',
                              ),
                              value: listing.landmark!.trim(),
                            ),
                          if ((listing.metro ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _InfoRow(
                              icon: Icons.subway_outlined,
                              label: _t(
                                context,
                                en: 'Metro',
                                ru: 'Метро',
                                uz: 'Metro',
                              ),
                              value: listing.metro!.trim(),
                            ),
                          ],
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () => openGoogleMaps(
                              query: '${listing.title}, ${_location(listing)}',
                            ),
                            icon: const Icon(Icons.map_outlined),
                            label: Text(
                              _t(
                                context,
                                en: 'Open in Google Maps',
                                ru: 'Открыть в Google Maps',
                                uz: 'Google Maps’da ochish',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    reviewsAsync.when(
                      loading: () => const _Panel(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                      error: (_, _) => _Panel(
                        child: Text(
                          _t(
                            context,
                            en: 'Could not load reviews yet.',
                            ru: 'Пока не удалось загрузить отзывы.',
                            uz: 'Sharhlarni hozircha yuklab bo‘lmadi.',
                          ),
                          style: const TextStyle(color: Color(0xFF64748B)),
                        ),
                      ),
                      data: (reviews) {
                        final sorted = _sort(reviews);
                        final average = reviews.isEmpty
                            ? 0.0
                            : reviews
                                      .map((r) => r.rating)
                                      .reduce((a, b) => a + b) /
                                  reviews.length;
                        return _Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFFFCE8BB),
                                          Color(0xFFF6C86A),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.star_rounded,
                                      size: 30,
                                      color: Color(0xFF915F14),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _t(
                                            context,
                                            en: 'Reviews',
                                            ru: 'Отзывы',
                                            uz: 'Sharhlar',
                                          ),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF1F2430),
                                            fontSize: 20,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (reviews.isEmpty)
                                          Text(
                                            _t(
                                              context,
                                              en: 'No reviews yet',
                                              ru: 'Пока нет отзывов',
                                              uz: 'Hozircha sharhlar yo‘q',
                                            ),
                                            style: const TextStyle(
                                              color: Color(0xFF64748B),
                                            ),
                                          )
                                        else
                                          Row(
                                            children: [
                                              Text(
                                                '${_rating(average)} / 5',
                                                style: const TextStyle(
                                                  color: Color(0xFF425166),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(
                                                Icons.star_rounded,
                                                size: 18,
                                                color: Color(0xFFE0A82E),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                '${reviews.length} ${_t(context, en: 'reviews', ru: 'отзывов', uz: 'sharh')}',
                                                style: const TextStyle(
                                                  color: Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _SortChip(
                                    label: _t(
                                      context,
                                      en: 'Popular',
                                      ru: 'Популярные',
                                      uz: 'Ommabop',
                                    ),
                                    active: _reviewSort == _ReviewSort.popular,
                                    onTap: () => setState(
                                      () => _reviewSort = _ReviewSort.popular,
                                    ),
                                  ),
                                  _SortChip(
                                    label: _t(
                                      context,
                                      en: 'Newest',
                                      ru: 'Новые',
                                      uz: 'Yangi',
                                    ),
                                    active: _reviewSort == _ReviewSort.newest,
                                    onTap: () => setState(
                                      () => _reviewSort = _ReviewSort.newest,
                                    ),
                                  ),
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.visibility_outlined,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _t(
                                        context,
                                        en: 'See all',
                                        ru: 'Смотреть все',
                                        uz: 'Barchasi',
                                      ),
                                    ),
                                    onPressed: () =>
                                        _openReviews(context, listing, reviews),
                                  ),
                                  FilledButton.tonalIcon(
                                    onPressed: () =>
                                        _writeReview(context, listing),
                                    icon: const Icon(Icons.edit_note_rounded),
                                    label: Text(
                                      _t(
                                        context,
                                        en: 'Write review',
                                        ru: 'Оставить отзыв',
                                        uz: 'Sharh yozish',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (sorted.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _ReviewCard(
                                  reviewerLabel: _reviewerLabel(
                                    sorted.first.reviewerUserId,
                                  ),
                                  rating: sorted.first.rating,
                                  comment: sorted.first.comment,
                                  dateLabel: _reviewDate(
                                    context,
                                    sorted.first.createdAt,
                                  ),
                                  onDelete: null,
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  child: _FloatingIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => context.canPop()
                        ? context.pop()
                        : context.go(RouteNames.search),
                  ),
                ),
                Positioned(
                  top: 18,
                  right: 18,
                  child: _FloatingIconButton(
                    icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                    iconColor: isFavorite
                        ? const Color(0xFFD64545)
                        : const Color(0xFF17324D),
                    onTap: () => ref
                        .read(favoritesIdsProvider.notifier)
                        .toggle(listing.id),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE1E3E8)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(
                        '${RouteNames.chatList}?listingId=${listing.id}&hostId=${listing.hostId}',
                      ),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: Text(
                        _t(context, en: 'Chat', ru: 'Чат', uz: 'Chat'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => context.push(
                        '${RouteNames.bookingRequest}/${listing.id}',
                      ),
                      icon: const Icon(Icons.event_available_outlined),
                      label: Text(
                        _t(
                          context,
                          en: 'Request booking',
                          ru: 'Запросить бронь',
                          uz: 'Bron so‘rovi',
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
}

class _FloatingIconButton extends StatelessWidget {
  const _FloatingIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = const Color(0xFF17324D),
  });
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xF8FFFFFF),
    elevation: 6,
    borderRadius: BorderRadius.circular(999),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 46,
        height: 46,
        child: Icon(icon, color: iconColor),
      ),
    ),
  );
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Scaffold(
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
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.images});
  final List<String> images;
  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const _ListingImage(imageUrl: null);
    if (images.length == 1) return _ListingImage(imageUrl: images.first);
    return Row(
      children: [
        Expanded(flex: 3, child: _ListingImage(imageUrl: images.first)),
        const SizedBox(width: 6),
        Expanded(
          flex: 2,
          child: Column(
            children: [
              Expanded(child: _ListingImage(imageUrl: images[1])),
              const SizedBox(height: 6),
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _ListingImage(
                      imageUrl: images.length > 2 ? images[2] : images.first,
                    ),
                    if (images.length > 3)
                      Container(
                        color: const Color(0x66000000),
                        alignment: Alignment.center,
                        child: Text(
                          '+${images.length - 3}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 22,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({required this.imageUrl});
  final String? imageUrl;
  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) return _placeholder();
    if (imageUrl!.startsWith('assets/'))
      return Image.asset(
        imageUrl!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://'))
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _placeholder(showLoader: true),
        errorBuilder: (_, _, _) => _placeholder(),
      );
    return _placeholder();
  }

  Widget _placeholder({bool showLoader = false}) => Container(
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

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFFFFCF7),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE6DCCB)),
    ),
    child: child,
  );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.reviewerLabel,
    required this.rating,
    required this.comment,
    required this.dateLabel,
    required this.onDelete,
  });
  final String reviewerLabel;
  final int rating;
  final String comment;
  final String dateLabel;
  final VoidCallback? onDelete;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFF8F4EA),
      borderRadius: BorderRadius.circular(18),
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
              (i) => Icon(
                i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                size: 17,
                color: const Color(0xFFE0A82E),
              ),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(999),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.delete_outline,
                    color: Color(0xFFD64545),
                    size: 18,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          comment,
          style: const TextStyle(color: Color(0xFF425166), height: 1.35),
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
      ],
    ),
  );
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
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

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFFF0F2F6),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: const Color(0xFFD6D9E0)),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF2A3040),
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: const Color(0xFF6D7280)),
      const SizedBox(width: 8),
      Expanded(
        child: RichText(
          text: TextSpan(
            style: const TextStyle(
              color: Color(0xFF425166),
              fontSize: 14,
              height: 1.35,
            ),
            children: [
              TextSpan(
                text: '$label: ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: value),
            ],
          ),
        ),
      ),
    ],
  );
}

String _reviewerLabel(String id) =>
    'Guest ${id.length > 4 ? id.substring(id.length - 4) : id}';
String _reviewDate(BuildContext context, DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return _t(
    context,
    en: 'Posted on $d.$m.$y',
    ru: 'Опубликовано $d.$m.$y',
    uz: 'Joylandi: $d.$m.$y',
  );
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

String _rating(double value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toStringAsFixed(1);
String _location(Listing listing) => listing.district.trim().isEmpty
    ? listing.city
    : '${listing.city}, ${listing.district}';
String _type(BuildContext context, ListingType type) {
  switch (type) {
    case ListingType.apartment:
      return _t(context, en: 'Apartment', ru: 'Апартаменты', uz: 'Apartament');
    case ListingType.room:
      return _t(context, en: 'Room', ru: 'Комната', uz: 'Xona');
    case ListingType.homePart:
      return _t(context, en: 'Home part', ru: 'Часть дома', uz: 'Uy qismi');
    case ListingType.freeStay:
      return _t(context, en: 'Free stay', ru: 'Free Stay', uz: 'Free Stay');
  }
}

String _amenity(BuildContext context, ListingAmenity a) {
  switch (a) {
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
        uz: 'Alohida hammom',
      );
    case ListingAmenity.kidsAllowed:
      return _t(
        context,
        en: 'Kids allowed',
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
        uz: 'Faqat ayollar',
      );
    case ListingAmenity.menOnly:
      return _t(
        context,
        en: 'Men only',
        ru: 'Только для мужчин',
        uz: 'Faqat erkaklar',
      );
    case ListingAmenity.hostLivesTogether:
      return _t(
        context,
        en: 'Host lives together',
        ru: 'Хозяин живет рядом',
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

class _HostContact {
  const _HostContact({required this.name, required this.phone});
  final String name;
  final String phone;
  static _HostContact fromListing(Listing listing) {
    switch (listing.hostId) {
      case 'h1':
        return const _HostContact(
          name: 'Aziza Karimova',
          phone: '+998 90 111 22 33',
        );
      case 'h4':
        return const _HostContact(
          name: 'Dilshod Rakhimov',
          phone: '+998 90 444 55 66',
        );
      case 'h5':
        return const _HostContact(
          name: 'Madina Yuldasheva',
          phone: '+998 90 555 66 77',
        );
      default:
        return _HostContact(
          name: 'Host ${listing.hostId}',
          phone: '+998 90 000 00 00',
        );
    }
  }
}
