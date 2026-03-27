import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/enums/app_role.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../auth/application/auth_controller.dart';
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
      return const Scaffold(
        body: EmptyStateView(
          title: 'Role is not selected',
          subtitle: 'Please choose renter or host mode.',
        ),
      );
    }

    final tabs = _tabsForRole(role);
    final destinations = _destinationsForRole(role);

    if (_index >= tabs.length) {
      _index = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(role == AppRole.renter ? 'Tutta Renter' : 'Tutta Host'),
        actions: [
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
              if (context.mounted) {
                context.go(RouteNames.auth);
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

  List<Widget> _tabsForRole(AppRole role) {
    if (role == AppRole.host) {
      return const [
        _HomeTab(
          title: 'Host Dashboard',
          subtitle: 'Manage listings, requests, and occupancy.',
        ),
        _HostListingsTab(
          title: 'My Listings',
          subtitle: 'Create and update your listings in one place.',
        ),
        _HostRequestsEntryTab(
          title: 'Requests',
          subtitle: 'Approve or decline booking requests in one place.',
        ),
        _HomeTab(title: 'Chat', subtitle: 'Talk to your guests in real time.'),
        _HomeTab(title: 'Profile', subtitle: 'Host profile and settings.'),
      ];
    }

    return const [
      _RenterHomeTab(),
      _HomeTab(
        title: 'Favorites',
        subtitle: 'Saved listings and host profiles.',
      ),
      _BookingsEntryTab(
        title: 'Bookings',
        subtitle: 'Track requests and upcoming stays in Uzbekistan.',
      ),
      _HomeTab(title: 'Chat', subtitle: 'Talk to hosts before booking.'),
      _HomeTab(
        title: 'Profile',
        subtitle: 'Account, premium, and preferences.',
      ),
    ];
  }

  List<NavigationDestination> _destinationsForRole(AppRole role) {
    if (role == AppRole.host) {
      return const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(Icons.home_work_outlined),
          label: 'Listings',
        ),
        NavigationDestination(
          icon: Icon(Icons.assignment_turned_in_outlined),
          label: 'Requests',
        ),
        NavigationDestination(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chat',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ];
    }

    return const [
      NavigationDestination(icon: Icon(Icons.travel_explore), label: 'Explore'),
      NavigationDestination(
        icon: Icon(Icons.favorite_border),
        label: 'Favorites',
      ),
      NavigationDestination(
        icon: Icon(Icons.calendar_month_outlined),
        label: 'Bookings',
      ),
      NavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Chat',
      ),
      NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
    ];
  }
}

class _RenterHomeTab extends StatelessWidget {
  const _RenterHomeTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
        children: [
          Row(
            children: const [
              Icon(Icons.menu, color: Color(0xFF072A73)),
              SizedBox(width: 12),
              Text(
                'Tutta',
                style: TextStyle(
                  color: Color(0xFF072A73),
                  fontSize: 34 / 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              CircleAvatar(
                radius: 16,
                backgroundColor: Color(0xFFF3CDAD),
                child: Icon(Icons.person, size: 16, color: Color(0xFFB78664)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
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
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _HomePill(icon: Icons.place_outlined, label: 'Anywhere'),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _HomePill(
                  icon: Icons.calendar_month_outlined,
                  label: 'Any week',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            children: [
              _SegmentTile(
                label: 'HOMES',
                icon: Icons.home,
                active: true,
                width: 112,
              ),
              SizedBox(width: 10),
              _SegmentTile(
                label: 'ROOMS',
                icon: Icons.bed_outlined,
                width: 112,
              ),
              SizedBox(width: 10),
              _SegmentTile(
                label: 'SKILL\nEXCHANGE',
                icon: Icons.swap_horiz,
                width: 120,
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
            children: const [
              Text(
                'Featured Stays',
                style: TextStyle(
                  color: Color(0xFF072A73),
                  fontWeight: FontWeight.w700,
                  fontSize: 44 / 2,
                ),
              ),
              Spacer(),
              Text(
                'View all',
                style: TextStyle(
                  color: Color(0xFF072A73),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 16, color: Color(0xFF072A73)),
            ],
          ),
          const SizedBox(height: 12),
          const _FeaturedStayCard(),
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
            title: 'Samarkand Courtyard Flat',
            subtitle: 'Samarkand • 3 nights',
            price: '850 000 UZS / night',
            rating: '4.95',
            imageAssetPath: 'assets/images/home2.png',
            color: Color(0xFF5B8F86),
          ),
          const SizedBox(height: 10),
          const _NearbyCard(
            title: 'Bukhara Old City Studio',
            subtitle: 'Bukhara • 2 nights',
            price: '620 000 UZS / night',
            rating: '4.78',
            imageAssetPath: 'assets/images/home4.png',
            color: Color(0xFFA9957B),
          ),
          const SizedBox(height: 10),
          const _NearbyCard(
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
  const _HomePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _SegmentTile extends StatelessWidget {
  const _SegmentTile({
    required this.label,
    required this.icon,
    required this.width,
    this.active = false,
  });

  final String label;
  final IconData icon;
  final double width;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

class _FeaturedStayCard extends StatelessWidget {
  const _FeaturedStayCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
                child: Image.asset(
                  'assets/images/home1.png',
                  fit: BoxFit.cover,
                ),
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
                  child: const Text(
                    '1 350 000 UZS / night',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Positioned(
                right: 12,
                top: 12,
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0x88FFFFFF),
                  child: Icon(Icons.favorite_border, color: Colors.white),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Row(
              children: const [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amirsoy Mountain Chalet',
                        style: TextStyle(
                          color: Color(0xFF071E57),
                          fontSize: 34 / 2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Tashkent Region, Uzbekistan',
                        style: TextStyle(color: Color(0xFF4E5568)),
                      ),
                    ],
                  ),
                ),
                _RatingBadge(value: '4.92'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyCard extends StatelessWidget {
  const _NearbyCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.rating,
    required this.color,
    this.imageAssetPath,
  });

  final String title;
  final String subtitle;
  final String price;
  final String rating;
  final Color color;
  final String? imageAssetPath;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                    const Icon(Icons.favorite, color: Color(0xFF808697)),
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

class _BookingsEntryTab extends StatelessWidget {
  const _BookingsEntryTab({required this.title, required this.subtitle});

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
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2E44),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tutta booking rules',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Uzbekistan only. Short-term rental only. Maximum stay is 30 days.',
                        style: TextStyle(color: Color(0xFFD2D7E5)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go(RouteNames.bookings),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: const Text('Open my bookings'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(RouteNames.search),
                      icon: const Icon(Icons.search),
                      label: const Text('Find stays in Uzbekistan'),
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
