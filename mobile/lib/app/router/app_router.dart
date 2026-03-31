import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/screens/auth_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/bookings/presentation/screens/booking_payment_screen.dart';
import '../../features/bookings/presentation/screens/booking_request_screen.dart';
import '../../features/bookings/presentation/screens/host_requests_screen.dart';
import '../../features/bookings/presentation/screens/my_bookings_screen.dart';
import '../../features/chat/presentation/screens/chat_list_screen.dart';
import '../../features/home/application/app_session_controller.dart';
import '../../features/home/presentation/screens/home_shell_screen.dart';
import '../../features/listings/presentation/screens/listing_details_screen.dart';
import '../../features/listings/presentation/screens/search_screen.dart';
import '../../features/premium/presentation/screens/premium_paywall_screen.dart';
import '../../features/profile/presentation/screens/settings_screen.dart';
import '../../features/profile/presentation/screens/support_screen.dart';
import '../../features/reviews/presentation/screens/review_submit_screen.dart';
import '../../features/role/presentation/screens/role_selector_screen.dart';
import '../../features/wishlist/presentation/screens/favorites_screen.dart';
import 'route_names.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);
  final session = ref.watch(appSessionControllerProvider);

  return GoRouter(
    initialLocation: RouteNames.auth,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isLoggedIn = authState.valueOrNull?.isAuthenticated ?? false;
      final onboardingCompleted = session.onboardingCompleted;
      final roleSelected = session.activeRole != null;

      if (location == RouteNames.splash) {
        if (!onboardingCompleted) {
          return RouteNames.onboarding;
        }
        if (!isLoggedIn) {
          return RouteNames.auth;
        }
        if (!roleSelected) {
          return RouteNames.roleSelector;
        }
        return RouteNames.home;
      }

      if (!onboardingCompleted && location != RouteNames.onboarding) {
        return RouteNames.onboarding;
      }

      if (!isLoggedIn && location != RouteNames.auth) {
        return RouteNames.auth;
      }

      if (isLoggedIn && !roleSelected && location != RouteNames.roleSelector) {
        return RouteNames.roleSelector;
      }

      if (isLoggedIn && roleSelected) {
        if (location == RouteNames.auth || location == RouteNames.onboarding) {
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
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
