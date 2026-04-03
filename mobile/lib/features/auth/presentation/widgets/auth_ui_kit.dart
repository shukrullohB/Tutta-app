import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

abstract final class AuthPalette {
  static const background = Color(0xFFFFFFFF);
  static const headerBorder = Color(0xFFE7EBF2);
  static const panel = Colors.white;
  static const panelBorder = Color(0xFFE6EAF2);
  static const primary = Color(0xFF0A2F73);
  static const primarySoft = Color(0xFFEAF0FF);
  static const text = Color(0xFF10244A);
  static const textMuted = Color(0xFF7A8497);
  static const input = Color(0xFFF2F4F8);
  static const inputBorder = Color(0xFFE3E8F1);
  static const danger = Color(0xFFB83D3D);
}

abstract final class AuthSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.leading,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final hasKeyboard = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -80,
              right: -60,
              child: IgnorePointer(
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AuthPalette.primary.withAlpha(40),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: -70,
              bottom: -90,
              child: IgnorePointer(
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [Color(0x2AB9D7FF), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(
                    AuthSpacing.xl,
                    AuthSpacing.sm,
                    AuthSpacing.xl,
                    AuthSpacing.sm,
                  ),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: AuthPalette.headerBorder),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (leading != null)
                        leading!
                      else
                        const SizedBox(width: 24, height: 24),
                      const Expanded(
                        child: Text(
                          'Tutta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AuthPalette.text,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      if (trailing != null)
                        trailing!
                      else
                        const SizedBox(width: 24, height: 24),
                    ],
                  ),
                ).animate().fadeIn(duration: 260.ms),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      AuthSpacing.xl,
                      hasKeyboard ? AuthSpacing.sm : AuthSpacing.md,
                      AuthSpacing.xl,
                      AuthSpacing.xxl,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                  title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: AuthPalette.text,
                                        fontWeight: FontWeight.w700,
                                        height: 1.05,
                                        fontSize: 52,
                                      ),
                                )
                                .animate()
                                .fadeIn(duration: 260.ms)
                                .slideY(begin: 0.08, end: 0),
                            const SizedBox(height: AuthSpacing.xs),
                            Text(
                                  subtitle,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AuthPalette.textMuted),
                                )
                                .animate(delay: 70.ms)
                                .fadeIn(duration: 240.ms)
                                .slideY(begin: 0.06, end: 0),
                            const SizedBox(height: AuthSpacing.lg),
                            Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(AuthSpacing.md),
                                  decoration: BoxDecoration(
                                    color: AuthPalette.panel.withAlpha(238),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: AuthPalette.panelBorder,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x140A2F73),
                                        blurRadius: 32,
                                        offset: Offset(0, 14),
                                      ),
                                    ],
                                  ),
                                  child: child,
                                )
                                .animate(delay: 120.ms)
                                .fadeIn(duration: 280.ms)
                                .slideY(begin: 0.08, end: 0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.labelText,
    this.keyboardType,
    this.maxLength,
    this.counterText,
  });

  final TextEditingController controller;
  final String hintText;
  final String? labelText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? counterText;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      style: const TextStyle(color: AuthPalette.text),
      cursorColor: AuthPalette.primary,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        counterText: counterText,
        hintStyle: const TextStyle(color: AuthPalette.textMuted),
        labelStyle: const TextStyle(color: AuthPalette.textMuted),
        filled: true,
        fillColor: AuthPalette.input,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AuthSpacing.md,
          vertical: 16,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthPalette.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthPalette.primary),
        ),
      ),
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AuthPalette.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF9FA9BD),
          disabledForegroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(label),
      ),
    );
  }
}

class AuthGoogleButton extends StatelessWidget {
  const AuthGoogleButton({
    super.key,
    required this.onPressed,
    this.loading = false,
  });

  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: AuthPalette.inputBorder),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          foregroundColor: AuthPalette.primary,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleGlyph(),
                  SizedBox(width: AuthSpacing.sm),
                  Text(
                    'Continue with Google',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
      ),
    );
  }
}

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, this.label = 'OR CONTINUE WITH'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Divider(color: AuthPalette.headerBorder, thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            label,
            style: const TextStyle(
              color: AuthPalette.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.3,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: AuthPalette.headerBorder, thickness: 1),
        ),
      ],
    );
  }
}

class AuthBanner extends StatelessWidget {
  const AuthBanner.error(this.message, {super.key}) : isError = true;

  const AuthBanner.info(this.message, {super.key}) : isError = false;

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AuthPalette.danger : AuthPalette.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AuthSpacing.md,
        vertical: AuthSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _GoogleGlyph extends StatelessWidget {
  const _GoogleGlyph();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AuthPalette.inputBorder),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
