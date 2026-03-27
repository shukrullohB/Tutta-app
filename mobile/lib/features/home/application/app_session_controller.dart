import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/app_role.dart';

class AppSessionState {
  const AppSessionState({
    required this.onboardingCompleted,
    required this.activeRole,
    required this.splashSeen,
  });

  const AppSessionState.initial()
    : onboardingCompleted = false,
      activeRole = null,
      splashSeen = false;

  final bool onboardingCompleted;
  final AppRole? activeRole;
  final bool splashSeen;

  AppSessionState copyWith({
    bool? onboardingCompleted,
    AppRole? activeRole,
    bool? splashSeen,
    bool clearRole = false,
  }) {
    return AppSessionState(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      activeRole: clearRole ? null : (activeRole ?? this.activeRole),
      splashSeen: splashSeen ?? this.splashSeen,
    );
  }
}

class AppSessionController extends StateNotifier<AppSessionState> {
  AppSessionController() : super(const AppSessionState.initial());

  void completeOnboarding() {
    state = state.copyWith(onboardingCompleted: true);
  }

  void setRole(AppRole role) {
    state = state.copyWith(activeRole: role);
  }

  void clearRole() {
    state = state.copyWith(clearRole: true);
  }

  void markSplashSeen() {
    if (state.splashSeen) {
      return;
    }
    state = state.copyWith(splashSeen: true);
  }
}

final appSessionControllerProvider =
    StateNotifierProvider<AppSessionController, AppSessionState>((ref) {
      return AppSessionController();
    });
