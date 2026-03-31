import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/app_role.dart';

class AppSessionState {
  const AppSessionState({
    required this.onboardingCompleted,
    required this.activeRole,
  });

  const AppSessionState.initial()
    : onboardingCompleted = false,
      activeRole = null;

  final bool onboardingCompleted;
  final AppRole? activeRole;

  AppSessionState copyWith({
    bool? onboardingCompleted,
    AppRole? activeRole,
    bool clearRole = false,
  }) {
    return AppSessionState(
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      activeRole: clearRole ? null : (activeRole ?? this.activeRole),
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
}

final appSessionControllerProvider =
    StateNotifierProvider<AppSessionController, AppSessionState>((ref) {
      return AppSessionController();
    });
