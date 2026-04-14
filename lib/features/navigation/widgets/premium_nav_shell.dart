// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/core/utils/user_role.dart';
import 'package:pharmacy_app/core/utils/navigation_config.dart';
import 'package:pharmacy_app/features/navigation/widgets/floating_nav_button.dart';
import 'package:pharmacy_app/features/navigation/widgets/premium_nav_item.dart';
import 'package:pharmacy_app/core/theme/nav_colors.dart';
import 'package:pharmacy_app/core/theme/nav_theme.dart';

/// Premium Navigation Shell
class PremiumNavShell extends StatefulWidget {
  final UserRole userRole;
  final Widget? child;

  const PremiumNavShell({
    super.key,
    required this.userRole,
    this.child,
  });

  @override
  State<PremiumNavShell> createState() => _PremiumNavShellState();
}

class _PremiumNavShellState extends State<PremiumNavShell>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isNavBarVisible = true;
  final ScrollController _scrollController = ScrollController();

  List<NavItem> get _navItems =>
      widget.userRole == UserRole.patient
          ? PatientNavItems.items
          : PharmacyNavItems.items;

  bool get _showFab => widget.userRole == UserRole.patient;

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

  void _onFabPressed() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Create new post'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
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
        ],
      ),
      bottomSheet: _buildNavigationBar(),
    );
  }

  Widget _buildCurrentScreen() {
    if (_currentIndex < _navItems.length) {
      return _navItems[_currentIndex].builder();
    }
    return const SizedBox.shrink();
  }

  Widget _buildNavigationBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: NavTheme.animationDuration,
      curve: Curves.easeInOut,
      height: _isNavBarVisible ? NavTheme.navBarHeight + 20 : 0,
      decoration: BoxDecoration(
        color: isDark
            ? NavColors.navBackgroundDark.withOpacity(0.9)
            : NavColors.navBackgroundLight.withOpacity(0.9),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(NavTheme.navBarRadius),
          topRight: Radius.circular(NavTheme.navBarRadius),
        ),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? NavColors.shadowDark : NavColors.shadowLight,
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(NavTheme.navBarRadius),
          topRight: Radius.circular(NavTheme.navBarRadius),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
