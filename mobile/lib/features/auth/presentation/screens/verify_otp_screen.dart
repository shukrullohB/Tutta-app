import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/errors/app_exception.dart';
import '../../application/auth_controller.dart';
import '../widgets/auth_ui_kit.dart';

class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  static const _cooldownSeconds = 60;
  final _codeController = TextEditingController();
  Timer? _timer;
  int _secondsLeft = _cooldownSeconds;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = _cooldownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_secondsLeft <= 1) {
        setState(() => _secondsLeft = 0);
        timer.cancel();
        return;
      }

      setState(() => _secondsLeft -= 1);
    });
  }

  Future<void> _verify(String phone) async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _setInlineError('Invalid code');
      return;
    }

    if (_secondsLeft == 0) {
      _setInlineError('Code expired. Please resend code.');
      return;
    }

    _setInlineError(null);
    await ref
        .read(authControllerProvider.notifier)
        .verifyOtp(code, phoneOverride: phone);

    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    authState.whenOrNull(
      data: (state) {
        if (state.isAuthenticated) {
          _setInlineError(null);
          context.go(RouteNames.roleSelector);
        }
      },
      error: (error, _) => _setInlineError(_mapError(error)),
    );
  }

  Future<void> _resend(String phone) async {
    if (_secondsLeft > 0) {
      return;
    }

    _setInlineError(null);
    await ref.read(authControllerProvider.notifier).requestOtp(phone);
    if (!mounted) {
      return;
    }

    final authState = ref.read(authControllerProvider);
    authState.whenOrNull(
      data: (_) {
        _startCooldown();
        _showSnack('Code resent');
      },
      error: (error, _) => _setInlineError(_mapError(error)),
    );
  }

  void _setInlineError(String? message) {
    if (!mounted) {
      return;
    }

    setState(() => _inlineError = message);
    if (message != null && message.isNotEmpty) {
      _showSnack(message);
    }
  }

  void _changePhoneNumber() {
    ref.read(authControllerProvider.notifier).clearOtpPhone();
    context.go(RouteNames.auth);
  }

  void _showSnack(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final state = authState.valueOrNull;
    final isLoading = authState.isLoading;
    final queryPhone = GoRouterState.of(context).uri.queryParameters['phone'];
    final phone = queryPhone ?? state?.phoneForOtp;
    final authError = authState.whenOrNull(
      error: (error, _) => _mapError(error),
    );
    final shownError = _inlineError ?? authError;

    if (phone == null || phone.isEmpty) {
      return AuthScaffold(
        title: 'Verify code',
        subtitle: 'Confirm your phone to continue',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthBanner.error(
              'Phone number is missing. Please request a new code.',
            ),
            const SizedBox(height: AuthSpacing.md),
            AuthPrimaryButton(
              label: 'Change phone number',
              onPressed: _changePhoneNumber,
            ),
          ],
        ),
      );
    }

    return AuthScaffold(
      title: 'Verify\nCode',
      subtitle: 'We sent a 6-digit code to ${_maskPhone(phone)}',
      leading: IconButton(
        onPressed: _changePhoneNumber,
        icon: const Icon(Icons.arrow_back, color: AuthPalette.text),
      ),
      trailing: const CircleAvatar(
        radius: 12,
        backgroundColor: Color(0xFFF5DCC8),
        child: Icon(Icons.person, size: 14, color: AuthPalette.text),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (shownError != null) ...[
            AuthBanner.error(
              shownError,
            ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.06, end: 0),
            const SizedBox(height: AuthSpacing.md),
          ],
          AuthTextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                labelText: 'CODE',
                hintText: '123456',
                maxLength: 6,
                counterText: '',
              )
              .animate(delay: 60.ms)
              .fadeIn(duration: 240.ms)
              .slideY(begin: 0.08, end: 0),
          if (kDebugMode) ...[
            const SizedBox(height: 4),
            const Text(
              'Dev OTP: 123456',
              style: TextStyle(color: AuthPalette.textMuted, fontSize: 11),
            ).animate(delay: 100.ms).fadeIn(duration: 220.ms),
          ],
          const SizedBox(height: AuthSpacing.md),
          AuthPrimaryButton(
                label: 'Confirm',
                onPressed: isLoading ? null : () => _verify(phone),
                loading: isLoading,
              )
              .animate(delay: 140.ms)
              .fadeIn(duration: 240.ms)
              .slideY(begin: 0.08, end: 0),
          const SizedBox(height: AuthSpacing.sm),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              onPressed: isLoading ? null : _changePhoneNumber,
              child: const Text(
                'Change phone number',
                style: TextStyle(color: AuthPalette.textMuted, fontSize: 12),
              ),
            ),
          ).animate(delay: 180.ms).fadeIn(duration: 220.ms),
          const SizedBox(height: AuthSpacing.xs),
          Center(
            child: AnimatedSwitcher(
              duration: 220.ms,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _secondsLeft > 0
                  ? Text(
                      'Resend code in ${_secondsLeft}s',
                      key: const ValueKey('resend-wait'),
                      style: const TextStyle(
                        color: AuthPalette.textMuted,
                        fontSize: 12,
                      ),
                    )
                  : TextButton(
                      key: const ValueKey('resend-action'),
                      onPressed: isLoading ? null : () => _resend(phone),
                      child: const Text(
                        'Resend code',
                        style: TextStyle(
                          color: AuthPalette.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ),
          ).animate(delay: 220.ms).fadeIn(duration: 220.ms),
        ],
      ),
    );
  }

  String _maskPhone(String phone) {
    if (phone.length < 13) {
      return phone;
    }

    final clean = phone.replaceAll(' ', '');
    if (!clean.startsWith('+998') || clean.length < 13) {
      return phone;
    }

    final p1 = clean.substring(0, 4);
    final p2 = clean.substring(4, 6);
    final p3 = clean.substring(6, 9);
    final p4 = clean.substring(9, 11);
    final p5 = clean.substring(11, 13);
    return '$p1 $p2 $p3 $p4 $p5';
  }
}
