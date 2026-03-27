import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../home/application/app_session_controller.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;
  int _currentIndex = 0;

  static const _slides = [
    _OnboardingSlide(
      title: 'Find Your Perfect Stay',
      subtitle:
          'Discover unique homes and rooms for short stays, from 1 day up to 1 month.',
      heroAssetPath: 'assets/images/start1.png',
      heroTitle: 'CURATED COLLECTION',
      heroValue: 'The Tutta Selection',
      heroIcon: Icons.verified_rounded,
      heroTop: Color(0xFF6B9CC7),
      heroBottom: Color(0xFF1D5A87),
    ),
    _OnboardingSlide(
      title: 'Booking Made Simple',
      subtitle:
          'Secure your reservation in just a few clicks with our fast and safe payment options.',
      heroAssetPath: 'assets/images/start2.png',
      heroTitle: 'SELECT DATES',
      heroValue: 'Oct 12 - Oct 18',
      heroIcon: Icons.calendar_month_rounded,
      heroTop: Color(0xFFE7ECF4),
      heroBottom: Color(0xFFD6DEE9),
    ),
    _OnboardingSlide(
      title: 'Unlock Premium Stays with Your Skills',
      subtitle:
          'Exchange your expertise in design, photography, or language for a free stay with verified hosts.',
      heroTitle: 'SKILL VERIFIED',
      heroValue: 'Photography',
      heroIcon: Icons.camera_alt_rounded,
      heroTop: Color(0xFFCFD3A9),
      heroBottom: Color(0xFFACB17D),
      showStep: true,
      stepLabel: 'STEP 03 / 03',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(appSessionControllerProvider.notifier).completeOnboarding();
    context.go(RouteNames.auth);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];
    final isLast = _currentIndex == _slides.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3B4152),
                    ),
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) => _OnboardingPage(slide: _slides[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final selected = index == _currentIndex;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: selected ? 54 : 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFF072A73)
                              : const Color(0xFFD9DCE3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        if (isLast) {
                          _finish();
                          return;
                        }
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        );
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(58),
                        backgroundColor: const Color(0xFF072A73),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        isLast ? 'Get Started' : 'Next  ->',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      slide.showStep ? 'Tell me more about the exchange' : 'SKIP',
                      style: const TextStyle(
                        color: Color(0xFF3A4355),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.title,
    required this.subtitle,
    this.heroAssetPath,
    required this.heroTitle,
    required this.heroValue,
    required this.heroIcon,
    required this.heroTop,
    required this.heroBottom,
    this.showStep = false,
    this.stepLabel,
  });

  final String title;
  final String subtitle;
  final String? heroAssetPath;
  final String heroTitle;
  final String heroValue;
  final IconData heroIcon;
  final Color heroTop;
  final Color heroBottom;
  final bool showStep;
  final String? stepLabel;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 700;
        final heroHeight = (constraints.maxHeight * (isCompact ? 0.5 : 0.58))
            .clamp(250.0, 380.0);
        final titleFontSize = isCompact ? 24.0 : 29.0;
        final subtitleFontSize = isCompact ? 18.0 : 21.0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
          child: Column(
            children: [
              SizedBox(height: isCompact ? 4 : 8),
              SizedBox(
                height: heroHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(36),
                      child: slide.heroAssetPath != null
                          ? Image.asset(slide.heroAssetPath!, fit: BoxFit.cover)
                          : DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [slide.heroTop, slide.heroBottom],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                  padding: const EdgeInsets.fromLTRB(14, 12, 16, 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF072A73),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(color: const Color(0x22000000)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFF3CD8D),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          slide.heroIcon,
                                          color: const Color(0xFF251700),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              slide.heroTitle,
                                              style: const TextStyle(
                                                color: Color(0xFFBFD0EF),
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              slide.heroValue,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(36),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 26,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 280.ms)
                  .slideY(begin: 0.07, end: 0, curve: Curves.easeOutCubic),
              SizedBox(height: isCompact ? 10 : 22),
              if (slide.showStep)
                Text(
                  slide.stepLabel ?? '',
                  style: TextStyle(
                    color: const Color(0xFF072A73),
                    fontWeight: FontWeight.w700,
                    letterSpacing: isCompact ? 2.2 : 3,
                    fontSize: isCompact ? 13 : 15,
                  ),
                ).animate().fadeIn(duration: 180.ms),
              if (slide.showStep) SizedBox(height: isCompact ? 4 : 8),
              Text(
                slide.title,
                maxLines: isCompact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF072A73),
                  height: 1.06,
                ),
              ).animate(delay: 80.ms).fadeIn(duration: 220.ms),
              SizedBox(height: isCompact ? 8 : 14),
              Text(
                slide.subtitle,
                maxLines: isCompact ? 2 : 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: subtitleFontSize,
                  color: const Color(0xFF3A4355),
                  height: 1.35,
                ),
              ).animate(delay: 120.ms).fadeIn(duration: 220.ms),
            ],
          ),
        );
      },
    );
  }
}
