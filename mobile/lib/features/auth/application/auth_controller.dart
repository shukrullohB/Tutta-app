import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../core/config/runtime_flags.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_token_provider.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/repositories/api_auth_repository.dart';
import '../data/repositories/api_otp_auth_repository.dart';
import '../data/repositories/fake_auth_repository.dart';
import '../data/repositories/fake_otp_auth_repository.dart';
import '../domain/repositories/auth_repository.dart';
import '../domain/repositories/otp_auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!RuntimeFlags.useFakeAuth) {
    return ApiAuthRepository(ref.watch(apiClientProvider));
  }

  return FakeAuthRepository();
});

final otpAuthRepositoryProvider = Provider<OtpAuthRepository>((ref) {
  if (kDebugMode || RuntimeFlags.useFakeAuth) {
    return FakeOtpAuthRepository();
  }

  return ApiOtpAuthRepository(ref.watch(apiClientProvider));
});

class AuthController extends StateNotifier<AsyncValue<AuthState>> {
  AuthController(this._authRepository, this._otpAuthRepository, this._read)
    : super(const AsyncValue.data(AuthState.initial()));

  final AuthRepository _authRepository;
  final OtpAuthRepository _otpAuthRepository;
  final Ref _read;
  String? _lastOtpPhone;

  Future<bool> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      String idToken;
      String? accessToken;
      String? email;
      String? displayName;

      if (RuntimeFlags.useFakeAuth) {
        idToken = 'fake_google_id_token';
        accessToken = 'fake_google_access_token';
        email = 'google.demo@tutta.uz';
        displayName = 'Google Demo';
      } else {
        final googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
        final account = await googleSignIn.signIn();
        if (account == null) {
          throw const AppException('Google sign-in was cancelled.');
        }

        final auth = await account.authentication;
        if (auth.idToken == null || auth.idToken!.isEmpty) {
          throw const AppException('Google did not return an id token.');
        }

        idToken = auth.idToken!;
        accessToken = auth.accessToken;
        email = account.email;
        displayName = account.displayName;
      }

      final user = await _authRepository.signInWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
        email: email,
        displayName: displayName,
      );

      final access = user.accessToken;
      final refresh = user.refreshToken;

      if (access == null || access.isEmpty) {
        throw const AppException('Invalid token response from Google sign-in.');
      }

      final refreshToken = (refresh != null && refresh.isNotEmpty)
          ? refresh
          : 'google_refresh_fallback';

      await _read
          .read(secureStorageServiceProvider)
          .saveTokens(accessToken: access, refreshToken: refreshToken);
      _read.read(authTokenProvider.notifier).state = access;

      _lastOtpPhone = null;
      state = AsyncValue.data(AuthState(user: user, phoneForOtp: null));
      return true;
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      state = AsyncValue.error(AppException(error.toString()), stackTrace);
      return false;
    }
  }

  Future<String?> requestOtp(String phone) async {
    final normalizedPhone = _normalizeUzPhone(phone);
    if (!_isValidUzPhone(normalizedPhone)) {
      state = AsyncValue.error(
        const AppException(
          'Invalid phone number. Use +998XXXXXXXXX or 9-digit local number.',
        ),
        StackTrace.current,
      );
      return null;
    }

    final current = state.valueOrNull ?? const AuthState.initial();
    state = const AsyncValue.loading();

    try {
      await _otpAuthRepository.sendOtp(phone: normalizedPhone);
      _lastOtpPhone = normalizedPhone;
      state = AsyncValue.data(current.copyWith(phoneForOtp: normalizedPhone));
      return normalizedPhone;
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return null;
    } catch (error, stackTrace) {
      state = AsyncValue.error(AppException(error.toString()), stackTrace);
      return null;
    }
  }

  Future<void> verifyOtp(String code, {String? phoneOverride}) async {
    final normalizedCode = code.trim();
    if (normalizedCode.length != 6) {
      state = AsyncValue.error(
        const AppException('Invalid code'),
        StackTrace.current,
      );
      return;
    }

    final current = state.valueOrNull ?? const AuthState.initial();
    final phone = phoneOverride?.trim().isNotEmpty == true
        ? _normalizeUzPhone(phoneOverride!)
        : (current.phoneForOtp ?? _lastOtpPhone);
    if (phone == null || phone.isEmpty) {
      state = AsyncValue.error(
        const AppException('Phone number is missing. Request OTP first.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();

    try {
      final user = await _otpAuthRepository.verifyOtp(
        phone: phone,
        code: normalizedCode,
      );

      final access = user.accessToken;
      final refresh = user.refreshToken;
      if (access != null && access.isNotEmpty) {
        final refreshToken = (refresh != null && refresh.isNotEmpty)
            ? refresh
            : 'otp_refresh_fallback';
        await _read
            .read(secureStorageServiceProvider)
            .saveTokens(accessToken: access, refreshToken: refreshToken);
        _read.read(authTokenProvider.notifier).state = access;
      }

      _lastOtpPhone = null;
      state = AsyncValue.data(current.copyWith(user: user, clearPhone: true));
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(AppException(error.toString()), stackTrace);
    }
  }

  void clearOtpPhone() {
    final current = state.valueOrNull ?? const AuthState.initial();
    _lastOtpPhone = null;
    state = AsyncValue.data(current.copyWith(clearPhone: true));
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncValue.loading();

    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );
      final access = user.accessToken;
      final refresh = user.refreshToken;

      if (access == null ||
          access.isEmpty ||
          refresh == null ||
          refresh.isEmpty) {
        throw const AppException('Invalid token response from server.');
      }

      await _read
          .read(secureStorageServiceProvider)
          .saveTokens(accessToken: access, refreshToken: refresh);
      _read.read(authTokenProvider.notifier).state = access;

      state = AsyncValue.data(AuthState(user: user, phoneForOtp: null));
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(AppException(error.toString()), stackTrace);
    }
  }

  Future<void> registerAndLogin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? phoneNumber,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _authRepository.register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role,
        phoneNumber: phoneNumber,
      );
      await login(email: email, password: password);
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(AppException(error.toString()), stackTrace);
    }
  }

  Future<void> restoreSession() async {
    final storedAccess = await _read
        .read(secureStorageServiceProvider)
        .readAccessToken();
    final storedRefresh = await _read
        .read(secureStorageServiceProvider)
        .readRefreshToken();

    if (storedAccess == null || storedAccess.isEmpty) {
      return;
    }

    _read.read(authTokenProvider.notifier).state = storedAccess;

    try {
      final me = await _authRepository.me();
      state = AsyncValue.data(AuthState(user: me, phoneForOtp: null));
    } on AppException {
      if (storedRefresh != null && storedRefresh.isNotEmpty) {
        try {
          final rotated = await _authRepository.refresh(
            refreshToken: storedRefresh,
          );
          final access = rotated['access'] ?? '';
          final refresh = rotated['refresh'] ?? storedRefresh;
          if (access.isNotEmpty) {
            await _read
                .read(secureStorageServiceProvider)
                .saveTokens(accessToken: access, refreshToken: refresh);
            _read.read(authTokenProvider.notifier).state = access;
            final me = await _authRepository.me();
            state = AsyncValue.data(AuthState(user: me, phoneForOtp: null));
            return;
          }
        } catch (_) {
          // fallback below
        }
      }
      await signOut();
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      final refresh = await _read
          .read(secureStorageServiceProvider)
          .readRefreshToken();
      if (refresh != null && refresh.isNotEmpty) {
        await _authRepository.signOut(refreshToken: refresh);
      }
      await _read.read(secureStorageServiceProvider).clearTokens();
      _read.read(authTokenProvider.notifier).state = null;
      _lastOtpPhone = null;
      state = const AsyncValue.data(AuthState.initial());
    } on AppException catch (error, stackTrace) {
      await _read.read(secureStorageServiceProvider).clearTokens();
      _read.read(authTokenProvider.notifier).state = null;
      _lastOtpPhone = null;
      state = AsyncValue.error(error, stackTrace);
    } catch (error, stackTrace) {
      await _read.read(secureStorageServiceProvider).clearTokens();
      _read.read(authTokenProvider.notifier).state = null;
      _lastOtpPhone = null;
      state = AsyncValue.error(AppException(error.toString()), stackTrace);
    }
  }

  bool _isValidUzPhone(String phone) {
    return RegExp(r'^\+998\d{9}$').hasMatch(phone);
  }

  String _normalizeUzPhone(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');

    if (digitsOnly.length == 9) {
      return '+998$digitsOnly';
    }

    if (digitsOnly.length == 12 && digitsOnly.startsWith('998')) {
      return '+$digitsOnly';
    }

    // Keep explicit + and drop common visual separators for strict validation.
    return trimmed.replaceAll(RegExp(r'[\s\-\(\)]'), '');
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthState>>((ref) {
      final controller = AuthController(
        ref.watch(authRepositoryProvider),
        ref.watch(otpAuthRepositoryProvider),
        ref,
      );
      Future<void>.microtask(controller.restoreSession);
      return controller;
    });
