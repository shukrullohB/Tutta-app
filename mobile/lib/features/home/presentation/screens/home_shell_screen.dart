import '../../../../app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/enums/app_role.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../bookings/application/booking_request_controller.dart';
import '../../../chat/application/chat_provider.dart';
import '../../../listings/application/search_controller.dart';
import '../../../listings/domain/models/listing.dart';
import '../../../wishlist/application/favorites_controller.dart';
import '../../application/app_session_controller.dart';

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key});

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionControllerProvider);
    final role = session.activeRole;

    if (role == null) {
      return Scaffold(
        body: EmptyStateView(
          title: _shellText(
            context,
            en: 'Role is not selected',
            ru: 'Роль не выбрана',
            uz: 'Rol tanlanmagan',
          ),
          subtitle: _shellText(
            context,
            en: 'Please choose renter or host mode.',
            ru: 'Пожалуйста, выберите режим арендатора или хозяина.',
            uz: 'Iltimos, mehmon yoki host rejimini tanlang.',
          ),
        ),
      );
    }

    final tabs = _tabsForRole(context, role);
    final destinations = _destinationsForRole(context, role);

    if (_index >= tabs.length) {
      _index = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          role == AppRole.renter
              ? _shellText(
                  context,
                  en: 'Tutta Renter',
                  ru: 'Tutta Арендатор',
                  uz: 'Tutta Mehmon',
                )
              : _shellText(
                  context,
                  en: 'Tutta Host',
                  ru: 'Tutta Хозяин',
                  uz: 'Tutta Host',
                ),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: LanguageSelector(),
          ),
          IconButton(
            tooltip: 'Switch role',
            onPressed: () {
              ref.read(appSessionControllerProvider.notifier).clearRole();
              context.go(RouteNames.roleSelector);
            },
            icon: const Icon(Icons.swap_horiz),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              await ref
                  .read(appSessionControllerProvider.notifier)
                  .resetForFirstLaunch();
              if (context.mounted) {
                context.go(RouteNames.onboarding);
              }
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: 280.ms,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: KeyedSubtree(
          key: ValueKey('tab-$role-$_index'),
          child: tabs[_index],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: destinations,
      ),
    );
  }

  List<Widget> _tabsForRole(BuildContext context, AppRole role) {
    if (role == AppRole.host) {
      return [
        _HomeTab(
          title: _shellText(
            context,
            en: 'Host Dashboard',
            ru: 'Панель хоста',
            uz: 'Host paneli',
          ),
          subtitle: _shellText(
            context,
            en: 'Manage listings, requests, and occupancy.',
            ru: 'Управляйте объявлениями, заявками и занятостью.',
            uz: 'E\'lonlar, so\'rovlar va bandlikni boshqaring.',
          ),
        ),
        _HostListingsTab(
          title: _shellText(
            context,
            en: 'My Listings',
            ru: 'Мои объявления',
            uz: 'Mening e\'lonlarim',
          ),
          subtitle: _shellText(
            context,
            en: 'Create and update your listings in one place.',
            ru: 'Создавайте и обновляйте объявления в одном месте.',
            uz: 'E\'lonlarni bir joyda yarating va yangilang.',
          ),
        ),
        _HostRequestsEntryTab(
          title: _shellText(
            context,
            en: 'Requests',
            ru: 'Заявки',
            uz: 'So\'rovlar',
          ),
          subtitle: _shellText(
            context,
            en: 'Approve or decline booking requests in one place.',
            ru: 'Принимайте или отклоняйте заявки в одном месте.',
            uz: 'Bron so\'rovlarini shu yerda tasdiqlang yoki rad eting.',
          ),
        ),
        _ChatEntryTab(
          title: _shellText(context, en: 'Chats', ru: 'Чаты', uz: 'Chatlar'),
          subtitle: _shellText(
            context,
            en: 'Talk to your guests in real time.',
            ru: 'Общайтесь с гостями в реальном времени.',
            uz: 'Mehmonlar bilan real vaqtda yozishing.',
          ),
        ),
        _ProfileHomeTab(),
      ];
    }

    return [
      _RenterHomeTab(),
      _FavoritesEntryTab(
        title: AppLocalizations.of(context).favoritesTitle,
        subtitle: _shellText(
          context,
          en: 'Saved listings and host profiles.',
          ru: 'Сохраненные объявления и профили хозяев.',
          uz: 'Saqlangan e\'lonlar va host profillari.',
        ),
      ),
      _BookingsEntryTab(
        title: _shellText(
          context,
          en: 'Bookings',
          ru: 'Бронирования',
          uz: 'Bronlar',
        ),
        subtitle: _shellText(
          context,
          en: 'Track requests and upcoming stays in Uzbekistan.',
          ru: 'Следите за заявками и предстоящими поездками по Узбекистану.',
          uz: 'So\'rovlar va yaqin safarlarni shu yerda kuzating.',
        ),
      ),
      _ChatEntryTab(
        title: _shellText(context, en: 'Chats', ru: 'Чаты', uz: 'Chatlar'),
        subtitle: _shellText(
          context,
          en: 'Talk to hosts before booking.',
          ru: 'Общайтесь с хозяевами до бронирования.',
          uz: 'Bron qilishdan oldin hostlar bilan yozishing.',
        ),
      ),
      _ProfileHomeTab(),
    ];
  }

  List<NavigationDestination> _destinationsForRole(
    BuildContext context,
    AppRole role,
  ) {
    if (role == AppRole.host) {
      return [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: _shellText(
            context,
            en: 'Dashboard',
            ru: 'Панель',
            uz: 'Panel',
          ),
        ),
        NavigationDestination(
          icon: Icon(Icons.home_work_outlined),
          label: _shellText(
            context,
            en: 'Listings',
            ru: 'Объявления',
            uz: 'E\'lonlar',
          ),
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_turned_in_outlined),
          label: _shellText(
            context,
            en: 'Requests',
            ru: 'Заявки',
            uz: 'So\'rovlar',
          ),
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          label: _shellText(context, en: 'Chats', ru: 'Чаты', uz: 'Chatlar'),
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: _shellText(
            context,
            en: 'Profile',
            ru: 'Профиль',
            uz: 'Profil',
          ),
        ),
      ];
    }

    return [
      NavigationDestination(
        icon: const Icon(Icons.travel_explore),
        label: _shellText(context, en: 'Explore', ru: 'Поиск', uz: 'Qidiruv'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.favorite_border),
        label: AppLocalizations.of(context).favoritesTitle,
      ),
      NavigationDestination(
        icon: const Icon(Icons.calendar_month_outlined),
        label: _shellText(context, en: 'Bookings', ru: 'Брони', uz: 'Bronlar'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.chat_bubble_outline),
        label: _shellText(context, en: 'Chats', ru: 'Чаты', uz: 'Chatlar'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        label: _shellText(context, en: 'Profile', ru: 'Профиль', uz: 'Profil'),
      ),
    ];
  }
}

class _RenterHomeTab extends ConsumerStatefulWidget {
  const _RenterHomeTab();

  @override
  ConsumerState<_RenterHomeTab> createState() => _RenterHomeTabState();
}

class _RenterHomeTabState extends ConsumerState<_RenterHomeTab> {
  String _locationLabel = 'Anywhere';
  String _weekLabel = 'Any week';

  Future<void> _pickLocation() async {
    final search = ref.read(searchControllerProvider.notifier);
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        const cities = <String>[
          'Tashkent',
          'Samarkand',
          'Bukhara',
          'Andijan',
          'Namangan',
          'Fergana',
        ];
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: cities
                .map(
                  (city) => ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(city),
                    onTap: () => Navigator.of(context).pop(city),
                  ),
                )
                .toList(growable: false),
          ),
        );
      },
    );

    if (picked == null || !mounted) {
      return;
    }
    setState(() => _locationLabel = picked);
    search.setCity(picked);
    await search.search();
    if (mounted) {
      context.go(RouteNames.search);
    }
  }

  Future<void> _pickWeek() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Select stay dates',
    );
    if (picked == null || !mounted) {
      return;
    }
    final nights = picked.end.difference(picked.start).inDays;
    if (nights > 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maximum stay is 30 nights. Please choose shorter dates.',
          ),
        ),
      );
      return;
    }
    setState(() {
      _weekLabel =
          '${picked.start.day}.${picked.start.month} - ${picked.end.day}.${picked.end.month}';
    });
    context.go(RouteNames.search);
  }

  void _openQuickMenu() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.search_outlined),
                title: Text(
                  _shellText(
                    context,
                    en: 'Search stays',
                    ru: 'Искать жилье',
                    uz: 'Uy qidirish',
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  this.context.go(RouteNames.search);
                },
              ),
              ListTile(
                leading: const Icon(Icons.favorite_border),
                title: Text(AppLocalizations.of(context).favoritesTitle),
                onTap: () => Navigator.of(context).pop(),
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: Text(AppLocalizations.of(context).settingsTitle),
                onTap: () {
                  Navigator.of(context).pop();
                  this.context.go(RouteNames.settings);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
        children: [
          Row(
            children: [
              IconButton(
                onPressed: _openQuickMenu,
                icon: const Icon(Icons.menu, color: Color(0xFF2E5E5A)),
              ),
              const SizedBox(width: 6),
              const Text(
                'Tutta',
                style: TextStyle(
                  color: Color(0xFF234B56),
                  fontSize: 34 / 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => context.go(RouteNames.settings),
                icon: const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFF3CDAD),
                  child: Icon(Icons.person, size: 16, color: Color(0xFF9A6D4B)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2F6C8F), Color(0xFF59A6A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2259A6A6),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Find your next stay in Uzbekistan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verified hosts, short-term only, and booking flow built for local travel.',
                  style: TextStyle(color: Color(0xE6FFFFFF), height: 1.35),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => context.go(RouteNames.search),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF2F6C8F),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        icon: const Icon(Icons.search),
                        label: const Text('Explore homes'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          final search = ref.read(
                            searchControllerProvider.notifier,
                          );
                          search.setIncludeFreeStay(true);
                          search.search();
                          context.go(RouteNames.search);
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0x66FFFFFF)),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        icon: const Icon(Icons.swap_horiz),
                        label: const Text('Free Stay'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickCityChip(
                  label: 'Tashkent',
                  onTap: () {
                    final search = ref.read(searchControllerProvider.notifier);
                    search.setCity('Tashkent');
                    search.search();
                    context.go(RouteNames.search);
                  },
                ),
                _QuickCityChip(
                  label: 'Samarkand',
                  onTap: () {
                    final search = ref.read(searchControllerProvider.notifier);
                    search.setCity('Samarkand');
                    search.search();
                    context.go(RouteNames.search);
                  },
                ),
                _QuickCityChip(
                  label: 'Bukhara',
                  onTap: () {
                    final search = ref.read(searchControllerProvider.notifier);
                    search.setCity('Bukhara');
                    search.search();
                    context.go(RouteNames.search);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => context.go(RouteNames.search),
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFE9EAEE),
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: const Row(
                children: [
                  Icon(Icons.search, color: Color(0xFF6E7585)),
                  SizedBox(width: 10),
                  Text(
                    'Where to?',
                    style: TextStyle(
                      color: Color(0xFF6E7585),
                      fontSize: 18 / 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HomePill(
                  icon: Icons.place_outlined,
                  label: _locationLabel,
                  onTap: _pickLocation,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _HomePill(
                  icon: Icons.calendar_month_outlined,
                  label: _weekLabel,
                  onTap: _pickWeek,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _SegmentTile(
                label: 'HOMES',
                icon: Icons.home,
                active: true,
                width: 112,
                onTap: () {
                  final search = ref.read(searchControllerProvider.notifier);
                  search.setTypes(const <ListingType>[
                    ListingType.apartment,
                    ListingType.homePart,
                  ]);
                  search.search();
                  context.go(RouteNames.search);
                },
              ),
              const SizedBox(width: 10),
              _SegmentTile(
                label: 'ROOMS',
                icon: Icons.bed_outlined,
                width: 112,
                onTap: () {
                  final search = ref.read(searchControllerProvider.notifier);
                  search.setTypes(const <ListingType>[ListingType.room]);
                  search.search();
                  context.go(RouteNames.search);
                },
              ),
              const SizedBox(width: 10),
              _SegmentTile(
                label: 'SKILL\nEXCHANGE',
                icon: Icons.swap_horiz,
                width: 120,
                onTap: () {
                  final search = ref.read(searchControllerProvider.notifier);
                  search.setIncludeFreeStay(true);
                  search.search();
                  context.go(RouteNames.search);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'CURATED SELECTION',
            style: TextStyle(
              color: Color(0xC89A6B1C),
              letterSpacing: 2.2,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text(
                'Featured Stays',
                style: TextStyle(
                  color: Color(0xFF072A73),
                  fontWeight: FontWeight.w700,
                  fontSize: 44 / 2,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => context.go(RouteNames.search),
                child: const Row(
                  children: [
                    Text(
                      'View all',
                      style: TextStyle(
                        color: Color(0xFF072A73),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Color(0xFF072A73),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _FeaturedStayCard(
            listingId: 'l1',
            title: 'Amirsoy Mountain Chalet',
            location: 'Tashkent Region, Uzbekistan',
            price: '1 350 000 UZS / night',
            rating: '4.92',
            imageAssetPath: 'assets/images/home1.png',
          ),
          const SizedBox(height: 12),
          const _FeaturedStayCard(
            listingId: 'l4',
            title: 'Modern Loft in Mirobod',
            location: 'Mirobod, Tashkent',
            price: '510 000 UZS / night',
            rating: '4.85',
            imageAssetPath: 'assets/images/home2.png',
          ),
          const SizedBox(height: 18),
          const Text(
            'Nearby Gems',
            style: TextStyle(
              color: Color(0xFF072A73),
              fontWeight: FontWeight.w700,
              fontSize: 44 / 2,
            ),
          ),
          const SizedBox(height: 12),
          const _NearbyCard(
            listingId: 'l3',
            title: 'Samarkand Courtyard Flat',
            subtitle: 'Samarkand • 3 nights',
            price: '850 000 UZS / night',
            rating: '4.95',
            imageAssetPath: 'assets/images/home2.png',
            color: Color(0xFF5B8F86),
          ),
          const SizedBox(height: 10),
          const _NearbyCard(
            listingId: 'l2',
            title: 'Bukhara Old City Studio',
            subtitle: 'Bukhara • 2 nights',
            price: '620 000 UZS / night',
            rating: '4.78',
            imageAssetPath: 'assets/images/home4.png',
            color: Color(0xFFA9957B),
          ),
          const SizedBox(height: 10),
          const _NearbyCard(
            listingId: 'l1',
            title: 'Cozy Living Room Stay',
            subtitle: 'Tashkent • 2 nights',
            price: '740 000 UZS / night',
            rating: '4.88',
            imageAssetPath: 'assets/images/home3.png',
            color: Color(0xFF7A7B87),
          ),
        ],
      ).animate().fadeIn(duration: 260.ms),
    );
  }
}

class _HomePill extends StatelessWidget {
  const _HomePill({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF0F3),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: const Color(0xFF3E4658)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 18 / 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickCityChip extends StatelessWidget {
  const _QuickCityChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFFDCE3EF)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.location_city_outlined, size: 14),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    required this.label,
    required this.icon,
    required this.width,
    this.active = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final double width;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
        height: 90,
        decoration: BoxDecoration(
          color: active ? const Color(0xFF072A73) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ]
              : const [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: active ? Colors.white : const Color(0xFF2F374A)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF2F374A),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedStayCard extends ConsumerWidget {
  const _FeaturedStayCard({
    required this.listingId,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.imageAssetPath,
  });

  final String listingId;
  final String title;
  final String location;
  final String price;
  final String rating;
  final String imageAssetPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesIdsProvider.select((ids) => ids.contains(listingId)),
    );
    return InkWell(
      onTap: () => context.push('${RouteNames.listingDetails}/$listingId'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 320,
                  width: double.infinity,
                  child: Image.asset(imageAssetPath, fit: BoxFit.cover),
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFF072A73),
                      borderRadius: BorderRadius.all(Radius.circular(999)),
                    ),
                    child: Text(
                      price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: InkWell(
                    onTap: () => ref
                        .read(favoritesIdsProvider.notifier)
                        .toggle(listingId),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0x88FFFFFF),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? const Color(0xFFD64545)
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            color: Color(0xFF071E57),
                            fontSize: 34 / 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          location,
                          style: TextStyle(color: Color(0xFF4E5568)),
                        ),
                      ],
                    ),
                  ),
                  _RatingBadge(value: rating),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NearbyCard extends ConsumerWidget {
  const _NearbyCard({
    required this.listingId,
    required this.title,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.color,
    this.imageAssetPath,
  });

  final String listingId;
  final String title;
  final String subtitle;
  final String price;
  final String rating;
  final Color color;
  final String? imageAssetPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesIdsProvider.select((ids) => ids.contains(listingId)),
    );

    return InkWell(
      onTap: () => context.push('${RouteNames.listingDetails}/$listingId'),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 108,
                height: 98,
                child: imageAssetPath == null
                    ? Container(color: color)
                    : Image.asset(imageAssetPath!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 34 / 2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => ref
                            .read(favoritesIdsProvider.notifier)
                            .toggle(listingId),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite
                              ? const Color(0xFFD64545)
                              : const Color(0xFF808697),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF4E5568)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          color: Color(0xFF072A73),
                          fontWeight: FontWeight.w700,
                          fontSize: 28 / 2,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        rating,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
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

class _RatingBadge extends StatelessWidget {
  const _RatingBadge({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E2CB),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.star, size: 14, color: Color(0xFF6A480A)),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF6A480A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF1E2133), Color(0xFF141522)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2A000000),
                blurRadius: 30,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xB3FFFFFF)),
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Search'),
                      onPressed: () => context.go(RouteNames.search),
                    ),
                    ActionChip(
                      label: const Text('Bookings'),
                      onPressed: () => context.go(RouteNames.bookings),
                    ),
                    ActionChip(
                      label: const Text('Chat'),
                      onPressed: () => context.go(RouteNames.chatList),
                    ),
                    ActionChip(
                      label: const Text('Premium'),
                      onPressed: () => context.go(RouteNames.premiumPaywall),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
    );
  }
}

class _FavoritesEntryTab extends StatelessWidget {
  const _FavoritesEntryTab({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _SoftPreviewCard(
      title: title,
      subtitle: subtitle,
      icon: Icons.favorite_border,
      child: const _FavoritesPreview(),
    );
  }
}

class _FavoritesPreview extends ConsumerWidget {
  const _FavoritesPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ids = ref.watch(favoritesIdsProvider).toList(growable: false);

    if (ids.isEmpty) {
      return const Text(
        'No saved listings yet. Tap the heart on any listing to save it here.',
        style: TextStyle(color: Color(0xFF64748B), height: 1.4),
      );
    }

    final previewIds = ids.take(3).toList(growable: false);
    final future = Future.wait(
      previewIds.map((id) => ref.read(listingsRepositoryProvider).getById(id)),
    );

    return FutureBuilder<List<Listing?>>(
      future: future,
      builder: (context, snapshot) {
        final listings = (snapshot.data ?? const <Listing?>[])
            .whereType<Listing>()
            .toList(growable: false);

        return Column(
          children: listings
              .map(
                (listing) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PreviewRow(
                    icon: Icons.favorite_border,
                    title: listing.title,
                    subtitle: '${listing.city}, ${listing.district}',
                    onTap: () => context.push(
                      '${RouteNames.listingDetails}/${listing.id}',
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

class _ChatEntryTab extends StatelessWidget {
  const _ChatEntryTab({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF12203A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF64748B), height: 1.3),
            ),
            const SizedBox(height: 16),
            const Expanded(child: _ChatPreview()),
          ],
        ),
      ),
    );
  }
}

class _ChatPreview extends ConsumerWidget {
  const _ChatPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final threadsAsync = ref.watch(chatThreadsProvider);

    return threadsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(minHeight: 3),
      ),
      error: (_, _) => const Text(
        'Could not load chats yet.',
        style: TextStyle(color: Color(0xFF64748B)),
      ),
      data: (threads) {
        if (threads.isEmpty) {
          return const Text(
            'No chats yet. When you contact a host, the conversation will appear here immediately.',
            style: TextStyle(color: Color(0xFF64748B), height: 1.4),
          );
        }

        return ListView.separated(
          itemCount: threads.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final thread = threads[index];
            return _PreviewRow(
              icon: Icons.chat_bubble_outline,
              title: _threadTitle(
                context,
                thread,
                ref.watch(appSessionControllerProvider).activeRole,
              ),
              subtitle: thread.lastMessage?.isNotEmpty == true
                  ? thread.lastMessage!
                  : _shellText(
                      context,
                      en: 'Tap to open conversation',
                      ru: 'Нажмите, чтобы открыть диалог',
                      uz: 'Suhbatni ochish uchun bosing',
                    ),
              trailing: thread.unreadCount > 0 ? '${thread.unreadCount}' : null,
              onTap: () => context.go(RouteNames.chatList),
            );
          },
        );
      },
    );
  }
}

class _ProfileHomeTab extends ConsumerWidget {
  const _ProfileHomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider).valueOrNull?.user;
    final role = ref.watch(appSessionControllerProvider).activeRole;
    final isHost = role == AppRole.host;
    final firstName = auth?.firstName ?? 'Tutta';
    final lastName = auth?.lastName ?? 'User';
    final displayName = '$firstName $lastName'.trim();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3C7A89), Color(0xFF7DB4A5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x223C7A89),
                  blurRadius: 24,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0x33FFFFFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isHost
                            ? _shellText(
                                context,
                                en: 'Host profile, support, and occupancy tools.',
                                ru: 'Профиль хоста, поддержка и инструменты занятости.',
                                uz: 'Host profili, yordam va bandlik vositalari.',
                              )
                            : _shellText(
                                context,
                                en: 'Trips, premium access, and account preferences.',
                                ru: 'Поездки, premium-доступ и настройки аккаунта.',
                                uz: 'Safarlar, premium kirish va akkaunt sozlamalari.',
                              ),
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
          ).animate().fadeIn(duration: 260.ms).slideY(begin: 0.06, end: 0),
          const SizedBox(height: 16),
          _ProfileStatRow(
            isHost: isHost,
            userId: auth?.id,
            isPremium: auth?.isPremium ?? false,
          ),
          const SizedBox(height: 16),
          _ProfileActionCard(
            icon: Icons.settings_outlined,
            title: _shellText(
              context,
              en: 'Settings',
              ru: 'Настройки',
              uz: 'Sozlamalar',
            ),
            subtitle: _shellText(
              context,
              en: 'Language, privacy, and app preferences',
              ru: 'Язык, приватность и настройки приложения',
              uz: 'Til, maxfiylik va ilova sozlamalari',
            ),
            accent: const Color(0xFFF4F0E7),
            iconColor: const Color(0xFF3C7A89),
            onTap: () => context.go(RouteNames.settings),
          ),
          const SizedBox(height: 10),
          _ProfileActionCard(
            icon: Icons.workspace_premium_outlined,
            title: _shellText(
              context,
              en: 'Premium',
              ru: 'Премиум',
              uz: 'Premium',
            ),
            subtitle: _shellText(
              context,
              en: 'Manage Free Stay access and premium benefits',
              ru: 'Управление доступом Free Stay и premium-возможностями',
              uz: 'Free Stay kirishi va premium imkoniyatlarini boshqarish',
            ),
            accent: const Color(0xFFF7E7C1),
            iconColor: const Color(0xFFB7791F),
            onTap: () => context.go(RouteNames.premiumPaywall),
          ),
          const SizedBox(height: 10),
          _ProfileActionCard(
            icon: Icons.notifications_none,
            title: _shellText(
              context,
              en: 'Notifications',
              ru: 'Уведомления',
              uz: 'Bildirishnomalar',
            ),
            subtitle: _shellText(
              context,
              en: 'Booking updates and activity alerts',
              ru: 'Обновления бронирований и важные уведомления',
              uz: 'Bron yangilanishlari va muhim bildirishnomalar',
            ),
            accent: const Color(0xFFF4F0E7),
            iconColor: const Color(0xFF3C7A89),
            onTap: () => context.go(RouteNames.notifications),
          ),
          const SizedBox(height: 10),
          _ProfileActionCard(
            icon: Icons.support_agent_outlined,
            title: _shellText(
              context,
              en: 'Support',
              ru: 'Поддержка',
              uz: 'Yordam',
            ),
            subtitle: _shellText(
              context,
              en: 'Help center and contact options',
              ru: 'Центр помощи и способы связи',
              uz: 'Yordam markazi va aloqa usullari',
            ),
            accent: const Color(0xFFF4F0E7),
            iconColor: const Color(0xFF3C7A89),
            onTap: () => context.go(RouteNames.support),
          ),
          const SizedBox(height: 10),
          _ProfileActionCard(
            icon: Icons.swap_horiz,
            title: isHost
                ? _shellText(
                    context,
                    en: 'Switch to renter mode',
                    ru: 'Переключиться в режим арендатора',
                    uz: 'Mehmon rejimiga o\'tish',
                  )
                : _shellText(
                    context,
                    en: 'Switch to host mode',
                    ru: 'Переключиться в режим хоста',
                    uz: 'Host rejimiga o\'tish',
                  ),
            subtitle: _shellText(
              context,
              en: 'Change your current Tutta role instantly',
              ru: 'Мгновенно поменять текущую роль в Tutta',
              uz: 'Tutta ichidagi joriy rolni darhol almashtirish',
            ),
            accent: const Color(0xFFF4F0E7),
            iconColor: const Color(0xFF3C7A89),
            onTap: () {
              ref.read(appSessionControllerProvider.notifier).clearRole();
              context.go(RouteNames.roleSelector);
            },
          ),
          const SizedBox(height: 14),
          _ProfileActionCard(
            icon: Icons.logout_rounded,
            title: _shellText(
              context,
              en: 'Sign out',
              ru: 'Выйти',
              uz: 'Chiqish',
            ),
            subtitle: _shellText(
              context,
              en: 'Leave your account and return to Get Started',
              ru: 'Выйти из аккаунта и вернуться к Get Started',
              uz: 'Akkauntdan chiqib Get Started sahifasiga qaytish',
            ),
            accent: const Color(0xFFFDECEC),
            iconColor: const Color(0xFFD64545),
            onTap: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              await ref
                  .read(appSessionControllerProvider.notifier)
                  .resetForFirstLaunch();
              if (context.mounted) {
                context.go(RouteNames.onboarding);
              }
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileStatRow extends ConsumerWidget {
  const _ProfileStatRow({
    required this.isHost,
    required this.userId,
    required this.isPremium,
  });

  final bool isHost;
  final String? userId;
  final bool isPremium;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesCount = ref.watch(favoritesIdsProvider).length;

    if (userId == null) {
      return Row(
        children: [
          Expanded(
            child: _ProfileStatCard(
              label: isHost
                  ? _shellText(
                      context,
                      en: 'Requests',
                      ru: 'Заявки',
                      uz: 'So\'rovlar',
                    )
                  : _shellText(
                      context,
                      en: 'Trips',
                      ru: 'Поездки',
                      uz: 'Safarlar',
                    ),
              value: '0',
              icon: isHost ? Icons.inbox_outlined : Icons.luggage_outlined,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ProfileStatCard(
              label: _shellText(
                context,
                en: 'Saved',
                ru: 'Сохранено',
                uz: 'Saqlangan',
              ),
              value: '$favoritesCount',
              icon: Icons.favorite_border,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _ProfileStatCard(
              label: _shellText(
                context,
                en: 'Premium',
                ru: 'Премиум',
                uz: 'Premium',
              ),
              value: isPremium
                  ? _shellText(context, en: 'ON', ru: 'ВКЛ', uz: 'YOQILGAN')
                  : _shellText(context, en: 'OFF', ru: 'ВЫКЛ', uz: 'O\'CHIQ'),
              icon: Icons.workspace_premium_outlined,
            ),
          ),
        ],
      );
    }

    final future = isHost
        ? ref.read(bookingRepositoryProvider).getHostBookings(userId!)
        : ref.read(bookingRepositoryProvider).getGuestBookings(userId!);

    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        final bookings = snapshot.data ?? const [];
        return Row(
          children: [
            Expanded(
              child: _ProfileStatCard(
                label: isHost
                    ? _shellText(
                        context,
                        en: 'Requests',
                        ru: 'Заявки',
                        uz: 'So\'rovlar',
                      )
                    : _shellText(
                        context,
                        en: 'Trips',
                        ru: 'Поездки',
                        uz: 'Safarlar',
                      ),
                value: '${bookings.length}',
                icon: isHost ? Icons.inbox_outlined : Icons.luggage_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProfileStatCard(
                label: _shellText(
                  context,
                  en: 'Saved',
                  ru: 'Сохранено',
                  uz: 'Saqlangan',
                ),
                value: '$favoritesCount',
                icon: Icons.favorite_border,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _ProfileStatCard(
                label: _shellText(
                  context,
                  en: 'Premium',
                  ru: 'Премиум',
                  uz: 'Premium',
                ),
                value: isPremium
                    ? _shellText(context, en: 'ON', ru: 'ВКЛ', uz: 'YOQILGAN')
                    : _shellText(context, en: 'OFF', ru: 'ВЫКЛ', uz: 'O\'CHIQ'),
                icon: Icons.workspace_premium_outlined,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileStatCard extends StatelessWidget {
  const _ProfileStatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1B5ED8), size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF12203A),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}

class _ProfileActionCard extends StatelessWidget {
  const _ProfileActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = const Color(0xFFF4F7FC),
    this.iconColor = const Color(0xFF145EE3),
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF12203A),
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingsEntryTab extends StatelessWidget {
  const _BookingsEntryTab({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _SoftPreviewCard(
      title: title,
      subtitle: subtitle,
      icon: Icons.calendar_month_outlined,
      child: const _BookingsPreview(),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0);
  }
}

class _BookingsPreview extends ConsumerWidget {
  const _BookingsPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authControllerProvider).valueOrNull?.user?.id;
    final role = ref.watch(appSessionControllerProvider).activeRole;

    if (userId == null || role == null) {
      return const Text(
        'Sign in and choose a role to see your bookings here.',
        style: TextStyle(color: Color(0xFF64748B)),
      );
    }

    final future = role == AppRole.host
        ? ref.read(bookingRepositoryProvider).getHostBookings(userId)
        : ref.read(bookingRepositoryProvider).getGuestBookings(userId);

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const Text(
            'No bookings yet. Your upcoming trips and requests will appear here.',
            style: TextStyle(color: Color(0xFF64748B), height: 1.4),
          );
        }

        return Column(
          children: items
              .take(3)
              .map(
                (booking) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PreviewRow(
                    icon: Icons.calendar_month_outlined,
                    title: 'Listing ${booking.listingId}',
                    subtitle:
                        '${booking.checkInDate.day}.${booking.checkInDate.month} - ${booking.checkOutDate.day}.${booking.checkOutDate.month}',
                    trailing: _bookingStatusLabel(context, booking.status),
                    onTap: () => context.go(RouteNames.bookings),
                  ),
                ),
              )
              .toList(growable: false),
        );
      },
    );
  }
}

String _shellText(
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

String _bookingStatusLabel(BuildContext context, Object status) {
  final value = status.toString().split('.').last;
  switch (value) {
    case 'pendingHostApproval':
      return _shellText(
        context,
        en: 'Pending',
        ru: 'Ожидает',
        uz: 'Kutilmoqda',
      );
    case 'confirmed':
      return _shellText(
        context,
        en: 'Confirmed',
        ru: 'Подтверждено',
        uz: 'Tasdiqlandi',
      );
    case 'cancelledByGuest':
    case 'cancelledByHost':
      return _shellText(
        context,
        en: 'Cancelled',
        ru: 'Отменено',
        uz: 'Bekor qilingan',
      );
    case 'completed':
      return _shellText(
        context,
        en: 'Completed',
        ru: 'Завершено',
        uz: 'Yakunlangan',
      );
    default:
      return value;
  }
}

String _threadTitle(BuildContext context, dynamic thread, AppRole? role) {
  if (role == AppRole.host) {
    return _shellText(
      context,
      en: 'Guest #${thread.guestUserId}',
      ru: 'Гость #${thread.guestUserId}',
      uz: 'Mehmon #${thread.guestUserId}',
    );
  }
  return _shellText(
    context,
    en: 'Host #${thread.hostUserId}',
    ru: 'Хозяин #${thread.hostUserId}',
    uz: 'Host #${thread.hostUserId}',
  );
}

class _SoftPreviewCard extends StatelessWidget {
  const _SoftPreviewCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F2)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x140F172A),
                blurRadius: 18,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F6FF),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: const Color(0xFF2E6FDD)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF12203A),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFD),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE5EBF5)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF2E6FDD), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF12203A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F0FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    trailing!,
                    style: const TextStyle(
                      color: Color(0xFF2459B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HostRequestsEntryTab extends StatelessWidget {
  const _HostRequestsEntryTab({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF232337), Color(0xFF171826)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0x1FFFFFFF)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xB3FFFFFF)),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go(RouteNames.hostRequests),
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: const Text('Open Host Requests'),
                ),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
    );
  }
}

class _HostListingsTab extends StatelessWidget {
  const _HostListingsTab({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [Color(0xFF21253A), Color(0xFF141726)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0x1FFFFFFF)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2A000000),
                blurRadius: 30,
                offset: Offset(0, 20),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xB3FFFFFF)),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                      onPressed: () => context.go(RouteNames.createListing),
                      icon: const Icon(Icons.add_home_work_outlined),
                      label: const Text('Add new listing'),
                    )
                    .animate()
                    .fadeIn(duration: 260.ms)
                    .slideX(begin: -0.08, end: 0),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                      onPressed: () => context.go(RouteNames.hostRequests),
                      icon: const Icon(Icons.assignment_turned_in_outlined),
                      label: const Text('Open host requests'),
                    )
                    .animate(delay: 70.ms)
                    .fadeIn(duration: 260.ms)
                    .slideX(begin: -0.08, end: 0),
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.08, end: 0),
    );
  }
}
