// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:Elaaj/core/theme/nav_colors.dart';
import 'package:Elaaj/core/theme/nav_theme.dart';

/// Floating Action Button for center navigation
class FloatingNavButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isVisible;

  const FloatingNavButton({
    super.key,
    this.onPressed,
    this.isVisible = true,
  });

  @override
  State<FloatingNavButton> createState() => _FloatingNavButtonState();
}

class _FloatingNavButtonState extends State<FloatingNavButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _animationController.forward();
  void _onTapUp(TapUpDetails details) =>
      _animationController.reverse().then((_) => widget.onPressed?.call());
  void _onTapCancel() => _animationController.reverse();

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: NavTheme.fabAnimationDuration,
      curve: Curves.easeInOut,
      width: widget.isVisible ? NavTheme.fabSize : 0,
      height: widget.isVisible ? NavTheme.fabSize : 0,
      child: AnimatedOpacity(
        duration: NavTheme.fabAnimationDuration,
        opacity: widget.isVisible ? 1.0 : 0.0,
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    NavColors.glowColor.withOpacity(0.9),
                    NavColors.glowColor.withOpacity(0.7),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: NavColors.glowColor.withOpacity(0.25),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular((NavTheme.fabSize + 8) / 2),
                  onTap: widget.onPressed,
                  child: Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
