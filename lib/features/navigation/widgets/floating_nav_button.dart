import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/core/theme/nav_colors.dart';
import 'package:pharmacy_app/core/theme/nav_theme.dart';

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
      duration: NavTheme.fabAnimationDuration,
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
                gradient: NavColors.fabGradient,
                boxShadow: [
                  BoxShadow(
                    color: NavColors.glowColor,
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(NavTheme.fabSize / 2),
                  onTap: widget.onPressed,
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 32,
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
