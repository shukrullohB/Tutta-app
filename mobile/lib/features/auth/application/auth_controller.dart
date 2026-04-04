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
  int _authEpoch = 0;

  Future<bool> signInWithGoogle() async {
    _authEpoch++;
    print('[AUTH_TRACE] signInWithGoogle:start epoch=$_authEpoch');
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
        final googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: kIsWeb ? _googleWebClientId : null,
          serverClientId: _googleServerClientId,
        );
        try {
          await googleSignIn.signOut();
        } catch (_) {}
        final account = await googleSignIn.signIn();
        if (account == null) {
          print('[AUTH_TRACE] signInWithGoogle:cancelled');
          throw const AppException('Google sign-in was cancelled.');
        }
        print(
          '[AUTH_TRACE] signInWithGoogle:google account selected email=${account.email}',
        );

        final auth = await account.authentication;
        final resolvedIdToken = auth.idToken?.trim();
        final resolvedAccessToken = auth.accessToken?.trim();
        if ((resolvedIdToken == null || resolvedIdToken.isEmpty) &&
            (resolvedAccessToken == null || resolvedAccessToken.isEmpty)) {
          throw const AppException(
            'Google did not return a usable authentication token.',
          );
        }

        idToken = resolvedIdToken ?? '';
        accessToken = resolvedAccessToken;
        email = account.email;
        displayName = account.displayName;
      }

      print(
        '[AUTH_TRACE] signInWithGoogle:calling backend idToken=${idToken.isNotEmpty} accessToken=${(accessToken ?? '').isNotEmpty}',
      );

      final user = await _authRepository.signInWithGoogle(
        idToken: idToken,
        accessToken: accessToken,
        email: email,
        displayName: displayName,
      );
      print('[AUTH_TRACE] signInWithGoogle:backend success userId=${user.id}');

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
      print('[AUTH_TRACE] signInWithGoogle:tokens saved');

      _lastOtpPhone = null;
      state = AsyncValue.data(
        AuthState(user: user, phoneForOtp: null, hydrated: true),
      );
      print('[AUTH_TRACE] signInWithGoogle:done success=true');
      return true;
    } on AppException catch (error, stackTrace) {
      print('[AUTH_TRACE] signInWithGoogle:AppException ${error.message}');
      state = AsyncValue.error(error, stackTrace);
      return false;
    } catch (error, stackTrace) {
      print('[AUTH_TRACE] signInWithGoogle:Exception $error');
      state = AsyncValue.error(AppException(error.toString()), stackTrace);
      return false;
    }
  }

  String? get _googleWebClientId {
    const value = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
    if (value.trim().isEmpty) {
      return null;
    }
    return value.trim();
  }

  String? get _googleServerClientId {
    const value = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
    if (value.trim().isNotEmpty) {
      return value.trim();
    }
    return _googleWebClientId;
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
      state = AsyncValue.data(
        current.copyWith(phoneForOtp: normalizedPhone, hydrated: true),
      );
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
      state = AsyncValue.data(
        current.copyWith(user: user, clearPhone: true, hydrated: true),
      );
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(AppException(error.toString()), stackTrace);
    }
  }

  void clearOtpPhone() {
    final current = state.valueOrNull ?? const AuthState.initial();
    _lastOtpPhone = null;
    state = AsyncValue.data(current.copyWith(clearPhone: true, hydrated: true));
  }

  Future<void> login({required String email, required String password}) async {
    _authEpoch++;
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

      state = AsyncValue.data(
        AuthState(user: user, phoneForOtp: null, hydrated: true),
      );
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
    _authEpoch++;
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
    final startedEpoch = _authEpoch;
    try {
      final storedAccess = await _read
          .read(secureStorageServiceProvider)
          .readAccessToken();
      final storedRefresh = await _read
          .read(secureStorageServiceProvider)
          .readRefreshToken();

      if (startedEpoch != _authEpoch) {
        return;
      }

      if (storedAccess == null || storedAccess.isEmpty) {
        if (startedEpoch != _authEpoch) {
          return;
        }
        state = AsyncValue.data(
          const AuthState.initial().copyWith(hydrated: true),
        );
        return;
      }

      _read.read(authTokenProvider.notifier).state = storedAccess;

      try {
        final me = await _authRepository.me();
        if (startedEpoch != _authEpoch) {
          return;
        }
        state = AsyncValue.data(
          AuthState(user: me, phoneForOtp: null, hydrated: true),
        );
        return;
      } on AppException {
        // Try refresh fallback below.
      }

      if (storedRefresh != null && storedRefresh.isNotEmpty) {
        try {
          final rotated = await _authRepository.refresh(
            refreshToken: storedRefresh,
          );
          if (startedEpoch != _authEpoch) {
            return;
          }
          final access = rotated['access'] ?? '';
          final refresh = rotated['refresh'] ?? storedRefresh;
          if (access.isNotEmpty) {
            await _read
                .read(secureStorageServiceProvider)
                .saveTokens(accessToken: access, refreshToken: refresh);
            _read.read(authTokenProvider.notifier).state = access;
            final me = await _authRepository.me();
            if (startedEpoch != _authEpoch) {
              return;
            }
            state = AsyncValue.data(
              AuthState(user: me, phoneForOtp: null, hydrated: true),
            );
            return;
          }
        } catch (_) {
          // Continue to local sign-out fallback below.
        }
      }

      if (startedEpoch != _authEpoch) {
        return;
      }
      await _read.read(secureStorageServiceProvider).clearTokens();
      _read.read(authTokenProvider.notifier).state = null;
      _lastOtpPhone = null;
      state = AsyncValue.data(
        const AuthState.initial().copyWith(hydrated: true),
      );
    } catch (_) {
      await _read.read(secureStorageServiceProvider).clearTokens();
      _read.read(authTokenProvider.notifier).state = null;
      _lastOtpPhone = null;
      state = AsyncValue.data(
        const AuthState.initial().copyWith(hydrated: true),
      );
    }
  }

  Future<void> signOut() async {
    _authEpoch++;
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
      state = AsyncValue.data(
        const AuthState.initial().copyWith(hydrated: true),
      );
    } on AppException {
      await _read.read(secureStorageServiceProvider).clearTokens();
      _read.read(authTokenProvider.notifier).state = null;
      _lastOtpPhone = null;
      state = AsyncValue.data(
        const AuthState.initial().copyWith(hydrated: true),
      );
    } catch (_) {
      await _read.read(secureStorageServiceProvider).clearTokens();
      _read.read(authTokenProvider.notifier).state = null;
      _lastOtpPhone = null;
      state = AsyncValue.data(
        const AuthState.initial().copyWith(hydrated: true),
      );
    }
  }

  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    final existingUser = state.valueOrNull?.user;
    if (existingUser == null) {
      state = AsyncValue.error(
        const AppException('Please sign in again.'),
        StackTrace.current,
      );
      return;
    }

    state = const AsyncValue.loading();
    try {
      final updated = await _authRepository.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      state = AsyncValue.data(
        AuthState(user: updated, phoneForOtp: null, hydrated: true),
      );
    } on AppException catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    } catch (error, stackTrace) {
      state = AsyncValue.error(AppException(error.toString()), stackTrace);
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authRepository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(error.toString());
    }
  }

  Future<void> deleteAccount({required String currentPassword}) async {
    try {
      await _authRepository.deleteAccount(currentPassword: currentPassword);
      await _read.read(secureStorageServiceProvider).clearTokens();
      _read.read(authTokenProvider.notifier).state = null;
      _lastOtpPhone = null;
      state = AsyncValue.data(
        const AuthState.initial().copyWith(hydrated: true),
      );
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(error.toString());
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
