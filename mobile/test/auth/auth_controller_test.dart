import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tutta/core/errors/app_exception.dart';
import 'package:tutta/core/network/auth_token_provider.dart';
import 'package:tutta/features/auth/application/auth_controller.dart';

ProviderContainer _createContainer() {
  return ProviderContainer(
    overrides: [
      authControllerProvider.overrideWith((ref) {
        return AuthController(
          ref.watch(authRepositoryProvider),
          ref.watch(otpAuthRepositoryProvider),
          ref,
        );
      }),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const storageChannel = MethodChannel(
    'plugins.it_nomads.com/flutter_secure_storage',
  );
  final storage = <String, String>{};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, (call) async {
          final key = call.arguments['key'] as String?;
          switch (call.method) {
            case 'write':
              if (key != null) {
                storage[key] = call.arguments['value'] as String? ?? '';
              }
              return null;
            case 'read':
              if (key == null) {
                return null;
              }
              return storage[key];
            case 'delete':
              if (key != null) {
                storage.remove(key);
              }
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    storage.clear();
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(storageChannel, null);
  });

  group('AuthController', () {
    test('login sets authenticated user and auth token', () async {
      final container = _createContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      await controller.login(email: 'demo@tutta.uz', password: 'DemoPass123!');

      final authState = container.read(authControllerProvider).valueOrNull;
      final token = container.read(authTokenProvider);

      expect(authState, isNotNull);
      expect(authState?.isAuthenticated, isTrue);
      expect(authState?.user?.id, 'user_demo_1');
      expect(authState?.user?.email, 'demo@tutta.uz');
      expect(token, isNotNull);
      expect(token, isNotEmpty);
    });

    test('signOut clears auth token and auth state', () async {
      final container = _createContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      await controller.login(email: 'demo@tutta.uz', password: 'DemoPass123!');
      await controller.signOut();

      final authState = container.read(authControllerProvider).valueOrNull;
      final token = container.read(authTokenProvider);

      expect(authState, isNotNull);
      expect(authState?.isAuthenticated, isFalse);
      expect(authState?.user, isNull);
      expect(token, isNull);
    });

    test('fake OTP flow authenticates with code 123456', () async {
      final container = _createContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      await controller.requestOtp('90 123 45 67');
      await controller.verifyOtp('123456');

      final authState = container.read(authControllerProvider).valueOrNull;
      final token = container.read(authTokenProvider);

      expect(authState, isNotNull);
      expect(authState?.isAuthenticated, isTrue);
      expect(authState?.user?.id, 'otp_demo_user_1');
      expect(token, isNotNull);
      expect(token, isNotEmpty);
    });

    test('requestOtp returns normalized +998 phone', () async {
      final container = _createContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      final normalized = await controller.requestOtp('(90) 123-45-67');
      final authState = container.read(authControllerProvider).valueOrNull;

      expect(normalized, '+998901234567');
      expect(authState?.phoneForOtp, '+998901234567');
    });

    test('fake OTP flow returns Invalid code for non-matching OTP', () async {
      final container = _createContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      await controller.requestOtp('+998901234567');
      await controller.verifyOtp('111111');

      final authState = container.read(authControllerProvider);
      expect(authState.hasError, isTrue);
      expect(authState.error, isA<AppException>());
      expect((authState.error as AppException).message, 'Invalid code');
    });

    test('fake Google sign-in authenticates and saves token', () async {
      final container = _createContainer();
      addTearDown(container.dispose);

      final controller = container.read(authControllerProvider.notifier);

      final success = await controller.signInWithGoogle();

      final authState = container.read(authControllerProvider).valueOrNull;
      final token = container.read(authTokenProvider);

      expect(success, isTrue);
      expect(authState, isNotNull);
      expect(authState?.isAuthenticated, isTrue);
      expect(authState?.user?.id, 'user_google_demo_1');
      expect(token, isNotNull);
      expect(token, isNotEmpty);
    });
  });
}
