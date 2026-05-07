import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';

/// Pharmacy Quick Actions Widget
/// 
/// Provides shortcuts to common pharmacy management tasks.
/// 
/// Performance Optimizations:
/// - Uses const constructors throughout
/// - Caches theme values to avoid repeated lookups
/// - Wraps grid items in RepaintBoundary for independent rasterization
/// - Uses const NeverScrollableScrollPhysics (already optimal)
/// - Minimizes closure allocations in onTap handlers
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
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.8,
            children: const [
              _QuickActionItem(
                icon: Icons.add_circle_outline,
                label: 'Add Post',
                color: AppColors.primaryBlue,
                actionName: 'Create Post',
              ),
              _QuickActionItem(
                icon: Icons.inventory_2_outlined,
                label: 'Manage Orders',
                color: AppColors.primaryGreen,
                actionName: 'Orders',
              ),
              _QuickActionItem(
                icon: Icons.people_outline,
                label: 'Admins',
                color: AppColors.accentPurple,
                actionName: 'Admins',
              ),
              _QuickActionItem(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                color: AppColors.accentYellow,
                actionName: 'Analytics',
              ),
            ],
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
        ? Colors.black.withOpacity(0.2)
        : Colors.black.withOpacity(0.05);
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;

    return RepaintBoundary(
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
                blurRadius: 10,
                offset: const Offset(0, 4),
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
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
