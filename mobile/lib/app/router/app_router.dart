import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
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
import '../../features/listings/presentation/screens/listing_details_screen.dart';
import '../../features/listings/presentation/screens/search_screen.dart';
import '../../features/listings/presentation/screens/create_listing_screen.dart';
import '../../features/listings/presentation/screens/edit_listing_screen.dart';
import '../../features/listings/presentation/screens/listing_availability_screen.dart';
import '../../features/premium/presentation/screens/premium_paywall_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/support_screen.dart';
import '../../features/reviews/presentation/screens/review_submit_screen.dart';
import '../../features/role/presentation/screens/role_selector_screen.dart';
import '../../features/wishlist/presentation/screens/favorites_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final isLoggedIn = ref.watch(
    authControllerProvider.select(
      (state) => state.valueOrNull?.isAuthenticated ?? false,
    ),
  );
  final session = ref.watch(appSessionControllerProvider);

  return GoRouter(
    initialLocation: RouteNames.splash,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final onboardingCompleted = session.onboardingCompleted;
      final roleSelected = session.activeRole != null;

      if (location == RouteNames.splash) {
        return null;
      }

      if (!onboardingCompleted &&
          location != RouteNames.onboarding &&
          location != RouteNames.splash) {
        return RouteNames.onboarding;
      }

      if (onboardingCompleted &&
          !isLoggedIn &&
          location != RouteNames.auth &&
          location != RouteNames.authVerify &&
          location != RouteNames.splash) {
        return RouteNames.auth;
      }

      if (isLoggedIn &&
          !roleSelected &&
          onboardingCompleted &&
          location != RouteNames.roleSelector &&
          location != RouteNames.splash) {
        return RouteNames.roleSelector;
      }

      if (isLoggedIn && roleSelected) {
        if (location == RouteNames.auth ||
            location == RouteNames.authVerify ||
            location == RouteNames.onboarding) {
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
        builder: (context, state) => const HomeShellScreen(),
      ),
      GoRoute(
        path: RouteNames.search,
        builder: (context, state) => const SearchScreen(),
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
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: RouteNames.premiumPaywall,
        builder: (context, state) => const PremiumPaywallScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: RouteNames.support,
        builder: (context, state) => const SupportScreen(),
      ),
    ],
  );
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
  @override
  void initState() {
    super.initState();
    final session = ref.read(appSessionControllerProvider);
    if (session.splashSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _continueFlow();
      });
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ref.read(appSessionControllerProvider.notifier).markSplashSeen();
      Future<void>.delayed(const Duration(milliseconds: 1400), _continueFlow);
    });
  }

  void _continueFlow() {
    if (!mounted) {
      return;
    }
    final isLoggedIn = ref.read(
      authControllerProvider.select(
        (state) => state.valueOrNull?.isAuthenticated ?? false,
      ),
    );
    final session = ref.read(appSessionControllerProvider);

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
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: 40,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [Color(0x1F858C9F), Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Tutta',
                    style: TextStyle(
                      color: Color(0xFF072A73),
                      fontSize: 68,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'DIGITAL CONCIERGE',
                    style: TextStyle(
                      color: Color(0xFF7A8192),
                      fontSize: 18,
                      letterSpacing: 5.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 240),
                  Text(
                    'PREPARING YOUR STAY',
                    style: TextStyle(
                      color: Color(0xFF8E94A2),
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
