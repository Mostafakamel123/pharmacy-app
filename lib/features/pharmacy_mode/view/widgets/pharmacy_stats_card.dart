import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';

/// Pharmacy Stats Card Widget
/// 
/// Displays key pharmacy metrics like orders, revenue, and ratings.
class PharmacyStatsCard extends StatelessWidget {
  const PharmacyStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.shopping_bag_outlined,
                  label: 'Orders',
                  value: '24',
                  trend: '+12%',
                  trendPositive: true,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatItem(
                  icon: Icons.pending_actions_outlined,
                  label: 'Pending',
                  value: '5',
                  trend: '-3%',
                  trendPositive: true,
                  color: AppColors.accentYellow,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _StatItem(
                  icon: Icons.star_outline_rounded,
                  label: 'Rating',
                  value: '4.8',
                  trend: '+0.2',
                  trendPositive: true,
                  color: AppColors.accentPurple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool trendPositive;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendPositive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: trendPositive
                  ? AppColors.primaryGreen.withOpacity(0.1)
                  : AppColors.accentRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              trend,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: trendPositive
                    ? AppColors.primaryGreen
                    : AppColors.accentRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
