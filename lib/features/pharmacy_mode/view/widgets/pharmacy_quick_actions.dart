// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';

/// Pharmacy Quick Actions Widget
/// 
/// Provides shortcuts to common pharmacy management tasks.
/// 
/// Performance Optimizations:
/// - Uses const constructors throughout
/// - Caches theme values to avoid repeated lookups
/// - Responsive grid via LayoutBuilder adapts to screen width
/// - Reduced shadow blur radius for better performance
/// - Text overflow prevention with ellipsis
class PharmacyQuickActions extends StatelessWidget {
  const PharmacyQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    // Cache theme values once at the start of build
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Responsive grid that adjusts to screen size
          LayoutBuilder(
            builder: (context, constraints) {
              final availableWidth = constraints.maxWidth;
              final isSmallScreen = availableWidth < 380;
              final childAspectRatio = isSmallScreen ? 1.6 : 1.8;
              
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: childAspectRatio,
                          child: const _QuickActionItem(
                            icon: Icons.add_circle_outline,
                            label: 'Add Post',
                            color: AppColors.primaryBlue,
                            actionName: 'Create Post',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: childAspectRatio,
                          child: const _QuickActionItem(
                            icon: Icons.inventory_2_outlined,
                            label: 'Manage Orders',
                            color: AppColors.primaryGreen,
                            actionName: 'Orders',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: childAspectRatio,
                          child: const _QuickActionItem(
                            icon: Icons.people_outline,
                            label: 'Admins',
                            color: AppColors.accentPurple,
                            actionName: 'Admins',
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: childAspectRatio,
                          child: const _QuickActionItem(
                            icon: Icons.analytics_outlined,
                            label: 'Analytics',
                            color: AppColors.accentYellow,
                            actionName: 'Analytics',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Individual quick action item widget
/// Uses const constructor and cached colors for optimal performance
class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String actionName;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.actionName,
  });

  void _handleTap(BuildContext context) {
    // TODO: Navigate to respective screens
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Navigate to $actionName')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Cache theme values once at the start of build
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? DarkColors.surface : LightColors.surface;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.1)
        : Colors.black.withOpacity(0.03);
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: GestureDetector(
        onTap: () => _handleTap(context),
        child: Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container with cached color
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
