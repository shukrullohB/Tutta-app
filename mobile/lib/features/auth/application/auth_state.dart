import '../domain/models/auth_user.dart';

class AuthState {
  const AuthState({
    required this.user,
    required this.phoneForOtp,
    required this.hydrated,
  });

  const AuthState.initial() : user = null, phoneForOtp = null, hydrated = false;

  final AuthUser? user;
  final String? phoneForOtp;
  final bool hydrated;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AuthUser? user,
    String? phoneForOtp,
    bool? hydrated,
    bool clearUser = false,
    bool clearPhone = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      phoneForOtp: clearPhone ? null : (phoneForOtp ?? this.phoneForOtp),
      hydrated: hydrated ?? this.hydrated,
    );
  }
}
