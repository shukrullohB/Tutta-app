import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/runtime_flags.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/auth_token_provider.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../data/repositories/api_auth_repository.dart';
import '../data/repositories/fake_auth_repository.dart';
import '../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (!RuntimeFlags.useFakeAuth) {
    return ApiAuthRepository(ref.watch(apiClientProvider));
  }

  return FakeAuthRepository();
});

class AuthController extends StateNotifier<AsyncValue<AuthState>> {
  AuthController(this._authRepository, this._read)
    : super(const AsyncValue.data(AuthState.initial()));

  final AuthRepository _authRepository;
  final Ref _read;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final user = await _authRepository.login(email: email, password: password);
      final access = user.accessToken;
      final refresh = user.refreshToken;

      if (access == null || access.isEmpty || refresh == null || refresh.isEmpty) {
        throw const AppException('Invalid token response from server.');
      }

      await _read.read(secureStorageServiceProvider).saveTokens(
        accessToken: access,
        refreshToken: refresh,
      );
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
    final storedAccess = await _read.read(secureStorageServiceProvider).readAccessToken();
    final storedRefresh = await _read.read(secureStorageServiceProvider).readRefreshToken();

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
          final rotated = await _authRepository.refresh(refreshToken: storedRefresh);
          final access = rotated['access'] ?? '';
          final refresh = rotated['refresh'] ?? storedRefresh;
          if (access.isNotEmpty) {
            await _read.read(secureStorageServiceProvider).saveTokens(
              accessToken: access,
              refreshToken: refresh,
            );
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
      final refresh = await _read.read(secureStorageServiceProvider).readRefreshToken();
      if (refresh != null && refresh.isNotEmpty) {
        await _authRepository.signOut(refreshToken: refresh);
      }
      await _read.read(secureStorageServiceProvider).clearTokens();
      _read.read(authTokenProvider.notifier).state = null;
      state = const AsyncValue.data(AuthState.initial());
    } on AppException catch (error, stackTrace) {
      await _read.read(secureStorageServiceProvider).clearTokens();
      _read.read(authTokenProvider.notifier).state = null;
      state = AsyncValue.error(error, stackTrace);
    } catch (error, stackTrace) {
      await _read.read(secureStorageServiceProvider).clearTokens();
      _read.read(authTokenProvider.notifier).state = null;
      state = AsyncValue.error(AppException(error.toString()), stackTrace);
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthState>>((ref) {
      final controller = AuthController(ref.watch(authRepositoryProvider), ref);
      Future<void>.microtask(controller.restoreSession);
      return controller;
    });
