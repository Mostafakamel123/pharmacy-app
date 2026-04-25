// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/core/utils/navigation_config.dart';
import 'package:pharmacy_app/features/navigation/widgets/floating_nav_button.dart';
import 'package:pharmacy_app/features/navigation/widgets/premium_nav_item.dart';
import 'package:pharmacy_app/core/theme/nav_colors.dart';
import 'package:pharmacy_app/core/theme/nav_theme.dart';
import 'package:pharmacy_app/features/posts/view/create_post_screen.dart';

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
  int _currentIndex = 0;
  bool _isNavBarVisible = true;
  final ScrollController _scrollController = ScrollController();

  // Get navigation items from provider (reactive to mode changes)
  List<NavItem> get _navItems => UserNavItems.items(ref);

  // Always show FAB for all users
  bool get _showFab => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isNavBarVisible) setState(() => _isNavBarVisible = false);
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isNavBarVisible) setState(() => _isNavBarVisible = true);
    }
  }

  void _onTabChanged(int index) {
    setState(() => _currentIndex = index);
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
    return Scaffold(
      extendBody: true,
      body: Stack(
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
    );
  }

  Widget _buildCurrentScreen() {
    if (_currentIndex < _navItems.length) {
      return _navItems[_currentIndex].builder(ref);
    }
    return const SizedBox.shrink();
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
