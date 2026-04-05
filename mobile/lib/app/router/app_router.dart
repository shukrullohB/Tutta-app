import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_colors.dart';
import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/application/auth_state.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/verify_otp_screen.dart';
import '../../features/bookings/presentation/screens/booking_payment_screen.dart';
import '../../features/bookings/presentation/screens/booking_request_screen.dart';
import '../../features/bookings/presentation/screens/host_requests_screen.dart';
import '../../features/bookings/presentation/screens/my_bookings_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/home/application/app_session_controller.dart';
import '../../features/home/presentation/screens/home_shell_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import 'listing_details_route_screen.dart';
import '../../features/listings/presentation/screens/search_screen.dart';
import '../../features/listings/presentation/screens/create_listing_screen.dart';
import '../../features/listings/presentation/screens/edit_listing_screen.dart';
import '../../features/listings/presentation/screens/listing_availability_screen.dart';
import '../../features/listings/presentation/screens/search_map_screen.dart';
import '../../features/premium/presentation/screens/premium_paywall_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/support_screen.dart';
import '../../features/profile/presentation/screens/notification_preferences_screen.dart';
import '../../features/reviews/presentation/screens/review_submit_screen.dart';
import '../../features/role/presentation/screens/role_selector_screen.dart';
import '../../features/wishlist/presentation/screens/favorites_screen.dart';
import '../../core/network/auth_token_provider.dart';
import 'route_names.dart';

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) {
  final notifier = _RouterRefreshNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(this._ref) {
    _authSub = _ref.listen<AsyncValue<AuthState>>(
      authControllerProvider,
      (_, _) => notifyListeners(),
    );
    _tokenSub = _ref.listen<String?>(
      authTokenProvider,
      (_, _) => notifyListeners(),
    );
    _sessionSub = _ref.listen<AppSessionState>(
      appSessionControllerProvider,
      (_, _) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<AuthState>> _authSub;
  late final ProviderSubscription<String?> _tokenSub;
  late final ProviderSubscription<AppSessionState> _sessionSub;

  @override
  void dispose() {
    _authSub.close();
    _tokenSub.close();
    _sessionSub.close();
    super.dispose();
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshListenable = ref.watch(_routerRefreshProvider);

  final router = GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final authAsync = ref.read(authControllerProvider);
      final authState = authAsync.valueOrNull;
      final authToken = ref.read(authTokenProvider);
      final session = ref.read(appSessionControllerProvider);

      final hasToken = authToken != null && authToken.isNotEmpty;
      final isLoggedIn = (authState?.isAuthenticated ?? false) || hasToken;
      final authHydrated = (authState?.hydrated ?? false) || hasToken;
      final location = state.matchedLocation;
      final bootstrapping = !authHydrated || !session.hydrated;
      final onboardingCompleted = session.onboardingCompleted;
      final roleSelected = session.activeRole != null;

      if (location == RouteNames.splash) {
        return null;
      }

      // Do not force users back to splash while state hydration is pending.
      // Splash screen itself already handles waiting + fallback navigation.
      if (bootstrapping) {
        return null;
      }

      if (!onboardingCompleted &&
          location != RouteNames.onboarding &&
          location != RouteNames.splash) {
        print(
          '[AUTH_TRACE] redirect -> onboarding (location=$location, loggedIn=$isLoggedIn, hydrated=$authHydrated)',
        );
        return RouteNames.onboarding;
      }

      if (onboardingCompleted &&
          !isLoggedIn &&
          location != RouteNames.auth &&
          location != RouteNames.authVerify &&
          location != RouteNames.splash) {
        print(
          '[AUTH_TRACE] redirect -> auth (location=$location, loggedIn=$isLoggedIn, hydrated=$authHydrated)',
        );
        return RouteNames.auth;
      }

      if (isLoggedIn &&
          !roleSelected &&
          onboardingCompleted &&
          location != RouteNames.roleSelector &&
          location != RouteNames.splash) {
        print(
          '[AUTH_TRACE] redirect -> roleSelector (location=$location, loggedIn=$isLoggedIn, roleSelected=$roleSelected)',
        );
        return RouteNames.roleSelector;
      }

      if (isLoggedIn && roleSelected) {
        if (location == RouteNames.auth ||
            location == RouteNames.authVerify ||
            location == RouteNames.onboarding) {
          print(
            '[AUTH_TRACE] redirect -> home (location=$location, loggedIn=$isLoggedIn, roleSelected=$roleSelected)',
          );
          return RouteNames.home;
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const _SplashRedirectScreen(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: RouteNames.auth,
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: RouteNames.authVerify,
        builder: (context, state) => const VerifyOtpScreen(),
      ),
      GoRoute(
        path: RouteNames.roleSelector,
        builder: (context, state) => const RoleSelectorScreen(),
      ),
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => HomeShellScreen(
          key: ValueKey('home:${state.uri.toString()}'),
          initialTab: state.uri.queryParameters['tab'],
        ),
      ),
      GoRoute(
        path: RouteNames.homeListings,
        builder: (context, state) => const HomeShellScreen(
          key: ValueKey('home:listings'),
          initialTab: 'listings',
        ),
      ),
      GoRoute(
        path: RouteNames.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: RouteNames.searchMap,
        builder: (context, state) => const SearchMapScreen(),
      ),
      GoRoute(
        path: RouteNames.createListing,
        builder: (context, state) => const CreateListingScreen(),
      ),
      GoRoute(
        path: '${RouteNames.editListing}/:id',
        builder: (context, state) {
          final listingId = state.pathParameters['id'] ?? '';
          return EditListingScreen(listingId: listingId);
        },
      ),
      GoRoute(
        path: '${RouteNames.listingAvailability}/:id',
        builder: (context, state) {
          final listingId = state.pathParameters['id'] ?? '';
          return ListingAvailabilityScreen(listingId: listingId);
        },
      ),
      GoRoute(
        path: '${RouteNames.listingDetails}/:id',
        builder: (context, state) {
          final listingId = state.pathParameters['id'] ?? '';
          return ListingDetailsScreen(listingId: listingId);
        },
      ),
      GoRoute(
        path: '${RouteNames.bookingRequest}/:id',
        builder: (context, state) {
          final listingId = state.pathParameters['id'] ?? '';
          return BookingRequestScreen(listingId: listingId);
        },
      ),
      GoRoute(
        path: '${RouteNames.bookingPayment}/:id',
        builder: (context, state) {
          final bookingId = state.pathParameters['id'] ?? '';
          return BookingPaymentScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: '${RouteNames.reviewSubmit}/:id',
        builder: (context, state) {
          final bookingId = state.pathParameters['id'] ?? '';
          return ReviewSubmitScreen(bookingId: bookingId);
        },
      ),
      GoRoute(
        path: RouteNames.favorites,
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: RouteNames.bookings,
        builder: (context, state) => const MyBookingsScreen(),
      ),
      GoRoute(
        path: RouteNames.hostRequests,
        builder: (context, state) => const HostRequestsScreen(),
      ),
      GoRoute(
        path: RouteNames.chatList,
        builder: (context, state) => ChatListScreen(
          initialListingId: state.uri.queryParameters['listingId'],
          initialHostId: state.uri.queryParameters['hostId'],
        ),
      ),
      GoRoute(
        path: RouteNames.premiumPaywall,
        builder: (context, state) => const PremiumPaywallScreen(),
      ),
      GoRoute(
        path: RouteNames.notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.notificationPreferences,
        builder: (context, state) => const NotificationPreferencesScreen(),
      ),
      GoRoute(
        path: RouteNames.support,
        builder: (context, state) => const SupportScreen(),
      ),
    ],
  );

  ref.onDispose(router.dispose);
  return router;
});

class _SplashRedirectScreen extends StatelessWidget {
  const _SplashRedirectScreen();

  @override
  Widget build(BuildContext context) {
    return const _BrandSplashScreen();
  }
}

class _BrandSplashScreen extends ConsumerStatefulWidget {
  const _BrandSplashScreen();

  @override
  ConsumerState<_BrandSplashScreen> createState() => _BrandSplashScreenState();
}

class _BrandSplashScreenState extends ConsumerState<_BrandSplashScreen> {
  int _guardTicks = 0;
  bool _animateIn = false;
  Timer? _pendingContinue;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _animateIn = true);
      }
    });
    final session = ref.read(appSessionControllerProvider);
    if (session.splashSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _scheduleContinue(const Duration(milliseconds: 1));
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(appSessionControllerProvider.notifier).markSplashSeen();
      _scheduleContinue(const Duration(milliseconds: 1400));
    });
  }

  @override
  void dispose() {
    _pendingContinue?.cancel();
    super.dispose();
  }

  void _scheduleContinue(Duration delay) {
    _pendingContinue?.cancel();
    _pendingContinue = Timer(delay, _continueFlow);
  }

  void _continueFlow() {
    if (!mounted) {
      return;
    }
    final authSnapshot = ref.read(authControllerProvider);
    final authState = authSnapshot.valueOrNull;
    final authToken = ref.read(authTokenProvider);
    final hasToken = authToken != null && authToken.isNotEmpty;
    final session = ref.read(appSessionControllerProvider);
    final authPending = authSnapshot.isLoading || (authSnapshot.hasValue && !(authState?.hydrated ?? false));
    if (authPending || !session.hydrated) {
      _guardTicks += 1;
      if (_guardTicks > 90) {
        // Failsafe: do not keep users forever on splash.
        context.go(RouteNames.auth);
        return;
      }
      _scheduleContinue(const Duration(milliseconds: 60));
      return;
    }
    _guardTicks = 0;
    final isLoggedIn = (authState?.isAuthenticated ?? false) || hasToken;

    if (!session.onboardingCompleted) {
      context.go(RouteNames.onboarding);
      return;
    }
    if (!isLoggedIn) {
      context.go(RouteNames.auth);
      return;
    }
    if (session.activeRole == null) {
      context.go(RouteNames.roleSelector);
      return;
    }
    context.go(RouteNames.home);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: AnimatedScale(
                    scale: _animateIn ? 1 : 0.92,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: _animateIn ? 1 : 0,
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOut,
                      child: Container(
                        width: 320,
                        height: 320,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [Color(0x30F15A24), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSlide(
                    offset: _animateIn ? Offset.zero : const Offset(0, 0.08),
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      opacity: _animateIn ? 1 : 0,
                      duration: const Duration(milliseconds: 420),
                      child: Text(
                        'Tutta',
                        style: const TextStyle(
                          color: AppColors.primaryDeep,
                          fontSize: 68,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DIGITAL CONCIERGE',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 18,
                      letterSpacing: 5.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 240),
                  Text(
                    'PREPARING YOUR STAY',
                    style: const TextStyle(
                      color: AppColors.textSoft,
                      fontSize: 15,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
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
