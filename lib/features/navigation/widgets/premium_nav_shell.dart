// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/core/utils/navigation_config.dart';
import 'package:Elaaj/features/navigation/widgets/floating_nav_button.dart';
import 'package:Elaaj/features/navigation/widgets/premium_nav_item.dart';
import 'package:Elaaj/core/theme/nav_colors.dart';
import 'package:Elaaj/core/theme/nav_theme.dart';
import 'package:Elaaj/features/posts/view/create_post_screen.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:Elaaj/features/home/controller/home_providers.dart';

/// Global provider for unified bottom navigation active index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Premium Navigation Shell
/// 
/// Unified navigation shell for all users.
/// No role-based navigation - single flow for everyone.
/// Now supports Pharmacy Mode with dynamic content switching.
class PremiumNavShell extends ConsumerStatefulWidget {
  final Widget? child;

  const PremiumNavShell({
    super.key,
    this.child,
  });

  @override
  ConsumerState<PremiumNavShell> createState() => _PremiumNavShellState();
}

class _PremiumNavShellState extends ConsumerState<PremiumNavShell>
    with TickerProviderStateMixin {
  int get _currentIndex => ref.watch(navigationIndexProvider);
  bool _isNavBarVisible = true;

  // Get navigation items from provider (reactive to mode changes)
  List<NavItem> get _navItems => UserNavItems.items(ref);

  // Always show FAB for normal users, hide in pharmacy mode
  bool get _showFab => !ref.watch(isPharmacyModeProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestLocationPermission();
    });
  }

  Future<void> _requestLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          ref.invalidate(locationProvider);
          ref.read(nearbyPharmaciesProvider.notifier).refresh();
        }
      }
    } catch (e) {
      debugPrint('Error requesting location permission on startup: $e');
    }
  }

  void _onTabChanged(int index) {
    ref.read(navigationIndexProvider.notifier).state = index;
  }

  void _onFabPressed() async {
    HapticFeedback.mediumImpact();
    await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const CreatePostScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Centralized listener to reset active navigation index to 0 when switching app modes
    ref.listen<PharmacyModeState>(pharmacyModeProvider, (previous, next) {
      if (previous?.currentMode != next.currentMode) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(navigationIndexProvider.notifier).state = 0;
        });
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => _ExitDialog(),
        );

        if (shouldExit == true) {
          await SystemNavigator.pop();
        }
      },
      child: Scaffold(
        extendBody: true,
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.reverse) {
              if (_isNavBarVisible) {
                setState(() => _isNavBarVisible = false);
              }
            } else if (notification.direction == ScrollDirection.forward) {
              if (!_isNavBarVisible) {
                setState(() => _isNavBarVisible = true);
              }
            }
            return false; // let the notification bubble further up
          },
          child: Stack(
            children: [
              if (widget.child != null) widget.child! else _buildCurrentScreen(),
              // Floating nav bar
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildFloatingNavigationBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    final isPharmacyMode = ref.watch(pharmacyModeProvider.select((s) => s.isPharmacyMode));
    return IndexedStack(
      index: _currentIndex,
      key: ValueKey(isPharmacyMode),
      children: [
        for (int i = 0; i < _navItems.length; i++)
          _navItems[i].builder(ref),
      ],
    );
  }

  Widget _buildFloatingNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: NavTheme.animationDuration,
      curve: Curves.easeInOut,
      height: _isNavBarVisible ? NavTheme.navBarHeight + 16 : 0,
      margin: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: _isNavBarVisible ? 12 : 0,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? NavColors.navBackgroundDark.withOpacity(0.95)
            : NavColors.navBackgroundLight.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, -8),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: isDark 
                ? AppColors.primaryBlue.withOpacity(0.1)
                : AppColors.primaryBlue.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  mainAxisSize: MainAxisSize.max,
                  children: _buildNavItemsRow(constraints.maxWidth),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavItemsRow(double maxWidth) {
    final items = <Widget>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final itemWidth =
        maxWidth / (_showFab ? (_navItems.length + 1) : _navItems.length);

    if (_showFab) {
      final halfIndex = _navItems.length ~/ 2;

      for (int i = 0; i < _navItems.length; i++) {
        if (i == halfIndex) {
          items.add(
            SizedBox(
              width: itemWidth,
              child: Center(
                child: FloatingNavButton(
                  onPressed: _onFabPressed,
                  isVisible: _isNavBarVisible,
                ),
              ),
            ),
          );
        }

        final isActive = _currentIndex == i;
        items.add(
          SizedBox(
            width: itemWidth,
            child: PremiumNavItem(
              item: _navItems[i],
              isActive: isActive,
              onTap: () => _onTabChanged(i),
              isDark: isDark,
            ),
          ),
        );
      }
    } else {
      for (int i = 0; i < _navItems.length; i++) {
        final isActive = _currentIndex == i;
        items.add(
          SizedBox(
            width: itemWidth,
            child: PremiumNavItem(
              item: _navItems[i],
              isActive: isActive,
              onTap: () => _onTabChanged(i),
              isDark: isDark,
            ),
          ),
        );
      }
    }

    return items;
  }
}

class _ExitDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      backgroundColor: isDark ? DarkColors.card : LightColors.card,
      title: const Text(
        'خروج من التطبيق',
        textAlign: TextAlign.right,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Text(
        'هل تريد الخروج من التطبيق فعلاً؟',
        textAlign: TextAlign.right,
        style: TextStyle(
          color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'لا',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accentRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
          ),
          child: const Text(
            'نعم',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
