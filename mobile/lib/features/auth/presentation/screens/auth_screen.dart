import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app.dart';
import '../../../../app/router/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../l10n/app_localizations.dart';
import '../../application/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isSignUp = false;
  bool _obscurePassword = true;
  bool _agreed = false;
  String? _inlineError;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp({String? value}) async {
    final phone = (value ?? _phoneController.text).trim();
    _setInlineError(null);
    final phoneForOtp = await ref
        .read(authControllerProvider.notifier)
        .requestOtp(phone);

    if (!mounted) {
      return;
    }

    if (phoneForOtp != null && phoneForOtp.isNotEmpty) {
      final encodedPhone = Uri.encodeQueryComponent(phoneForOtp);
      context.go('${RouteNames.authVerify}?phone=$encodedPhone');
      return;
    }

    final authState = ref.read(authControllerProvider);
    authState.whenOrNull(
      error: (error, _) => _setInlineError(_mapError(error)),
    );
  }

  Future<void> _signInWithEmail() async {
    final loc = AppLocalizations.of(context);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _setInlineError(loc.authEnterEmailPassword);
      return;
    }

    _setInlineError(null);
    await ref
        .read(authControllerProvider.notifier)
        .login(email: email, password: password);

    if (!mounted) {
      return;
    }

    final state = ref.read(authControllerProvider);
    if ((state.valueOrNull?.isAuthenticated ?? false) == true) {
      context.go(RouteNames.roleSelector);
      return;
    }

    state.whenOrNull(error: (error, _) => _setInlineError(_mapError(error)));
  }

  Future<void> _register() async {
    final loc = AppLocalizations.of(context);
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _setInlineError(loc.authFillRequired);
      return;
    }
    if (!_agreed) {
      _setInlineError(loc.authAcceptTerms);
      return;
    }

    final parts = fullName
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    final firstName = parts.isEmpty ? 'User' : parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'Member';

    _setInlineError(null);
    await ref
        .read(authControllerProvider.notifier)
        .registerAndLogin(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          role: 'guest',
          phoneNumber: phone.isEmpty ? null : phone,
        );

    if (!mounted) {
      return;
    }

    final state = ref.read(authControllerProvider);
    if ((state.valueOrNull?.isAuthenticated ?? false) == true) {
      context.go(RouteNames.roleSelector);
      return;
    }

    state.whenOrNull(error: (error, _) => _setInlineError(_mapError(error)));
  }

  Future<void> _signInWithGoogle() async {
    _setInlineError(null);
    final success = await ref
        .read(authControllerProvider.notifier)
        .signInWithGoogle();

    if (!mounted) {
      return;
    }

    if (success) {
      context.go(RouteNames.roleSelector);
      return;
    }

    final authState = ref.read(authControllerProvider);
    authState.whenOrNull(
      error: (error, _) => _setInlineError(_mapError(error)),
    );
  }

  void _setInlineError(String? message) {
    if (!mounted) {
      return;
    }

    setState(() => _inlineError = message);
    if (message != null && message.isNotEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  String _mapError(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final shownError =
        _inlineError ??
        authState.whenOrNull(error: (error, _) => _mapError(error));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 18, 28, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const LanguageSelector(),
                  const Spacer(),
                  const Text(
                    'Tutta',
                    style: TextStyle(
                      color: AppColors.primaryDeep,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ).animate().fadeIn(duration: 220.ms),
              const SizedBox(height: 24),
              if (!_isSignUp) ...[
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${loc.authWelcome}\n',
                        style: const TextStyle(
                          color: AppColors.primaryDeep,
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          height: 0.98,
                        ),
                      ),
                      TextSpan(
                        text: loc.authBack,
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          height: 0.98,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  loc.authSubtitle,
                  style: const TextStyle(
                    color: AppColors.textSoft,
                    fontSize: 17,
                    height: 1.35,
                  ),
                ),
              ] else ...[
                Center(
                  child: Text(
                    loc.authCreateAccount,
                    style: const TextStyle(
                      color: AppColors.primaryDeep,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: '${loc.authAlreadyMember} ',
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 17,
                      ),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => setState(() => _isSignUp = false),
                            child: Text(
                              loc.authSignInAction,
                              style: const TextStyle(
                                color: AppColors.primaryDeep,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 26),
              if (shownError != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFFDEBEC),
                    border: Border.all(color: const Color(0xFFF0C0B8)),
                  ),
                  child: Text(
                    shownError,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ).animate().fadeIn(duration: 180.ms),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      label: 'Google',
                      isGoogle: true,
                      onTap: isLoading ? null : _signInWithGoogle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _DividerText(label: loc.authContinueWithEmail),
              const SizedBox(height: 18),
              if (_isSignUp) ...[
                _FieldLabel(text: loc.authFullName.toUpperCase()),
                _LightField(
                  controller: _fullNameController,
                  hintText: 'John Doe',
                  suffixIcon: Icons.person,
                ),
                const SizedBox(height: 10),
              ],
              _FieldLabel(text: loc.authEmail.toUpperCase()),
              _LightField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                hintText: _isSignUp
                    ? 'john@example.com'
                    : 'concierge@tutta.com',
                suffixIcon: Icons.email,
              ),
              const SizedBox(height: 10),
              if (_isSignUp) ...[
                _FieldLabel(text: loc.authPhone.toUpperCase()),
                _LightField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  hintText: '+998901234567',
                  suffixIcon: Icons.smartphone,
                ),
                const SizedBox(height: 10),
              ],
              Row(
                children: [
                  _FieldLabel(text: loc.authPassword.toUpperCase()),
                  const Spacer(),
                  if (!_isSignUp)
                    Text(
                      loc.authForgotPassword.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.1,
                      ),
                    ),
                ],
              ),
              _LightField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                hintText: '••••••••',
                suffixIcon: _obscurePassword
                    ? Icons.visibility
                    : Icons.visibility_off,
                onSuffixTap: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              if (_isSignUp) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      side: const BorderSide(color: AppColors.borderStrong),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          loc.authTermsAgree,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 16,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: _isSignUp
                    ? FilledButton.icon(
                        onPressed: isLoading ? null : _register,
                        icon: const Icon(Icons.arrow_right_alt),
                        iconAlignment: IconAlignment.end,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          backgroundColor: AppColors.primaryDeep,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        label: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                loc.authCreateButton,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      )
                    : FilledButton(
                        onPressed: isLoading ? null : _signInWithEmail,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          backgroundColor: AppColors.primaryDeep,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                loc.authSignInAction,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
              ),
              const SizedBox(height: 14),
              if (!_isSignUp)
                Center(
                  child: TextButton.icon(
                    onPressed: isLoading
                        ? null
                        : () async {
                            final value = await _askPhoneDialog();
                            if (value != null && value.isNotEmpty) {
                              _phoneController.text = value;
                              await _sendOtp(value: value);
                            }
                          },
                    icon: const Icon(
                      Icons.smartphone,
                      color: AppColors.textSoft,
                    ),
                    label: Text(
                      loc.authContinueWithPhone,
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              if (!_isSignUp)
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: '${loc.authNewToTutta} ',
                      style: const TextStyle(
                        color: AppColors.textSoft,
                        fontSize: 17,
                      ),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => setState(() => _isSignUp = true),
                            child: Text(
                              loc.authRegister,
                              style: const TextStyle(
                                color: AppColors.primaryDeep,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ).animate().fadeIn(duration: 260.ms),
        ),
      ),
    );
  }

  Future<String?> _askPhoneDialog() async {
    final controller = TextEditingController(text: _phoneController.text);
    final value = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final loc = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(loc.authPhoneDialogTitle),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+998901234567'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                MaterialLocalizations.of(dialogContext).cancelButtonLabel,
              ),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: Text(
                MaterialLocalizations.of(dialogContext).okButtonLabel,
              ),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return value;
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textMuted,
          letterSpacing: 2,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _LightField extends StatelessWidget {
  const _LightField({
    required this.controller,
    required this.hintText,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
  });

  final TextEditingController controller;
  final String hintText;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10E36A3A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.iconMuted, fontSize: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          suffixIcon: suffixIcon == null
              ? null
              : IconButton(
                  onPressed: onSuffixTap,
                  icon: Icon(suffixIcon, color: const Color(0xFFA08A81)),
                ),
        ),
      ),
    );
  }
}

class _DividerText extends StatelessWidget {
  const _DividerText({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.onTap,
    this.isGoogle = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isGoogle;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: AppColors.borderStrong),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isGoogle) ...[const _GoogleBadge(), const SizedBox(width: 10)],
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleBadge extends StatelessWidget {
  const _GoogleBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10E36A3A),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
