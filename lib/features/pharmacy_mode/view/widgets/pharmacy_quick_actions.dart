import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';

/// Pharmacy Quick Actions Widget
/// 
/// Provides shortcuts to common pharmacy management tasks.
class PharmacyQuickActions extends StatelessWidget {
  const PharmacyQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
              color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
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
            children: [
              _QuickActionItem(
                icon: Icons.add_circle_outline,
                label: 'Add Post',
                color: AppColors.primaryBlue,
                onTap: () {
                  // TODO: Navigate to create post screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to Create Post')),
                  );
                },
              ),
              _QuickActionItem(
                icon: Icons.inventory_2_outlined,
                label: 'Manage Orders',
                color: AppColors.primaryGreen,
                onTap: () {
                  // TODO: Navigate to orders screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to Orders')),
                  );
                },
              ),
              _QuickActionItem(
                icon: Icons.people_outline,
                label: 'Admins',
                color: AppColors.accentPurple,
                onTap: () {
                  // TODO: Navigate to admins screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to Admins')),
                  );
                },
              ),
              _QuickActionItem(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                color: AppColors.accentYellow,
                onTap: () {
                  // TODO: Navigate to analytics screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Navigate to Analytics')),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? DarkColors.surface : LightColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
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
                color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
