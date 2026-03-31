import 'package:flutter/material.dart';
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
      body: tabs[_index],
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
        _HomeTab(
          title: 'My Listings',
          subtitle: 'Create and update your listings.',
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
      _HomeTab(
        title: 'Discover Uzbekistan',
        subtitle: 'Find short-term stays up to 30 days.',
      ),
      _HomeTab(
        title: 'Favorites',
        subtitle: 'Saved listings and host profiles.',
      ),
      _HomeTab(
        title: 'Bookings',
        subtitle: 'Active, upcoming, and completed stays.',
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

class _HomeTab extends StatelessWidget {
  const _HomeTab({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(subtitle),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 8,
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
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Text(subtitle),
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
      ),
    );
  }
}
