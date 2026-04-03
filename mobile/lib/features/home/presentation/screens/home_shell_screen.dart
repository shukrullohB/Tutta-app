import '../../../../app/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/l10n/ru_fallbacks.dart';
import '../../../../core/enums/app_role.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../bookings/application/booking_request_controller.dart';
import '../../../bookings/domain/models/booking.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../listings/application/search_controller.dart';
import '../../../listings/domain/models/listing.dart';
import '../../../listings/domain/models/listing_search_params.dart';
import '../../../wishlist/application/favorites_controller.dart';
import '../../application/app_session_controller.dart';

final _homeExploreListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final hasPremium =
      ref.watch(authControllerProvider).valueOrNull?.user?.isPremium ?? false;
  final params = const ListingSearchParams(
    city: 'Tashkent',
    district: '',
    guests: 1,
    includeFreeStay: false,
  );
  final localItems = ref.watch(locallyCreatedHostListingsProvider);
  try {
    final items = await ref
        .watch(listingsRepositoryProvider)
        .search(params: params, hasPremium: hasPremium);
    return mergeCreatedListings(remote: items, local: localItems)
        .where(
          (listing) =>
              matchesSearchParams(listing, params, hasPremium: hasPremium),
        )
        .toList(growable: false);
  } on AppException {
    return localItems
        .where(
          (listing) =>
              matchesSearchParams(listing, params, hasPremium: hasPremium),
        )
        .toList(growable: false);
  }
});

final _homeFavoriteListingsProvider = FutureProvider<List<Listing>>((
  ref,
) async {
  final favoriteIds = ref.watch(favoritesIdsProvider);
  if (favoriteIds.isEmpty) {
    return const <Listing>[];
  }

  final repository = ref.watch(listingsRepositoryProvider);
  final items = await Future.wait(favoriteIds.map(repository.getById));
  return items.whereType<Listing>().toList(growable: false);
});

final _guestBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull?.user;
  if (user == null) {
    return const <Booking>[];
  }
  return ref.watch(bookingRepositoryProvider).getGuestBookings(user.id);
});

final _hostBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final user = ref.watch(authControllerProvider).valueOrNull?.user;
  if (user == null) {
    return const <Booking>[];
  }
  return ref.watch(bookingRepositoryProvider).getHostBookings(user.id);
});

class HomeShellScreen extends ConsumerStatefulWidget {
  const HomeShellScreen({super.key, this.initialTab});

  final String? initialTab;

  @override
  ConsumerState<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends ConsumerState<HomeShellScreen> {
  int _index = 0;
  String? _initializedTabToken;

  @override
  void initState() {
    super.initState();
    final role = ref.read(appSessionControllerProvider).activeRole;
    if (role == null) {
      return;
    }
    final requestedIndex = _routeTabToIndex(role, widget.initialTab);
    if (requestedIndex != null) {
      _index = requestedIndex;
      _initializedTabToken = '${role.name}:${widget.initialTab}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(appSessionControllerProvider);
    final role = session.activeRole;

    if (role == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            _copy(
              context,
              en: 'Choose mode',
              ru: 'Выберите режим',
              uz: 'Rejimni tanlang',
            ),
          ),
          actions: const [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: LanguageSelector(),
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.swap_horiz_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  _copy(
                    context,
                    en: 'Please choose renter or host mode to continue.',
                    ru: 'Пожалуйста, выберите режим гостя или хоста, чтобы продолжить.',
                    uz: 'Davom etish uchun mehmon yoki host rejimini tanlang.',
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => context.go(RouteNames.roleSelector),
                  child: Text(
                    _copy(
                      context,
                      en: 'Open role selector',
                      ru: 'Открыть выбор роли',
                      uz: 'Rol tanlashni ochish',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final tabs = _tabsForRole(role);
    final destinations = _destinationsForRole(context, role);
    final requestedTab = widget.initialTab;
    final pendingTab = session.pendingHomeTab;
    final effectiveTab = pendingTab ?? requestedTab;
    final requestedIndex = _routeTabToIndex(role, effectiveTab);
    final requestedToken = effectiveTab == null
        ? null
        : '${role.name}:$effectiveTab';
    final selectedIndex = _index >= tabs.length ? 0 : _index;

    if (requestedIndex != null &&
        requestedToken != null &&
        requestedToken != _initializedTabToken &&
        requestedIndex != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _index = requestedIndex;
            _initializedTabToken = requestedToken;
          });
          ref.read(appSessionControllerProvider.notifier).clearPendingHomeTab();
        }
      });
    } else if (requestedToken != null &&
        requestedToken != _initializedTabToken) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _initializedTabToken = requestedToken);
          ref.read(appSessionControllerProvider.notifier).clearPendingHomeTab();
        }
      });
    }

    if (selectedIndex != _index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _index = selectedIndex);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          role == AppRole.host
              ? _copy(
                  context,
                  en: 'Tutta Host',
                  ru: 'Tutta Хост',
                  uz: 'Tutta Host',
                )
              : _copy(
                  context,
                  en: 'Tutta Renter',
                  ru: 'Tutta Арендатор',
                  uz: 'Tutta Mehmon',
                ),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: LanguageSelector(),
          ),
          IconButton(
            tooltip: _copy(
              context,
              en: 'Choose role',
              ru: 'Сменить роль',
              uz: 'Rolni almashtirish',
            ),
            onPressed: _showRoleSwitcher,
            icon: const Icon(Icons.swap_horiz_rounded),
          ),
          IconButton(
            tooltip: _copy(context, en: 'Sign out', ru: 'Выйти', uz: 'Chiqish'),
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: selectedIndex, children: tabs),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: destinations,
      ),
      floatingActionButton: role == AppRole.host && selectedIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => context.push(RouteNames.createListing),
              icon: const Icon(Icons.add_home_work_outlined),
              label: Text(
                _copy(
                  context,
                  en: 'New listing',
                  ru: 'Новое объявление',
                  uz: 'Yangi e\'lon',
                ),
              ),
            )
          : null,
    );
  }

  List<Widget> _tabsForRole(AppRole role) {
    return role == AppRole.host
        ? <Widget>[
            const _HostDashboardTab(),
            const _HostListingsTab(),
            const _BookingsTab(role: AppRole.host),
            const ChatListScreen(embedded: true),
            _ProfileTab(onSignOut: _signOut, onSwitchRole: _showRoleSwitcher),
          ]
        : <Widget>[
            const _ExploreTab(),
            const _FavoritesTab(),
            const _BookingsTab(role: AppRole.renter),
            const ChatListScreen(embedded: true),
            _ProfileTab(onSignOut: _signOut, onSwitchRole: _showRoleSwitcher),
          ];
  }

  List<NavigationDestination> _destinationsForRole(
    BuildContext context,
    AppRole role,
  ) {
    if (role == AppRole.host) {
      return <NavigationDestination>[
        NavigationDestination(
          icon: const Icon(Icons.dashboard_outlined),
          selectedIcon: const Icon(Icons.dashboard_rounded),
          label: _copy(context, en: 'Dashboard', ru: 'Панель', uz: 'Panel'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.home_work_outlined),
          selectedIcon: const Icon(Icons.home_work_rounded),
          label: _copy(
            context,
            en: 'Listings',
            ru: 'Объявления',
            uz: 'E\'lonlar',
          ),
        ),
        NavigationDestination(
          icon: const Icon(Icons.calendar_month_outlined),
          selectedIcon: const Icon(Icons.calendar_month_rounded),
          label: _copy(context, en: 'Bookings', ru: 'Брони', uz: 'Bronlar'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.chat_bubble_outline_rounded),
          selectedIcon: const Icon(Icons.chat_bubble_rounded),
          label: _copy(context, en: 'Chats', ru: 'Чаты', uz: 'Chatlar'),
        ),
        NavigationDestination(
          icon: const Icon(Icons.person_outline_rounded),
          selectedIcon: const Icon(Icons.person_rounded),
          label: _copy(context, en: 'Profile', ru: 'Профиль', uz: 'Profil'),
        ),
      ];
    }

    return <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.travel_explore_outlined),
        selectedIcon: const Icon(Icons.travel_explore_rounded),
        label: _copy(context, en: 'Explore', ru: 'Поиск', uz: 'Qidiruv'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.favorite_outline_rounded),
        selectedIcon: const Icon(Icons.favorite_rounded),
        label: _copy(
          context,
          en: 'Favorites',
          ru: 'Избранное',
          uz: 'Sevimlilar',
        ),
      ),
      NavigationDestination(
        icon: const Icon(Icons.calendar_month_outlined),
        selectedIcon: const Icon(Icons.calendar_month_rounded),
        label: _copy(context, en: 'Bookings', ru: 'Брони', uz: 'Bronlar'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.chat_bubble_outline_rounded),
        selectedIcon: const Icon(Icons.chat_bubble_rounded),
        label: _copy(context, en: 'Chats', ru: 'Чаты', uz: 'Chatlar'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline_rounded),
        selectedIcon: const Icon(Icons.person_rounded),
        label: _copy(context, en: 'Profile', ru: 'Профиль', uz: 'Profil'),
      ),
    ];
  }

  Future<void> _showRoleSwitcher() async {
    final currentRole = ref.read(appSessionControllerProvider).activeRole;
    if (currentRole == null || !mounted) {
      if (mounted) {
        context.go(RouteNames.roleSelector);
      }
      return;
    }

    final selectedRole = await showModalBottomSheet<AppRole>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surfaceSoft,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _copy(
                    sheetContext,
                    en: 'Choose role',
                    ru: 'Выберите роль',
                    uz: 'Rolni tanlang',
                  ),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _copy(
                    sheetContext,
                    en: 'Use renter mode to book stays and host mode to manage your listings.',
                    ru: 'Режим гостя нужен для бронирования, а режим хозяина — для управления объявлениями.',
                    uz: 'Mehmon rejimi bron qilish uchun, host rejimi esa e\'lonlarni boshqarish uchun kerak.',
                  ),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                _RoleChoiceCard(
                  icon: Icons.travel_explore_rounded,
                  title: _copy(
                    sheetContext,
                    en: 'Renter mode',
                    ru: 'Режим гостя',
                    uz: 'Mehmon rejimi',
                  ),
                  subtitle: _copy(
                    sheetContext,
                    en: 'Search, save, chat, and request bookings.',
                    ru: 'Ищите жильё, сохраняйте варианты, общайтесь и отправляйте заявки на бронь.',
                    uz: 'Turar joy qidiring, saqlang, yozing va bron so\'rovlari yuboring.',
                  ),
                  selected: currentRole == AppRole.renter,
                  onTap: () => Navigator.of(sheetContext).pop(AppRole.renter),
                ),
                const SizedBox(height: 12),
                _RoleChoiceCard(
                  icon: Icons.home_work_rounded,
                  title: _copy(
                    sheetContext,
                    en: 'Host mode',
                    ru: 'Режим хозяина',
                    uz: 'Host rejimi',
                  ),
                  subtitle: _copy(
                    sheetContext,
                    en: 'Manage listings, chats, availability, and guest requests.',
                    ru: 'Управляйте объявлениями, чатами, календарём и заявками гостей.',
                    uz: 'E\'lonlar, chatlar, mavjudlik va mehmon so\'rovlarini boshqaring.',
                  ),
                  selected: currentRole == AppRole.host,
                  onTap: () => Navigator.of(sheetContext).pop(AppRole.host),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedRole == null || selectedRole == currentRole || !mounted) {
      return;
    }

    ref.read(appSessionControllerProvider.notifier).setRole(selectedRole);
    setState(() => _index = 0);
  }

  Future<void> _signOut() async {
    await ref.read(authControllerProvider.notifier).signOut();
    ref.read(appSessionControllerProvider.notifier).clearRole();
    if (mounted) {
      context.go(RouteNames.auth);
    }
  }

  int? _routeTabToIndex(AppRole role, String? tab) {
    switch (tab) {
      case 'listings':
        return role == AppRole.host ? 1 : null;
      case 'bookings':
        return 2;
      case 'chats':
        return 3;
      case 'profile':
        return 4;
      default:
        return null;
    }
  }
}

class _ExploreTab extends ConsumerWidget {
  const _ExploreTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(_homeExploreListingsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _HeroCard(
          title: _copy(
            context,
            en: 'Find your next stay in Uzbekistan',
            ru: 'Найдите следующее жильё в Узбекистане',
            uz: 'O\'zbekistondagi keyingi turar joyingizni toping',
          ),
          subtitle: _copy(
            context,
            en: 'Short stays only, direct host contact, and fast booking requests.',
            ru: 'Только краткосрочная аренда, прямой контакт с хозяином и быстрые заявки на бронь.',
            uz: 'Faqat qisqa muddatli ijara, host bilan to\'g\'ridan-to\'g\'ri aloqa va tez bron so\'rovlari.',
          ),
          primaryLabel: _copy(
            context,
            en: 'Open search',
            ru: 'Открыть поиск',
            uz: 'Qidiruvni ochish',
          ),
          primaryIcon: Icons.search_rounded,
          onPrimaryTap: () => context.push(RouteNames.search),
          secondaryLabel: _copy(
            context,
            en: 'Open map',
            ru: 'Открыть карту',
            uz: 'Xaritani ochish',
          ),
          secondaryIcon: Icons.map_outlined,
          onSecondaryTap: () => context.push(RouteNames.searchMap),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: _copy(
            context,
            en: 'Recommended stays',
            ru: 'Рекомендуемые варианты',
            uz: 'Tavsiya etilgan joylar',
          ),
          subtitle: _copy(
            context,
            en: 'Clean stable preview from the real backend.',
            ru: 'Стабильная подборка из реального backend.',
            uz: 'Real backenddan barqaror tavsiyalar.',
          ),
          child: listingsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return _InfoBanner(
                  icon: Icons.inbox_outlined,
                  text: _copy(
                    context,
                    en: 'No listings are available yet.',
                    ru: 'Пока нет доступных объявлений.',
                    uz: 'Hozircha e\'lonlar yo\'q.',
                  ),
                );
              }

              return Column(
                children: items
                    .take(4)
                    .map(
                      (listing) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ListingPreviewTile(
                          listing: listing,
                          onTap: () => context.push(
                            RouteNames.listingDetailsById(listing.id),
                          ),
                        ),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const _LoadingBlock(),
            error: (error, _) =>
                _InfoBanner(icon: Icons.error_outline, text: error.toString()),
          ),
        ),
      ],
    );
  }
}

class _FavoritesTab extends ConsumerWidget {
  const _FavoritesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoriteIds = ref.watch(favoritesIdsProvider);
    final favoritesAsync = ref.watch(_homeFavoriteListingsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _SectionHeader(
          title: _copy(
            context,
            en: 'Saved stays',
            ru: 'Сохранённые варианты',
            uz: 'Saqlangan joylar',
          ),
          subtitle: _copy(
            context,
            en: 'Your favorites open directly into the listing details screen.',
            ru: 'Избранные объявления открываются сразу в экран объекта.',
            uz: 'Sevimli e\'lonlar to\'g\'ridan-to\'g\'ri detail ekranga ochiladi.',
          ),
        ),
        const SizedBox(height: 14),
        if (favoriteIds.isEmpty)
          _SectionCard(
            title: _copy(
              context,
              en: 'No favorites yet',
              ru: 'Пока нет избранного',
              uz: 'Hali sevimlilar yo\'q',
            ),
            subtitle: _copy(
              context,
              en: 'Tap the heart on any apartment to save it here.',
              ru: 'Нажмите на сердце в любом объявлении, чтобы сохранить его здесь.',
              uz: 'Istalgan e\'londagi yurakni bosib, uni shu yerga saqlang.',
            ),
            child: FilledButton.icon(
              onPressed: () => context.push(RouteNames.search),
              icon: const Icon(Icons.search_rounded),
              label: Text(
                _copy(
                  context,
                  en: 'Browse listings',
                  ru: 'Смотреть объявления',
                  uz: 'E\'lonlarni ko\'rish',
                ),
              ),
            ),
          )
        else
          _SectionCard(
            title: _copy(
              context,
              en: 'Favorites',
              ru: 'Избранное',
              uz: 'Sevimlilar',
            ),
            subtitle: _copy(
              context,
              en: '${favoriteIds.length} saved listing(s)',
              ru: 'Сохранено объявлений: ${favoriteIds.length}',
              uz: 'Saqlangan e\'lonlar: ${favoriteIds.length}',
            ),
            child: favoritesAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return _InfoBanner(
                    icon: Icons.favorite_outline_rounded,
                    text: _copy(
                      context,
                      en: 'Saved items are no longer available.',
                      ru: 'Сохранённые объекты больше недоступны.',
                      uz: 'Saqlangan obyektlar endi mavjud emas.',
                    ),
                  );
                }

                return Column(
                  children: items
                      .map(
                        (listing) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ListingPreviewTile(
                            listing: listing,
                            highlightFavorite: true,
                            onTap: () => context.push(
                              RouteNames.listingDetailsById(listing.id),
                            ),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
              loading: () => const _LoadingBlock(),
              error: (error, _) => _InfoBanner(
                icon: Icons.error_outline,
                text: error.toString(),
              ),
            ),
          ),
      ],
    );
  }
}

class _BookingsTab extends ConsumerWidget {
  const _BookingsTab({required this.role});

  final AppRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(
      role == AppRole.host ? _hostBookingsProvider : _guestBookingsProvider,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _SectionHeader(
          title: role == AppRole.host
              ? _copy(
                  context,
                  en: 'Booking requests',
                  ru: 'Заявки на бронь',
                  uz: 'Bron so\'rovlari',
                )
              : _copy(
                  context,
                  en: 'My bookings',
                  ru: 'Мои брони',
                  uz: 'Mening bronlarim',
                ),
          subtitle: role == AppRole.host
              ? _copy(
                  context,
                  en: 'See new requests and upcoming guest stays.',
                  ru: 'Смотрите новые заявки и предстоящие заезды гостей.',
                  uz: 'Yangi so\'rovlar va yaqinlashayotgan mehmonlarni ko\'ring.',
                )
              : _copy(
                  context,
                  en: 'Track your requests and upcoming stays.',
                  ru: 'Следите за заявками и предстоящими поездками.',
                  uz: 'So\'rovlar va kelgusi safarlaringizni kuzating.',
                ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: _copy(context, en: 'Bookings', ru: 'Брони', uz: 'Bronlar'),
          subtitle: _copy(
            context,
            en: 'Stable list from the active backend.',
            ru: 'Стабильный список из активного backend.',
            uz: 'Faol backenddan barqaror ro\'yxat.',
          ),
          child: bookingsAsync.when(
            data: (items) {
              if (items.isEmpty) {
                return _InfoBanner(
                  icon: Icons.calendar_month_outlined,
                  text: role == AppRole.host
                      ? _copy(
                          context,
                          en: 'No booking requests yet.',
                          ru: 'Пока нет заявок на бронь.',
                          uz: 'Hozircha bron so\'rovlari yo\'q.',
                        )
                      : _copy(
                          context,
                          en: 'No bookings yet.',
                          ru: 'Пока нет бронирований.',
                          uz: 'Hozircha bronlar yo\'q.',
                        ),
                );
              }

              return Column(
                children: items
                    .map(
                      (booking) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _BookingTile(booking: booking),
                      ),
                    )
                    .toList(growable: false),
              );
            },
            loading: () => const _LoadingBlock(),
            error: (error, _) =>
                _InfoBanner(icon: Icons.error_outline, text: error.toString()),
          ),
        ),
      ],
    );
  }
}

class _HostDashboardTab extends ConsumerWidget {
  const _HostDashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final listingsAsync = ref.watch(hostOwnedListingsProvider);
    final AsyncValue<dynamic>? diagnosticsAsync = null;
    final syncInfo = ref.watch(hostListingsSyncInfoProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _HeroCard(
          title: _copy(
            context,
            en: 'Host dashboard',
            ru: 'Панель хоста',
            uz: 'Host paneli',
          ),
          subtitle: _copy(
            context,
            en: 'Create listings, respond to requests, and keep communication in one place.',
            ru: 'Создавайте объявления, отвечайте на заявки и держите переписку в одном месте.',
            uz: 'E\'lon yarating, so\'rovlarga javob bering va yozishmalarni bir joyda saqlang.',
          ),
          primaryLabel: _copy(
            context,
            en: 'Create listing',
            ru: 'Создать объявление',
            uz: 'E\'lon yaratish',
          ),
          primaryIcon: Icons.add_home_work_outlined,
          onPrimaryTap: () => context.push(RouteNames.createListing),
          secondaryLabel: _copy(
            context,
            en: 'Host requests',
            ru: 'Заявки хоста',
            uz: 'Host so\'rovlari',
          ),
          secondaryIcon: Icons.assignment_turned_in_outlined,
          onSecondaryTap: () => context.push(RouteNames.hostRequests),
        ),
        const SizedBox(height: 18),
        _SectionCard(
          title: _copy(
            context,
            en: 'Current mode',
            ru: 'Текущий режим',
            uz: 'Joriy rejim',
          ),
          subtitle: _copy(
            context,
            en: 'This screen is intentionally simple while Chrome MVP is being stabilized.',
            ru: 'Этот экран намеренно упрощён, пока мы стабилизируем Chrome MVP.',
            uz: 'Chrome MVP barqarorlashayotganda bu ekran ataylab soddalashtirilgan.',
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InfoLine(
                icon: Icons.person_outline_rounded,
                label: _copy(context, en: 'Host', ru: 'Хост', uz: 'Host'),
                value:
                    user?.displayName ??
                    _copy(
                      context,
                      en: 'Signed in',
                      ru: 'Выполнен вход',
                      uz: 'Kirish bajarilgan',
                    ),
              ),
              const SizedBox(height: 12),
              _InfoLine(
                icon: Icons.chat_bubble_outline_rounded,
                label: _copy(context, en: 'Chats', ru: 'Чаты', uz: 'Chatlar'),
                value: _copy(
                  context,
                  en: 'Open the Chats tab to reply to guests.',
                  ru: 'Откройте вкладку «Чаты», чтобы отвечать гостям.',
                  uz: 'Mehmonlarga javob berish uchun Chatlar bo\'limini oching.',
                ),
              ),
            ],
          ),
        ),
        if (diagnosticsAsync != null) ...[
          const SizedBox(height: 18),
          _SectionCard(
            title: _copy(
              context,
              en: 'Debug diagnostics',
              ru: 'Диагностика',
              uz: 'Diagnostika',
            ),
            subtitle: _copy(
              context,
              en: 'Current listings source and backend mode for local debugging.',
              ru: 'Текущий источник объявлений и режим базы для локальной отладки.',
              uz: 'Mahalliy tekshiruv uchun e’lon manbai va backend rejimi.',
            ),
            child: diagnosticsAsync.when(
              loading: () => const _LoadingBlock(),
              error: (error, _) => _InfoBanner(
                icon: Icons.error_outline,
                text: error.toString(),
              ),
              data: (diagnostics) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoLine(
                    icon: Icons.cloud_outlined,
                    label: _copy(
                      context,
                      en: 'Listings source',
                      ru: 'Источник объявлений',
                      uz: 'E’lon manbai',
                    ),
                    value: diagnostics.source,
                  ),
                  const SizedBox(height: 12),
                  _InfoLine(
                    icon: Icons.link_rounded,
                    label: _copy(
                      context,
                      en: 'API base URL',
                      ru: 'Базовый API URL',
                      uz: 'API manzili',
                    ),
                    value: diagnostics.apiBaseUrl,
                  ),
                  const SizedBox(height: 12),
                  _InfoLine(
                    icon: Icons.storage_rounded,
                    label: _copy(
                      context,
                      en: 'Backend storage',
                      ru: 'Хранилище backend',
                      uz: 'Backend saqlash turi',
                    ),
                    value: diagnostics.backendEngine,
                  ),
                  ...[
                    const SizedBox(height: 12),
                    _InfoLine(
                      icon: Icons.sync_problem_rounded,
                      label: _copy(
                        context,
                        en: 'Listings sync',
                        ru: 'Синхронизация объявлений',
                        uz: 'E\'lonlar sinxi',
                      ),
                      value: syncInfo.message == null
                          ? syncInfo.state.name
                          : '${syncInfo.state.name}: ${syncInfo.message}',
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        _SectionCard(
          title: _copy(
            context,
            en: 'My listings',
            ru: 'Мои объявления',
            uz: 'Mening e\'lonlarim',
          ),
          subtitle: _copy(
            context,
            en: 'Newly created stays appear here right away, and you can open or edit them from the dashboard.',
            ru: 'Новые объявления появляются здесь сразу, и их можно открыть или отредактировать прямо с панели.',
            uz: 'Yangi e\'lonlar shu yerda darhol chiqadi va ularni paneldan ochish yoki tahrirlash mumkin.',
          ),
          child: listingsAsync.when(
            loading: () => const _LoadingBlock(),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error.toString(),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(hostOwnedListingsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    _copy(
                      context,
                      en: 'Reload',
                      ru: 'Обновить',
                      uz: 'Qayta yuklash',
                    ),
                  ),
                ),
              ],
            ),
            data: (listings) {
              final showSyncWarning =
                  syncInfo.state == HostListingsSyncState.warning &&
                  (syncInfo.message?.isNotEmpty ?? false);
              if (listings.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showSyncWarning) ...[
                      _InfoBanner(
                        icon: Icons.sync_problem_rounded,
                        text: syncInfo.message!,
                      ),
                      const SizedBox(height: 12),
                    ],
                    Text(
                      _copy(
                        context,
                        en: 'No listings yet. Create your first stay and it will show up here.',
                        ru: 'Пока объявлений нет. Создайте первое жильё, и оно появится здесь.',
                        uz: 'Hozircha e\'lon yo\'q. Birinchi turar joyni yarating, u shu yerda ko\'rinadi.',
                      ),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => context.push(RouteNames.createListing),
                      icon: const Icon(Icons.add_home_work_outlined),
                      label: Text(
                        _copy(
                          context,
                          en: 'Create listing',
                          ru: 'Создать объявление',
                          uz: 'E\'lon yaratish',
                        ),
                      ),
                    ),
                  ],
                );
              }

              final preview = listings.take(2).toList(growable: false);
              return Column(
                children: [
                  if (showSyncWarning) ...[
                    _InfoBanner(
                      icon: Icons.sync_problem_rounded,
                      text: syncInfo.message!,
                    ),
                    const SizedBox(height: 12),
                  ],
                  for (var i = 0; i < preview.length; i++) ...[
                    _HostListingTile(listing: preview[i]),
                    if (i != preview.length - 1) const SizedBox(height: 12),
                  ],
                  if (listings.length > 2) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => context.go(RouteNames.homeListings),
                        icon: const Icon(Icons.grid_view_rounded),
                        label: Text(
                          _copy(
                            context,
                            en: 'Open all listings',
                            ru: 'Открыть все объявления',
                            uz: 'Barcha e\'lonlarni ochish',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HostListingsTab extends ConsumerWidget {
  const _HostListingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listingsAsync = ref.watch(hostOwnedListingsProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        _SectionHeader(
          title: _copy(
            context,
            en: 'Listings',
            ru: 'Объявления',
            uz: 'E\'lonlar',
          ),
          subtitle: _copy(
            context,
            en: 'All of your stays appear here, including drafts that are still invisible to guests.',
            ru: 'Здесь отображаются все ваши варианты жилья, включая черновики, которые пока не видны гостям.',
            uz: 'Bu yerda mehmonlarga hali ko\'rinmaydigan qoralamalar bilan birga barcha e\'lonlaringiz chiqadi.',
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: _copy(
            context,
            en: 'Your listings',
            ru: 'Ваши объявления',
            uz: 'Sizning e\'lonlaringiz',
          ),
          subtitle: _copy(
            context,
            en: 'Open, edit, and track the visibility of each stay.',
            ru: 'Открывайте, редактируйте и следите за статусом видимости каждого варианта жилья.',
            uz: 'Har bir turar joyni oching, tahrirlang va ko\'rinish holatini kuzating.',
          ),
          child: listingsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  error.toString(),
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(hostOwnedListingsProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    _copy(
                      context,
                      en: 'Reload',
                      ru: 'Обновить',
                      uz: 'Qayta yuklash',
                    ),
                  ),
                ),
              ],
            ),
            data: (listings) {
              if (listings.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _copy(
                        context,
                        en: 'You have not created any stays yet.',
                        ru: 'Вы пока не создали ни одного варианта жилья.',
                        uz: 'Siz hali birorta turar joy yaratmagansiz.',
                      ),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => context.push(RouteNames.createListing),
                      icon: const Icon(Icons.add_home_work_outlined),
                      label: Text(
                        _copy(
                          context,
                          en: 'Create listing',
                          ru: 'Создать объявление',
                          uz: 'E\'lon yaratish',
                        ),
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  for (var i = 0; i < listings.length; i++) ...[
                    _HostListingTile(listing: listings[i]),
                    if (i != listings.length - 1) const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        _ActionTile(
          icon: Icons.add_home_work_outlined,
          title: _copy(
            context,
            en: 'Create a new listing',
            ru: 'Создать новое объявление',
            uz: 'Yangi e\'lon yaratish',
          ),
          subtitle: _copy(
            context,
            en: 'Start the multi-step listing flow.',
            ru: 'Запустить пошаговый сценарий создания объявления.',
            uz: 'Bosqichma-bosqich e\'lon yaratish jarayonini boshlash.',
          ),
          onTap: () => context.push(RouteNames.createListing),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.assignment_turned_in_outlined,
          title: _copy(
            context,
            en: 'Open booking requests',
            ru: 'Открыть заявки на бронь',
            uz: 'Bron so\'rovlarini ochish',
          ),
          subtitle: _copy(
            context,
            en: 'Review and respond to incoming requests.',
            ru: 'Смотрите входящие заявки и отвечайте на них.',
            uz: 'Kiruvchi so\'rovlarni ko\'rib chiqing va javob bering.',
          ),
          onTap: () => context.push(RouteNames.hostRequests),
        ),
      ],
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab({required this.onSignOut, required this.onSwitchRole});

  final Future<void> Function() onSignOut;
  final Future<void> Function() onSwitchRole;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final role = ref.watch(appSessionControllerProvider).activeRole;
    final favoriteCount = ref.watch(favoritesIdsProvider).length;

    final displayName = user?.displayName.trim().isNotEmpty == true
        ? user!.displayName
        : _copy(
            context,
            en: 'Guest account',
            ru: 'Аккаунт гостя',
            uz: 'Mehmon akkaunti',
          );
    final email = user?.email.trim().isNotEmpty == true
        ? user!.email
        : _copy(context, en: 'No email', ru: 'Нет email', uz: 'Email yo\'q');
    final phone = user?.phone?.trim().isNotEmpty == true
        ? user!.phone!
        : _copy(
            context,
            en: 'Phone not added',
            ru: 'Телефон не добавлен',
            uz: 'Telefon qo\'shilmagan',
          );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primaryDeep, AppColors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(
                  Icons.person_outline_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      email,
                      style: const TextStyle(
                        color: Color(0xE6FFFFFF),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      phone,
                      style: const TextStyle(
                        color: Color(0xCCFFFFFF),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.favorite_outline_rounded,
                value: '$favoriteCount',
                label: _copy(
                  context,
                  en: 'Saved',
                  ru: 'Сохранено',
                  uz: 'Saqlangan',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.swap_horiz_rounded,
                value: role == AppRole.host
                    ? _copy(context, en: 'Host', ru: 'Хост', uz: 'Host')
                    : _copy(context, en: 'Guest', ru: 'Гость', uz: 'Mehmon'),
                label: _copy(context, en: 'Mode', ru: 'Режим', uz: 'Rejim'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.workspace_premium_outlined,
                value: user?.isPremium == true ? 'ON' : 'OFF',
                label: _copy(
                  context,
                  en: 'Premium',
                  ru: 'Премиум',
                  uz: 'Premium',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ActionTile(
          icon: Icons.edit_outlined,
          title: _copy(
            context,
            en: 'Edit profile',
            ru: 'Редактировать профиль',
            uz: 'Profilni tahrirlash',
          ),
          subtitle: _copy(
            context,
            en: 'Update your name and phone number.',
            ru: 'Обновите имя и номер телефона.',
            uz: 'Ism va telefon raqamingizni yangilang.',
          ),
          onTap: () => _showEditProfileSheet(context, ref, user),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.settings_outlined,
          title: _copy(
            context,
            en: 'Settings',
            ru: 'Настройки',
            uz: 'Sozlamalar',
          ),
          subtitle: _copy(
            context,
            en: 'Language, privacy, and app preferences.',
            ru: 'Язык, приватность и настройки приложения.',
            uz: 'Til, maxfiylik va ilova sozlamalari.',
          ),
          onTap: () => context.push(RouteNames.settings),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.workspace_premium_outlined,
          title: _copy(context, en: 'Premium', ru: 'Премиум', uz: 'Premium'),
          subtitle: _copy(
            context,
            en: 'Manage Free Stay access and premium benefits.',
            ru: 'Управляйте доступом к Free Stay и премиум-возможностями.',
            uz: 'Free Stay kirishi va premium imkoniyatlarini boshqaring.',
          ),
          onTap: () => context.push(RouteNames.premiumPaywall),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.notifications_none_rounded,
          title: _copy(
            context,
            en: 'Notifications',
            ru: 'Уведомления',
            uz: 'Bildirishnomalar',
          ),
          subtitle: _copy(
            context,
            en: 'Booking updates and important activity.',
            ru: 'Обновления по броням и важная активность.',
            uz: 'Bron yangilanishlari va muhim faollik.',
          ),
          onTap: () => context.push(RouteNames.notifications),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.support_agent_outlined,
          title: _copy(context, en: 'Support', ru: 'Поддержка', uz: 'Yordam'),
          subtitle: _copy(
            context,
            en: 'Help center and contact options.',
            ru: 'Центр помощи и способы связи.',
            uz: 'Yordam markazi va aloqa variantlari.',
          ),
          onTap: () => context.push(RouteNames.support),
        ),
        const SizedBox(height: 12),
        _ActionTile(
          icon: Icons.swap_horiz_rounded,
          title: _copy(
            context,
            en: 'Switch role',
            ru: 'Сменить роль',
            uz: 'Rolni almashtirish',
          ),
          subtitle: _copy(
            context,
            en: 'Switch between renter and host mode.',
            ru: 'Переключитесь между режимом гостя и хоста.',
            uz: 'Mehmon va host rejimi o\'rtasida almashing.',
          ),
          onTap: onSwitchRole,
        ),
        const SizedBox(height: 16),
        Material(
          color: const Color(0xFFFFF1F1),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onSignOut,
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFF1B0B0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE0E0),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Color(0xFFC53030),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _copy(
                            context,
                            en: 'Sign out',
                            ru: 'Выйти из аккаунта',
                            uz: 'Akkauntdan chiqish',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF9B1C1C),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _copy(
                            context,
                            en: 'Leave this account on this device.',
                            ru: 'Выйти из этого аккаунта на этом устройстве.',
                            uz: 'Ushbu qurilmadagi akkauntdan chiqish.',
                          ),
                          style: const TextStyle(
                            color: Color(0xFFB45353),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showEditProfileSheet(
    BuildContext context,
    WidgetRef ref,
    AuthUser? user,
  ) async {
    final firstNameController = TextEditingController(
      text: user?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: user?.lastName ?? '',
    );
    final phoneController = TextEditingController(text: user?.phone ?? '');

    final shouldSave = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _copy(
                sheetContext,
                en: 'Edit profile',
                ru: 'Редактировать профиль',
                uz: 'Profilni tahrirlash',
              ),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: firstNameController,
              decoration: InputDecoration(
                labelText: _copy(
                  sheetContext,
                  en: 'First name',
                  ru: 'Имя',
                  uz: 'Ism',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lastNameController,
              decoration: InputDecoration(
                labelText: _copy(
                  sheetContext,
                  en: 'Last name',
                  ru: 'Фамилия',
                  uz: 'Familiya',
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: _copy(
                  sheetContext,
                  en: 'Phone',
                  ru: 'Телефон',
                  uz: 'Telefon',
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(sheetContext).pop(false),
                    child: Text(
                      MaterialLocalizations.of(sheetContext).cancelButtonLabel,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(true),
                    child: Text(
                      _copy(
                        sheetContext,
                        en: 'Save',
                        ru: 'Сохранить',
                        uz: 'Saqlash',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (shouldSave == true) {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            firstName: firstNameController.text.trim(),
            lastName: lastNameController.text.trim(),
            phoneNumber: phoneController.text.trim(),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _copy(
                context,
                en: 'Profile updated',
                ru: 'Профиль обновлён',
                uz: 'Profil yangilandi',
              ),
            ),
          ),
        );
      }
    }

    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.primaryLabel,
    required this.primaryIcon,
    required this.onPrimaryTap,
    required this.secondaryLabel,
    required this.secondaryIcon,
    required this.onSecondaryTap,
  });

  final String title;
  final String subtitle;
  final String primaryLabel;
  final IconData primaryIcon;
  final VoidCallback onPrimaryTap;
  final String secondaryLabel;
  final IconData secondaryIcon;
  final VoidCallback onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDeep, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xE6FFFFFF), height: 1.45),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onPrimaryTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDeep,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(primaryIcon),
                  label: Text(primaryLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onSecondaryTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0x66FFFFFF)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: Icon(secondaryIcon),
                  label: Text(secondaryLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: AppColors.textMuted, height: 1.45),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
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
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ListingPreviewTile extends ConsumerWidget {
  const _ListingPreviewTile({
    required this.listing,
    required this.onTap,
    this.highlightFavorite = false,
  });

  final Listing listing;
  final VoidCallback onTap;
  final bool highlightFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(
      favoritesIdsProvider.select((items) => items.contains(listing.id)),
    );

    return Material(
      color: AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 92,
                  height: 92,
                  child: _ListingImagePreview(
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
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _listingLocation(listing),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          _listingPriceLabel(context, listing),
                          style: const TextStyle(
                            color: Color(0xFF6A480A),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => ref
                              .read(favoritesIdsProvider.notifier)
                              .toggle(listing.id),
                          icon: Icon(
                            isFavorite || highlightFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite || highlightFavorite
                                ? const Color(0xFFD64545)
                                : AppColors.iconMuted,
                          ),
                        ),
                      ],
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

class _HostListingTile extends StatelessWidget {
  const _HostListingTile({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final isDraft = !listing.isActive;
    final hasUsableRoute = _hasUsableListingRoute(listing);
    final title = listing.title.trim().isEmpty
        ? _copy(
            context,
            en: 'Listing is syncing',
            ru: 'Объявление синхронизируется',
            uz: 'E\'lon sinxronlanmoqda',
          )
        : listing.title;
    final location = _listingLocation(listing).trim().isEmpty
        ? _copy(
            context,
            en: 'Location is syncing',
            ru: 'Локация синхронизируется',
            uz: 'Manzil sinxronlanmoqda',
          )
        : _listingLocation(listing);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: _ListingImagePreview(
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
                      title,
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
                      location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HostListingStatusChip(
                          label: isDraft
                              ? _copy(
                                  context,
                                  en: 'Draft',
                                  ru: 'Черновик',
                                  uz: 'Qoralama',
                                )
                              : _copy(
                                  context,
                                  en: 'Visible to guests',
                                  ru: 'Видно гостям',
                                  uz: 'Mehmonlarga ko\'rinadi',
                                ),
                          active: !isDraft,
                        ),
                        _HostListingStatusChip(
                          label: _listingPriceLabel(context, listing),
                          active: true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            !hasUsableRoute
                ? _copy(
                    context,
                    en: 'This listing was saved, but its full details are still syncing. Refresh in a moment or open Edit later.',
                    ru: 'Объявление сохранено, но его полные данные ещё синхронизируются. Обновите экран чуть позже или откройте редактирование позже.',
                    uz: 'E\'lon saqlandi, lekin uning to\'liq ma\'lumotlari hali sinxronlanmoqda. Birozdan so\'ng yangilang yoki keyinroq tahrirlashni oching.',
                  )
                : isDraft
                ? _copy(
                    context,
                    en: 'This listing is saved as a draft and is not visible in public search yet.',
                    ru: 'Это объявление сохранено как черновик и пока не видно в публичном поиске.',
                    uz: 'Bu e\'lon qoralama sifatida saqlangan va hozircha ommaviy qidiruvda ko\'rinmaydi.',
                  )
                : _copy(
                    context,
                    en: 'This listing is already visible in your host inventory.',
                    ru: 'Это объявление уже отображается в вашем списке хозяина.',
                    uz: 'Bu e\'lon host ro\'yxatingizda allaqachon ko\'rinadi.',
                  ),
            style: const TextStyle(color: AppColors.textMuted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: hasUsableRoute
                      ? () =>
                          context.push(RouteNames.listingDetailsById(listing.id))
                      : null,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text(
                    _copy(context, en: 'Open', ru: 'Открыть', uz: 'Ochish'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: hasUsableRoute
                      ? () => context.push(RouteNames.editListingById(listing.id))
                      : null,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(
                    _copy(
                      context,
                      en: 'Edit',
                      ru: 'Изменить',
                      uz: 'Tahrirlash',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HostListingStatusChip extends StatelessWidget {
  const _HostListingStatusChip({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primarySoft : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: active ? AppColors.primarySoftStrong : AppColors.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? AppColors.primaryDeep : AppColors.textSoft,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _ListingImagePreview extends StatelessWidget {
  const _ListingImagePreview({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        color: const Color(0xFFE8EDF5),
        alignment: Alignment.center,
        child: const Icon(Icons.image_outlined, color: Color(0xFF7A8397)),
      );
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
      loadingBuilder: (context, child, progress) {
        return progress == null ? child : _fallback(showLoader: true);
      },
    );
  }

  Widget _fallback({bool showLoader = false}) {
    return Container(
      color: const Color(0xFFE8EDF5),
      alignment: Alignment.center,
      child: showLoader
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.image_outlined, color: Color(0xFF7A8397)),
    );
  }
}

class _BookingTile extends StatelessWidget {
  const _BookingTile({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${booking.checkInDate.day.toString().padLeft(2, '0')}.${booking.checkInDate.month.toString().padLeft(2, '0')} - ${booking.checkOutDate.day.toString().padLeft(2, '0')}.${booking.checkOutDate.month.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_copy(context, en: 'Guests', ru: 'Гости', uz: 'Mehmonlar')}: ${booking.guestsCount}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _bookingStatusLabel(context, booking.status),
              style: const TextStyle(
                color: AppColors.primaryDeep,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 12),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.35,
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

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textMuted, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
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
        Icon(icon, size: 18, color: const Color(0xFF6D7280)),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Color(0xFF425166), height: 1.4),
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
}

class _LoadingBlock extends StatelessWidget {
  const _LoadingBlock();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

String _bookingStatusLabel(BuildContext context, BookingStatus status) {
  switch (status) {
    case BookingStatus.pendingHostApproval:
      return _copy(context, en: 'Pending', ru: 'Ожидает', uz: 'Kutilmoqda');
    case BookingStatus.confirmed:
      return _copy(
        context,
        en: 'Confirmed',
        ru: 'Подтверждено',
        uz: 'Tasdiqlandi',
      );
    case BookingStatus.cancelledByGuest:
    case BookingStatus.cancelledByHost:
      return _copy(
        context,
        en: 'Cancelled',
        ru: 'Отменено',
        uz: 'Bekor qilingan',
      );
    case BookingStatus.completed:
      return _copy(
        context,
        en: 'Completed',
        ru: 'Завершено',
        uz: 'Yakunlangan',
      );
  }
}

String _listingLocation(Listing listing) {
  final parts = <String>[
    listing.city.trim(),
    if (listing.district.trim().isNotEmpty) listing.district.trim(),
  ];
  return parts.where((part) => part.isNotEmpty).join(', ');
}

bool _hasUsableListingRoute(Listing listing) {
  return listing.id.trim().isNotEmpty &&
      listing.title.trim().isNotEmpty &&
      listing.city.trim().isNotEmpty &&
      listing.district.trim().isNotEmpty;
}

String _copy(
  BuildContext context, {
  required String en,
  required String ru,
  required String uz,
}) {
  switch (Localizations.localeOf(context).languageCode) {
    case 'ru':
      return resolveRussianCopy(en, ru);
    case 'uz':
      return uz;
    default:
      return en;
  }
}

String _listingPriceLabel(BuildContext context, Listing listing) {
  if (listing.type == ListingType.freeStay) {
    return _copy(
      context,
      en: 'Free stay',
      ru: 'Бесплатное проживание',
      uz: 'Bepul',
    );
  }
  if (listing.nightlyPriceUzs == null) {
    return _copy(
      context,
      en: 'Price on request',
      ru: 'Цена по запросу',
      uz: 'Narx so\'rov bo\'yicha',
    );
  }
  return '${listing.nightlyPriceUzs} UZS';
}

class _RoleChoiceCard extends StatelessWidget {
  const _RoleChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primarySoft : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : AppColors.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? AppColors.primary : AppColors.iconMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
