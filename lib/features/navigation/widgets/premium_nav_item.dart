// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/core/theme/nav_colors.dart';
import 'package:pharmacy_app/core/theme/nav_theme.dart';
import 'package:pharmacy_app/core/utils/navigation_config.dart';

/// Premium Navigation Item Widget
class PremiumNavItem extends StatefulWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const PremiumNavItem({
    super.key,
    required this.item,
    required this.isActive,
    required this.onTap,
    required this.isDark,
  });

  @override
  State<PremiumNavItem> createState() => _PremiumNavItemState();
}

class _PremiumNavItemState extends State<PremiumNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PremiumNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive && widget.isActive) {
      _triggerBounce();
    }
  }

  void _triggerBounce() {
    _animationController.forward().then((_) => _animationController.reverse());
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse().then((_) => widget.onTap());
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = widget.isActive
        ? null
        : widget.isDark
            ? NavColors.iconInactiveDark
            : NavColors.iconInactiveLight;

    final labelColor = widget.isActive
        ? AppColors.primaryBlue
        : widget.isDark
            ? NavColors.labelInactiveDark
            : NavColors.labelInactiveLight;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.translucent,
      child: AnimatedContainer(
        duration: NavTheme.animationDuration,
        curve: Curves.easeInOut,
        padding: NavTheme.itemPadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: NavTheme.animationDuration,
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: _buildIcon(iconColor),
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              duration: NavTheme.animationDuration,
              opacity: widget.isActive ? 1.0 : 0.0,
              child: AnimatedDefaultTextStyle(
                duration: NavTheme.animationDuration,
                style: TextStyle(
                  fontSize: widget.isActive
                      ? NavTheme.activeLabelSize
                      : NavTheme.inactiveLabelSize,
                  fontWeight:
                      widget.isActive ? FontWeight.w600 : FontWeight.w500,
                  color: labelColor,
                ),
                child: Text(
                  widget.item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(Color? iconColor) {
    final icon = widget.isActive ? widget.item.activeIcon : widget.item.icon;

    if (widget.isActive) {
      return ShaderMask(
        key: ValueKey('active_${widget.item.label}'),
        shaderCallback: (bounds) =>
            NavColors.primaryGradient.createShader(
              Rect.fromLTWH(0, 0, bounds.width, bounds.height),
            ),
        child: Icon(
          icon,
          size: NavTheme.iconSize,
          color: Colors.white,
        ),
      );
    } else {
      return Icon(
        icon,
        key: ValueKey('inactive_${widget.item.label}'),
        size: NavTheme.iconSize,
        color: iconColor,
      );
    }
  }
}
