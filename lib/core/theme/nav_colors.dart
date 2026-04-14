import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';

/// Premium color palette for the healthcare navigation system
class NavColors {
  NavColors._();

  // Primary medical gradient (now references AppColors)
  static const primaryGradient = AppColors.primaryGradient;

  static const primaryBlue = AppColors.primaryBlue;
  static const primaryCyan = AppColors.primaryCyan;
  static const primaryGreen = AppColors.primaryGreen;

  // Light mode colors
  static const navBackgroundLight = Color(0xFFFAFAFA);
  static const navSurfaceLight = Color(0xFFFFFFFF);
  static const iconInactiveLight = Color(0xFF9CA3AF);
  static const labelInactiveLight = Color(0xFF6B7280);
  static const shadowLight = Color(0x1A000000);

  // Dark mode colors
  static const navBackgroundDark = Color(0xFF1F2937);
  static const navSurfaceDark = Color(0xFF374151);
  static const iconInactiveDark = Color(0xFF6B7280);
  static const labelInactiveDark = Color(0xFF9CA3AF);
  static const shadowDark = Color(0x40000000);

  // Glow effects
  static const glowColor = Color(0x400EA5E9);
  static const fabGradient = LinearGradient(
    colors: [AppColors.primaryBlue, AppColors.primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Indicator
  static const indicatorGradient = LinearGradient(
    colors: [AppColors.primaryCyan, AppColors.primaryBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
