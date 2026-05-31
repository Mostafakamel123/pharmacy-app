// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/core/routing/app_routes.dart';
import 'package:pharmacy_app/core/constants/app_constants.dart';
import 'package:pharmacy_app/core/helpers/local_storage_helper.dart';

// Pharmacy-inspired color palette
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
  
  // Pre-defined constant gradients to avoid object recreation in builds
  static const lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_OnboardingColors.lightBg, Colors.white],
  );

  static const darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [_OnboardingColors.darkBgStart, _OnboardingColors.darkBgEnd],
  );

  static const indicatorGradient = LinearGradient(
    colors: [primaryGreen, primaryBlue],
  );
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
  static const List<OnboardingData> _screens = [
    OnboardingData(
      headline: 'Find Nearby Pharmacies Easily',
      description: 'Discover pharmacies around you instantly using smart location-based search.',
      image: 'assets/onboarding/onboarding_1.png',
      gradientColors: [_OnboardingColors.primaryBlue, _OnboardingColors.softBlue],
      bgAccent: Color(0xFFE8F4FD),
    ),
    OnboardingData(
      headline: 'Upload Prescriptions & Ask Anytime',
      description: 'Send your prescription or medical inquiry and get quick responses from trusted pharmacists.',
      image: 'assets/onboarding/onboarding_2.png',
      gradientColors: [_OnboardingColors.primaryGreen, _OnboardingColors.softGreen],
      bgAccent: Color(0xFFE8F4FD),
    ),
    OnboardingData(
      headline: 'Connect with Trusted Pharmacists',
      description: 'Get expert advice and real-time communication from professional pharmacists.',
      image: 'assets/onboarding/onboarding_3.png',
      gradientColors: [_OnboardingColors.primaryBlue, _OnboardingColors.softGreen],
      bgAccent: Color(0xFFE8F4FD),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? _OnboardingColors.darkGradient : _OnboardingColors.lightGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip button row - extracted to minimize rebuild range
              _OnboardingHeader(
                isDark: isDark,
                currentPage: _currentPage,
                onSkip: _skip,
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
                    return OnboardingScreenContent(
                      key: ValueKey('onboarding_page_$index'),
                      data: _screens[index],
                      isLastPage: index == _screens.length - 1,
                      onNext: _nextPage,
                      onGetStarted: () async {
                        await LocalStorageHelper.setBool(AppConstants.onboardingCompleteKey, true);
                        if (context.mounted) {
                          context.go(AppRoutes.login);
                        }
                      },
                    );
                  },
                ),
              ),

              // Page indicators - RepaintBoundary prevents painting over unrelated widgets
              RepaintBoundary(
                child: _OnboardingIndicatorRow(
                  currentPage: _currentPage,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}

// Extracted Header Widget
class _OnboardingHeader extends StatelessWidget {
  final bool isDark;
  final int currentPage;
  final VoidCallback onSkip;

  const _OnboardingHeader({
    required this.isDark,
    required this.currentPage,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, right: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
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
          if (currentPage < 2)
            TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF7A8BA0),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Extracted Indicator Widget
class _OnboardingIndicatorRow extends StatelessWidget {
  final int currentPage;
  final bool isDark;

  const _OnboardingIndicatorRow({
    required this.currentPage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (index) => _OnboardingDot(
          key: ValueKey(index),
          index: index,
          currentPage: currentPage,
          isDark: isDark,
        ),
      ),
    );
  }
}

// Extracted individual indicator dot
class _OnboardingDot extends StatelessWidget {
  final int index;
  final int currentPage;
  final bool isDark;

  const _OnboardingDot({
    super.key,
    required this.index,
    required this.currentPage,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = currentPage == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: const EdgeInsets.symmetric(horizontal: 5),
      height: 8,
      width: isActive ? 28 : 8,
      decoration: BoxDecoration(
        gradient: isActive ? _OnboardingColors.indicatorGradient : null,
        color: isActive ? null : (isDark ? const Color(0xFF2D3748) : const Color(0xFFD1D9E6)),
        borderRadius: BorderRadius.circular(6),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    
                    // Animated illustration container
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
                        child: _OnboardingIllustration(data: data),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Headline
                    Text(
                      data.headline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                        height: 1.25,
                        letterSpacing: -0.3,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Description
                    Text(
                      data.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: descColor,
                        height: 1.5,
                        letterSpacing: 0.1,
                      ),
                    ),
                    
                    const Spacer(flex: 1),
                    const SizedBox(height: 24),
                    
                    // Button
                    RepaintBoundary(
                      child: _OnboardingButton(
                        isLastPage: isLastPage,
                        gradientColors: data.gradientColors,
                        onNext: onNext,
                        onGetStarted: onGetStarted,
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Extracted illustration to be used as the `child` of TweenAnimationBuilder
class _OnboardingIllustration extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingIllustration({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          cacheWidth: 380,
          cacheHeight: 380,
        ),
      ),
    );
  }
}

// Extracted Button widget
class _OnboardingButton extends StatelessWidget {
  final bool isLastPage;
  final List<Color> gradientColors;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;

  const _OnboardingButton({
    required this.isLastPage,
    required this.gradientColors,
    required this.onNext,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradientColors),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withOpacity(0.35),
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
    );
  }
}