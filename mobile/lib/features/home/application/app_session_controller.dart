import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/enums/app_role.dart';
import '../../../core/storage/secure_storage_service.dart';

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
  AppSessionController(this._ref) : super(const AppSessionState.initial()) {
    _restore();
  }

  final Ref _ref;
  static const _onboardingKey = 'session_onboarding_completed';
  static const _roleKey = 'session_active_role';
  static const _splashKey = 'session_splash_seen';

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingCompleted: true);
    await _persistBool(_onboardingKey, true);
  }

  void setRole(AppRole role) {
    state = state.copyWith(activeRole: role);
    _persistString(_roleKey, role.name);
  }

  void clearRole() {
    state = state.copyWith(clearRole: true);
    _delete(_roleKey);
  }

  Future<void> resetForFirstLaunch() async {
    state = const AppSessionState.initial();
    await Future.wait([
      _delete(_onboardingKey),
      _delete(_roleKey),
      _delete(_splashKey),
    ]);
  }

  void markSplashSeen() {
    if (state.splashSeen) {
      return;
    }
    state = state.copyWith(splashSeen: true);
    _persistBool(_splashKey, true);
  }

  Future<void> _restore() async {
    final storage = _ref.read(secureStorageServiceProvider);
    final onboardingRaw = await storage.readString(_onboardingKey);
    final roleRaw = await storage.readString(_roleKey);
    final splashRaw = await storage.readString(_splashKey);

    AppRole? restoredRole;
    if (roleRaw != null && roleRaw.isNotEmpty) {
      for (final role in AppRole.values) {
        if (role.name == roleRaw) {
          restoredRole = role;
          break;
        }
      }
    }

    state = state.copyWith(
      onboardingCompleted: onboardingRaw == 'true',
      activeRole: restoredRole,
      splashSeen: splashRaw == 'true',
    );
  }

  Future<void> _persistBool(String key, bool value) {
    return _ref
        .read(secureStorageServiceProvider)
        .writeString(key: key, value: value.toString());
  }

  Future<void> _persistString(String key, String value) {
    return _ref
        .read(secureStorageServiceProvider)
        .writeString(key: key, value: value);
  }

  Future<void> _delete(String key) {
    return _ref.read(secureStorageServiceProvider).delete(key);
  }
}

final appSessionControllerProvider =
    StateNotifierProvider<AppSessionController, AppSessionState>((ref) {
      return AppSessionController(ref);
    });
