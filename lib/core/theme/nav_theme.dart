import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Navigation theme constants
class NavTheme {
  NavTheme._();

  // Dimensions
  static const double navBarHeight = 60.0;
  static const double navBarElevation = 0;
  static const double fabSize = 52.0;
  static const double fabElevation = 8.0;
  static const double indicatorWidth = 50.0;
  static const double indicatorHeight = 3.0;
  static const double iconSize = 22.0;
  static const double activeLabelSize = 11.0;
  static const double inactiveLabelSize = 10.0;

  // Border radius
  static const double navBarRadius = 28.0;
  static const double fabRadius = AppRadius.md;

  // Animation durations
  static const Duration animationDuration = Duration(milliseconds: 150);
  static const Duration fabAnimationDuration = Duration(milliseconds: 200);
  static const Duration indicatorDuration = Duration(milliseconds: 150);

  // Haptic feedback
  static const bool enableHapticFeedback = true;

  // Padding
  static const EdgeInsets navBarPadding = EdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 14.0,
  );

  static const EdgeInsets itemPadding = EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 4.0,
  );
}
