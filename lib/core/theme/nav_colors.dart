import 'package:flutter/material.dart';

/// Premium color palette for the healthcare navigation system
class NavColors {
  NavColors._();

  // Primary medical gradient
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9), Color(0xFF10B981)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const primaryBlue = Color(0xFF0EA5E9);
  static const primaryCyan = Color(0xFF06B6D4);
  static const primaryGreen = Color(0xFF10B981);

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
    colors: [Color(0xFF0EA5E9), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Indicator
  static const indicatorGradient = LinearGradient(
    colors: [Color(0xFF06B6D4), Color(0xFF0EA5E9)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
