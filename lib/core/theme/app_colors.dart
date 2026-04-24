import 'package:flutter/material.dart';

/// Primary brand colors
class AppColors {
  AppColors._();

  // Primary gradient - Medical cyan to green
  static const primaryGradient = LinearGradient(
    colors: [primaryCyan, primaryBlue, primaryGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const primaryCyan = Color(0xFF06B6D4);
  static const primaryBlue = Color(0xFF0EA5E9);
  static const primaryGreen = Color(0xFF10B981);

  // Accents
  static const accentYellow = Color(0xFFF59E0B);
  static const accentRed = Color(0xFFEF4444);
  static const accentPurple = Color(0xFF8B5CF6);
}

/// Light theme colors
class LightColors {
  LightColors._();

  static const background = Color(0xFFF9FAFB);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF3F4F6);
  static const card = Color(0xFFFFFFFF);
  static const divider = Color(0xFFE5E7EB);

  // Text
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);

  // Shadows
  static const shadow = Color(0x0A000000);
  static const shadowLight = Color(0x06000000);
}

/// Dark theme colors
class DarkColors {
  DarkColors._();

  static const background = Color(0xFF111827);
  static const surface = Color(0xFF1F2937);
  static const surfaceVariant = Color(0xFF374151);
  static const card = Color(0xFF1F2937);
  static const divider = Color(0xFF374151);

  // Text
  static const textPrimary = Color(0xFFF9FAFB);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textHint = Color(0xFF6B7280);

  // Shadows
  static const shadow = Color(0x30000000);
  static const shadowLight = Color(0x20000000);
}

/// Border radius constants
class AppRadius {
  AppRadius._();

  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;
}

/// Spacing constants
class AppSpacing {
  AppSpacing._();

  static const double xxs = 4;
  static const double xs = 6;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
}

/// Typography constants
class AppTypography {
  AppTypography._();

  static const h1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );

  static const h2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
  );

  static const h3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.2,
  );

  static const subtitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const small = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
  );
}
