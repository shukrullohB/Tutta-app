import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_response_parser.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../listings/application/search_controller.dart';
import '../../../listings/domain/models/listing.dart';

final _publicProfileProvider =
    FutureProvider.family<_PublicProfileData, String>((ref, userId) async {
      final apiClient = ref.watch(apiClientProvider);
      final profileResult = await apiClient.get(
        ApiEndpoints.userPublicProfile(userId),
      );

      final profile = await profileResult.when(
        success: (data) async {
          final payload = ApiResponseParser.extractMap(data);
          return _PublicProfileData(
            id: payload['id']?.toString() ?? userId,
            firstName: payload['first_name']?.toString().trim() ?? '',
            lastName: payload['last_name']?.toString().trim() ?? '',
            email: payload['email']?.toString().trim() ?? '',
            phone: payload['phone_number']?.toString().trim(),
            role: payload['role']?.toString().trim() ?? 'user',
            createdAt:
                DateTime.tryParse(payload['created_at']?.toString() ?? '') ??
                DateTime.now(),
            activeListingsCount:
                int.tryParse(
                  payload['active_listings_count']?.toString() ?? '',
                ) ??
                0,
          );
        },
        failure: (failure) => throw Exception(failure.message),
      );

      final hasPremium =
          ref.watch(authControllerProvider).valueOrNull?.user?.isPremium ??
          false;
      List<Listing> listings = const <Listing>[];
      try {
        listings = await ref
            .watch(listingsRepositoryProvider)
            .getByHost(hostId: userId, hasPremium: hasPremium);
      } catch (_) {
        listings = const <Listing>[];
      }

      return profile.copyWith(listings: listings);
    });

class PublicProfileScreen extends ConsumerWidget {
  const PublicProfileScreen({
    super.key,
    required this.userId,
    required this.displayName,
  });

  final String userId;
  final String displayName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(_publicProfileProvider(userId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(RouteNames.home),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: Text(
          _tr(context, en: 'Profile', ru: 'Профиль', uz: 'Profil'),
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: profileAsync.when(
        data: (profile) {
          final resolvedProfile = profile.withFallbackName(displayName);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
            children: [
              _ProfileHeaderCard(profile: resolvedProfile),
              const SizedBox(height: 18),
              _SectionTitle(
                title: _tr(
                  context,
                  en: 'About person',
                  ru: 'О пользователе',
                  uz: 'Foydalanuvchi haqida',
                ),
              ),
              const SizedBox(height: 10),
              _ProfileFactsCard(profile: resolvedProfile),
              const SizedBox(height: 18),
              _SectionTitle(
                title: _tr(
                  context,
                  en: 'Available stays',
                  ru: 'Объявления',
                  uz: 'Mavjud joylar',
                ),
                subtitle: _tr(
                  context,
                  en: 'Current rentals from this user.',
                  ru: 'Активные варианты жилья этого пользователя.',
                  uz: 'Ushbu foydalanuvchining faol e’lonlari.',
                ),
              ),
              const SizedBox(height: 10),
              if (resolvedProfile.listings.isEmpty)
                _EmptyListingsCard(
                  label: _tr(
                    context,
                    en: 'No active stays are published yet.',
                    ru: 'Активных объявлений пока нет.',
                    uz: 'Hali faol e’lonlar yo‘q.',
                  ),
                )
              else
                ...resolvedProfile.listings.map(
                  (listing) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _HostListingCard(listing: listing),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error.toString().replaceFirst('Exception: ', ''),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({required this.profile});

  final _PublicProfileData profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A1A365D),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0x22FFFFFF),
              borderRadius: BorderRadius.circular(22),
            ),
            alignment: Alignment.center,
            child: Text(
              profile.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.email.isNotEmpty
                      ? profile.email
                      : _tr(
                          context,
                          en: 'Email is not available',
                          ru: 'Email не указан',
                          uz: 'Email ko‘rsatilmagan',
                        ),
                  style: const TextStyle(
                    color: AppColors.surfaceSoft,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _HeaderBadge(
                      icon: Icons.home_work_outlined,
                      label: '${profile.activeListingsCount}',
                    ),
                    const SizedBox(width: 10),
                    _HeaderBadge(
                      icon: Icons.verified_user_outlined,
                      label: profile.roleLabel(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x20FFFFFF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(subtitle!, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ],
    );
  }
}

class _ProfileFactsCard extends StatelessWidget {
  const _ProfileFactsCard({required this.profile});

  final _PublicProfileData profile;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _FactRow(
            icon: Icons.phone_outlined,
            label: _tr(context, en: 'Phone', ru: 'Телефон', uz: 'Telefon'),
            value: profile.phone?.isNotEmpty == true
                ? profile.phone!
                : _tr(
                    context,
                    en: 'Phone not provided',
                    ru: 'Телефон не указан',
                    uz: 'Telefon ko‘rsatilmagan',
                  ),
          ),
          const SizedBox(height: 14),
          _FactRow(
            icon: Icons.calendar_today_outlined,
            label: _tr(
              context,
              en: 'Joined',
              ru: 'В сервисе',
              uz: 'Qo‘shilgan',
            ),
            value: profile.memberSinceLabel,
          ),
          const SizedBox(height: 14),
          _FactRow(
            icon: Icons.home_work_outlined,
            label: _tr(
              context,
              en: 'Active stays',
              ru: 'Активные варианты',
              uz: 'Faol joylar',
            ),
            value: '${profile.activeListingsCount}',
          ),
        ],
      ),
    );
  }
}

class _FactRow extends StatelessWidget {
  const _FactRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.iconMuted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HostListingCard extends StatelessWidget {
  const _HostListingCard({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => context.push(RouteNames.listingDetailsById(listing.id)),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 94,
                  height: 94,
                  child: _ListingPreviewImage(
                    imageUrl: listing.imageUrls.isEmpty
                        ? null
                        : listing.imageUrls.first,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [listing.city, listing.district].join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      listing.nightlyPriceUzs == null
                          ? _tr(
                              context,
                              en: 'Free stay',
                              ru: 'Бесплатно',
                              uz: 'Bepul',
                            )
                          : '${listing.nightlyPriceUzs} UZS',
                      style: const TextStyle(
                        color: AppColors.primaryDeep,
                        fontWeight: FontWeight.w800,
                      ),
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
}

class _ListingPreviewImage extends StatelessWidget {
  const _ListingPreviewImage({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _fallback();
    }
    if (imageUrl!.startsWith('assets/')) {
      return Image.asset(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return Image.network(
      imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.surfaceTint,
      alignment: Alignment.center,
      child: const Icon(Icons.image_outlined, color: AppColors.iconMuted),
    );
  }
}

class _EmptyListingsCard extends StatelessWidget {
  const _EmptyListingsCard({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(label, style: const TextStyle(color: AppColors.textMuted)),
    );
  }
}

class _PublicProfileData {
  const _PublicProfileData({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.createdAt,
    required this.activeListingsCount,
    this.listings = const <Listing>[],
    this.fallbackName,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String role;
  final DateTime createdAt;
  final int activeListingsCount;
  final List<Listing> listings;
  final String? fallbackName;

  String get displayName {
    final full = '$firstName $lastName'.trim();
    if (full.isNotEmpty) {
      return full;
    }
    if ((fallbackName ?? '').trim().isNotEmpty) {
      return fallbackName!.trim();
    }
    if (email.isNotEmpty) {
      return email;
    }
    return 'Tutta user';
  }

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (parts.isEmpty) {
      return 'TT';
    }
    return parts.map((part) => part[0].toUpperCase()).join();
  }

  String get memberSinceLabel =>
      '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}';

  String roleLabel(BuildContext context) {
    switch (role) {
      case 'host':
        return _tr(context, en: 'Host', ru: 'Хозяин', uz: 'Host');
      case 'guest':
        return _tr(context, en: 'Guest', ru: 'Гость', uz: 'Mehmon');
      default:
        return role;
    }
  }

  _PublicProfileData withFallbackName(String value) {
    return copyWith(fallbackName: value);
  }

  _PublicProfileData copyWith({List<Listing>? listings, String? fallbackName}) {
    return _PublicProfileData(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      role: role,
      createdAt: createdAt,
      activeListingsCount: activeListingsCount,
      listings: listings ?? this.listings,
      fallbackName: fallbackName ?? this.fallbackName,
    );
  }
}

String _tr(
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
