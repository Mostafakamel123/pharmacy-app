import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';

/// Pharmacy Recent Activity Widget
/// 
/// Shows recent orders, posts, and other pharmacy activities.
class PharmacyRecentActivity extends StatelessWidget {
  const PharmacyRecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color:
                      isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: View all activity
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
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
                _ActivityItem(
                  icon: Icons.shopping_bag_rounded,
                  title: 'New Order #1234',
                  subtitle: 'Paracetamol 500mg - 2 boxes',
                  time: '5 min ago',
                  status: ActivityStatus.pending,
                  isLast: false,
                ),
                _ActivityItem(
                  icon: Icons.check_circle_rounded,
                  title: 'Order #1230 Completed',
                  subtitle: 'Delivered successfully',
                  time: '1 hour ago',
                  status: ActivityStatus.completed,
                  isLast: false,
                ),
                _ActivityItem(
                  icon: Icons.article_rounded,
                  title: 'New Post Published',
                  subtitle: 'Health tips for winter season',
                  time: '3 hours ago',
                  status: ActivityStatus.info,
                  isLast: false,
                ),
                _ActivityItem(
                  icon: Icons.people_rounded,
                  title: 'New Admin Added',
                  subtitle: 'Dr. Ahmed joined as admin',
                  time: '1 day ago',
                  status: ActivityStatus.info,
                  isLast: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum ActivityStatus { pending, completed, info }

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final ActivityStatus status;
  final bool isLast;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.status,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: _getStatusColor(), size: 22),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? DarkColors.textSecondary
                          : LightColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark ? DarkColors.textHint : LightColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          trailing: _buildStatusIndicator(),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 72,
            color: isDark ? DarkColors.divider : LightColors.divider,
          ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case ActivityStatus.pending:
        return AppColors.accentYellow;
      case ActivityStatus.completed:
        return AppColors.primaryGreen;
      case ActivityStatus.info:
        return AppColors.primaryBlue;
    }
  }

  Widget? _buildStatusIndicator() {
    switch (status) {
      case ActivityStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accentYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            'Pending',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.accentYellow,
            ),
          ),
        );
      case ActivityStatus.completed:
        return null;
      case ActivityStatus.info:
        return null;
    }
  }
}
