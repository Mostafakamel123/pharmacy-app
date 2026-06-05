import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Premium color palette for the healthcare navigation system
class NavColors {
  NavColors._();

  // Primary medical gradient (now references AppColors)
  static const primaryGradient = AppColors.primaryGradient;

  static const primaryBlue = AppColors.primaryBlue;
  static const primaryCyan = AppColors.primaryCyan;
  static const primaryGreen = AppColors.primaryGreen;

  // Light mode colors
  static const navBackgroundLight = Color(0xFFFBFCFE);
  static const navSurfaceLight = Color(0xFFFFFFFF);
  static const iconInactiveLight = Color(0xFF94A3B8);
  static const labelInactiveLight = Color(0xFF64748B);
  static const shadowLight = Color(0x14000000);

  // Dark mode colors
  static const navBackgroundDark = Color(0xFF0F172A);
  static const navSurfaceDark = Color(0xFF1E293B);
  static const iconInactiveDark = Color(0xFF64748B);
  static const labelInactiveDark = Color(0xFF94A3B8);
  static const shadowDark = Color(0x40000000);

  // Glow effects - Enhanced
  static const glowColor = Color(0xFF0EA5E9);
  static const fabGradient = LinearGradient(
    colors: [
      Color(0xFF0EA5E9),
      Color(0xFF06B6D4),
    ],
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
