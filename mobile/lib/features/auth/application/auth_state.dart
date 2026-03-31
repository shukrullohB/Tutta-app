import '../domain/models/auth_user.dart';

class AuthState {
  const AuthState({required this.user, required this.phoneForOtp});

  const AuthState.initial() : user = null, phoneForOtp = null;

  final AuthUser? user;
  final String? phoneForOtp;

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AuthUser? user,
    String? phoneForOtp,
    bool clearUser = false,
    bool clearPhone = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      phoneForOtp: clearPhone ? null : (phoneForOtp ?? this.phoneForOtp),
    );
  }
}
