// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/core/routing/app_routes.dart';

// Pharmacy-inspired color palette
const Color _primaryGreen = Color(0xFF1D9E75);
const Color _primaryBlue = Color(0xFF2B9FEA);
const Color _softBlue = Color(0xFF3AA8F7);
const Color _softGreen = Color(0xFF2DC689);
const Color _lightBg = Color(0xFFF5F9FF);

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _screens = [
    OnboardingData(
      headline: 'Find Nearby Pharmacies Easily',
      description: 'Discover pharmacies around you instantly using smart location-based search.',
      image: 'assets/onboarding/onboarding_1.png',
      gradientColors: [_primaryBlue, _softBlue],
      bgAccent: const Color(0xFFE8F4FD),
    ),
    OnboardingData(
      headline: 'Upload Prescriptions & Ask Anytime',
      description: 'Send your prescription or medical inquiry and get quick responses from trusted pharmacists.',
      image: 'assets/onboarding/onboarding_2.png',
      gradientColors: [_primaryGreen, _softGreen],
      bgAccent: const Color(0xFFE8F8F0),
    ),
    OnboardingData(
      headline: 'Connect with Trusted Pharmacists',
      description: 'Get expert advice and real-time communication from professional pharmacists.',
      image: 'assets/onboarding/onboarding_3.png',
      gradientColors: [_primaryBlue, _softGreen],
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
                ? [const Color(0xFF0A1628), const Color(0xFF0F2035)]
                : [_lightBg, const Color(0xFFFFFFFF)],
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
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Text(
                            'Elaaj',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _primaryGreen,
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

                  // PageView
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const ClampingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                      },
                      itemCount: _screens.length,
                      itemBuilder: (context, index) {
                        return OnboardingScreen(
                          data: _screens[index],
                          onNext: _nextPage,
                          onGetStarted: () {
                            context.go(AppRoutes.home);
                          },
                        );
                      },
                    ),
                  ),

                  // Page indicators
                  Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _screens.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          height: _currentPage == index ? 8 : 8,
                          width: _currentPage == index ? 28 : 8,
                          decoration: BoxDecoration(
                            gradient: _currentPage == index
                                ? const LinearGradient(
                                    colors: [_primaryGreen, _primaryBlue],
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

  OnboardingData({
    required this.headline,
    required this.description,
    required this.image,
    required this.gradientColors,
    required this.bgAccent,
  });
}

class OnboardingScreen extends StatelessWidget {
  final OnboardingData data;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;

  const OnboardingScreen({
    super.key,
    required this.data,
    required this.onNext,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLast = data.headline == 'Connect with Trusted Pharmacists';
    final textColor = isDark ? const Color(0xFFEEF2F7) : const Color(0xFF1A2B4A);
    final descColor = isDark ? const Color(0xFF8A96A8) : const Color(0xFF6B7D91);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Animated illustration container
          TweenAnimationBuilder<double>(
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

          // Button
          Container(
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
              onPressed: isLast ? onGetStarted : onNext,
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
                    isLast ? 'Get Started' : 'Next',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (!isLast) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 22),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
