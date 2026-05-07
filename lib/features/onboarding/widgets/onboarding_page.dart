// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/core/routing/app_routes.dart';

// Pharmacy-inspired color palette - moved to constants to avoid recreation
class _OnboardingColors {
  static const primaryGreen = Color(0xFF1D9E75);
  static const primaryBlue = Color(0xFF2B9FEA);
  static const softBlue = Color(0xFF3AA8F7);
  static const softGreen = Color(0xFF2DC689);
  static const lightBg = Color(0xFFF5F9FF);
  static const darkBgStart = Color(0xFF0A1628);
  static const darkBgEnd = Color(0xFF0F2035);
  static const textColorLight = Color(0xFF1A2B4A);
  static const textColorDark = Color(0xFFEEF2F7);
  static const descColorLight = Color(0xFF6B7D91);
  static const descColorDark = Color(0xFF8A96A8);
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Static data - no need to recreate on every build
  static final List<OnboardingData> _screens = [
    OnboardingData(
      headline: 'Find Nearby Pharmacies Easily',
      description: 'Discover pharmacies around you instantly using smart location-based search.',
      image: 'assets/onboarding/onboarding_1.png',
      gradientColors: [_OnboardingColors.primaryBlue, _OnboardingColors.softBlue],
      bgAccent: const Color(0xFFE8F4FD),
    ),
    OnboardingData(
      headline: 'Upload Prescriptions & Ask Anytime',
      description: 'Send your prescription or medical inquiry and get quick responses from trusted pharmacists.',
      image: 'assets/onboarding/onboarding_2.png',
      gradientColors: [_OnboardingColors.primaryGreen, _OnboardingColors.softGreen],
      bgAccent: const Color(0xFFE8F8F0),
    ),
    OnboardingData(
      headline: 'Connect with Trusted Pharmacists',
      description: 'Get expert advice and real-time communication from professional pharmacists.',
      image: 'assets/onboarding/onboarding_3.png',
      gradientColors: [_OnboardingColors.primaryBlue, _OnboardingColors.softGreen],
      bgAccent: const Color(0xFFE8F4FD),
    ),
  ];

  void _nextPage() {
    if (_currentPage < _screens.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _skip() {
    _pageController.jumpToPage(_screens.length - 1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [_OnboardingColors.darkBgStart, _OnboardingColors.darkBgEnd]
                : [_OnboardingColors.lightBg, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Page content
              Column(
                children: [
                  // Skip button
                  Padding(
                    padding: const EdgeInsets.only(top: 12, right: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // App name small
                        const Padding(
                          padding: EdgeInsets.only(left: 24),
                          child: Text(
                            'Elaaj',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _OnboardingColors.primaryGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (_currentPage < _screens.length - 1)
                          TextButton(
                            onPressed: _skip,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            ),
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF7A8BA0),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // PageView - use builder with key for better performance
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: _screens.length,
                      itemBuilder: (context, index) {
                        return OnboardingScreenContent(
                          key: ValueKey('onboarding_page_$index'),
                          data: _screens[index],
                          isLastPage: index == _screens.length - 1,
                          onNext: _nextPage,
                          onGetStarted: () {
                            context.go(AppRoutes.login);
                          },
                        );
                      },
                    ),
                  ),

                  // Page indicators - wrapped in RepaintBoundary
                  RepaintBoundary(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _screens.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            height: 8,
                            width: _currentPage == index ? 28 : 8,
                            decoration: BoxDecoration(
                              gradient: _currentPage == index
                                  ? const LinearGradient(
                                      colors: [_OnboardingColors.primaryGreen, _OnboardingColors.primaryBlue],
                                    )
                                  : null,
                              color: _currentPage == index
                                  ? null
                                  : isDark
                                      ? const Color(0xFF2D3748)
                                      : const Color(0xFFD1D9E6),
                              borderRadius: BorderRadius.circular(6),
                            ),
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
      ),
    );
  }
}

class OnboardingData {
  final String headline;
  final String description;
  final String image;
  final List<Color> gradientColors;
  final Color bgAccent;

  const OnboardingData({
    required this.headline,
    required this.description,
    required this.image,
    required this.gradientColors,
    required this.bgAccent,
  });
}

// Optimized onboarding screen content widget - renamed to avoid confusion
class OnboardingScreenContent extends StatelessWidget {
  final OnboardingData data;
  final bool isLastPage;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;

  const OnboardingScreenContent({
    super.key,
    required this.data,
    required this.isLastPage,
    required this.onNext,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? _OnboardingColors.textColorDark : _OnboardingColors.textColorLight;
    final descColor = isDark ? _OnboardingColors.descColorDark : _OnboardingColors.descColorLight;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Animated illustration container with RepaintBoundary
          RepaintBoundary(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 600),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.85 + (0.15 * value),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(160),
                  boxShadow: [
                    BoxShadow(
                      color: data.gradientColors[0].withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: data.gradientColors[0].withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Image.asset(
                    data.image,
                    fit: BoxFit.contain,
                    width: 380,
                    height: 380,
                    // Add cache width/height for better memory management
                    cacheWidth: 380,
                    cacheHeight: 380,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 44),

          // Headline
          Text(
            data.headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: textColor,
              height: 1.25,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: descColor,
              height: 1.6,
              letterSpacing: 0.1,
            ),
          ),

          const Spacer(flex: 2),

          // Button - wrapped in RepaintBoundary
          RepaintBoundary(
            child: Container(
              width: double.infinity,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: data.gradientColors,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: data.gradientColors[0].withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: isLastPage ? onGetStarted : onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLastPage ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (!isLastPage) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 22),
                    ],
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
