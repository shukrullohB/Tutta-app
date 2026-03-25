import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/errors/app_exception.dart';
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
      _setInlineError(null);
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
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _setInlineError('Enter your email and password.');
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
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      _setInlineError('Fill in full name, email, and password.');
      return;
    }
    if (!_agreed) {
      _setInlineError('Please accept Terms and Privacy Policy.');
      return;
    }

    final parts = fullName.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    final firstName = parts.isEmpty ? 'User' : parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'Member';

    _setInlineError(null);
    await ref.read(authControllerProvider.notifier).registerAndLogin(
          email: email,
          password: password,
          firstName: firstName,
          lastName: lastName,
          role: 'renter',
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
      _setInlineError(null);
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
      _showSnack(message);
    }
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
    final isLoading = authState.isLoading;

    final authError = authState.whenOrNull(
      error: (error, _) => _mapError(error),
    );
    final shownError = _inlineError ?? authError;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 14, 28, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isSignUp)
                Row(
                  children: [
                    const Icon(Icons.menu, color: Color(0xFF072A73)),
                    const Spacer(),
                    const Text(
                      'Tutta',
                      style: TextStyle(
                        color: Color(0xFF072A73),
                        fontSize: 56 / 2,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFF3CDAD),
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: Color(0xFFB78664),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 220.ms)
              else
                const Center(
                  child: Text(
                    'Tutta',
                    style: TextStyle(
                      color: Color(0xFF072A73),
                      fontSize: 56 / 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ).animate().fadeIn(duration: 220.ms),
              const SizedBox(height: 20),
              if (!_isSignUp) ...[
                Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Welcome\n',
                        style: TextStyle(
                          color: Color(0xFF072A73),
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          height: 0.98,
                        ),
                      ),
                      TextSpan(
                        text: 'Back.',
                        style: TextStyle(
                          color: Color(0xFF7FA0F3),
                          fontSize: 42,
                          fontWeight: FontWeight.w700,
                          height: 0.98,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Access your curated world of hospitality and editorial stays.',
                  style: TextStyle(
                    color: Color(0xFF3D4350),
                    fontSize: 20 / 1.2,
                    height: 1.35,
                  ),
                ),
              ] else ...[
                const Center(
                  child: Text(
                    'Create your account',
                    style: TextStyle(
                      color: Color(0xFF072A73),
                      fontSize: 52 / 2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'Already a member? ',
                      style: const TextStyle(color: Color(0xFF3D4350), fontSize: 17),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => setState(() => _isSignUp = false),
                            child: const Text(
                              'Sign in',
                              style: TextStyle(
                                color: Color(0xFF072A73),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFFDEBEC),
                    border: Border.all(color: const Color(0xFFE2A8AA)),
                  ),
                  child: Text(
                    shownError,
                    style: const TextStyle(color: Color(0xFF8D2A2E)),
                  ),
                ).animate().fadeIn(duration: 180.ms),
              Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      label: 'Google',
                      icon: Icons.g_mobiledata,
                      onTap: isLoading ? null : _signInWithGoogle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SocialButton(
                      label: 'Apple',
                      icon: Icons.apple,
                      onTap: () => _showSnack('Apple sign-in is not connected yet.'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const _DividerText(label: 'OR CONTINUE WITH EMAIL'),
              const SizedBox(height: 18),
              if (_isSignUp) ...[
                _FieldLabel(text: 'FULL NAME'),
                _LightField(
                  controller: _fullNameController,
                  hintText: 'John Doe',
                  suffixIcon: Icons.person,
                ),
                const SizedBox(height: 10),
              ],
              _FieldLabel(text: 'EMAIL ADDRESS'),
              _LightField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                hintText: _isSignUp ? 'john@example.com' : 'concierge@tutta.com',
                suffixIcon: Icons.email,
              ),
              const SizedBox(height: 10),
              if (_isSignUp) ...[
                _FieldLabel(text: 'PHONE NUMBER'),
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
                  const _FieldLabel(text: 'PASSWORD'),
                  const Spacer(),
                  if (!_isSignUp)
                    const Text(
                      'FORGOT PASSWORD?',
                      style: TextStyle(
                        color: Color(0xFF6A480A),
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
                suffixIcon: _obscurePassword ? Icons.visibility : Icons.visibility_off,
                onSuffixTap: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              if (_isSignUp) ...[
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreed,
                      onChanged: (v) => setState(() => _agreed = v ?? false),
                      side: const BorderSide(color: Color(0xFFB9BECC)),
                    ),
                    const Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'I agree to the Terms of Service and Privacy Policy.',
                          style: TextStyle(
                            color: Color(0xFF232A3A),
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
                          backgroundColor: const Color(0xFF072A73),
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
                            : const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 22 / 1.2,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      )
                    : FilledButton(
                        onPressed: isLoading ? null : _signInWithEmail,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          backgroundColor: const Color(0xFF072A73),
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
                            : const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 22 / 1.2,
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
                    icon: const Icon(Icons.smartphone, color: Color(0xFF576680)),
                    label: const Text(
                      'Continue with Phone Number',
                      style: TextStyle(color: Color(0xFF576680), fontSize: 22 / 1.2),
                    ),
                  ),
                ),
              if (!_isSignUp) ...[
                const SizedBox(height: 12),
                const _DividerText(label: 'OR CONTINUE WITH'),
              ],
              const SizedBox(height: 18),
              if (!_isSignUp)
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: 'New to Tutta? ',
                      style: const TextStyle(color: Color(0xFF3D4350), fontSize: 17),
                      children: [
                        WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: GestureDetector(
                            onTap: () => setState(() => _isSignUp = true),
                            child: const Text(
                              'Join the club',
                              style: TextStyle(
                                color: Color(0xFF072A73),
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
              if (_isSignUp)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Text(
                      '© 2024 TUTTA HOSPITALITY GROUP. ALL RIGHTS RESERVED.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF6F7483),
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
                      ),
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Continue with phone'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '+998901234567'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Continue'),
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
          color: Color(0xFF6B7080),
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
        color: const Color(0xFFF0F1F4),
        border: Border.all(color: const Color(0xFFCDD1D9)),
        borderRadius: BorderRadius.circular(2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Color(0xFFA8AEB8), fontSize: 22 / 1.2),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: suffixIcon == null
              ? null
              : IconButton(
                  onPressed: onSuffixTap,
                  icon: Icon(suffixIcon, color: const Color(0xFFA1A6B0)),
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
        const Expanded(child: Divider(color: Color(0xFFD9DDE5))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF7C8290),
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              fontSize: 12,
            ),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFD9DDE5))),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        side: const BorderSide(color: Color(0xFFBFC6D3)),
        backgroundColor: const Color(0xFFFBFCFE),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFF1B202A), size: 22),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF1B202A),
              fontSize: 34 / 2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
