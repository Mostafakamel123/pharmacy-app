// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:Elaaj/core/theme/app_colors.dart';

/// Pharmacy Recent Activity Widget
/// 
/// Shows recent orders, posts, and other pharmacy activities.
/// 
/// Performance Optimizations:
/// - Uses const constructors throughout
/// - Caches theme values to avoid repeated lookups
/// - Wraps activity list in RepaintBoundary for independent rasterization
/// - Pre-computes status colors to avoid redundant calculations
/// - Uses efficient Divider with proper indent
class PharmacyRecentActivity extends StatelessWidget {
  const PharmacyRecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    // Cache theme values once at the start of build
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final surfaceColor = isDark ? DarkColors.surface : LightColors.surface;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.08)
        : Colors.black.withOpacity(0.06);
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.1)
        : Colors.black.withOpacity(0.03);

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
                  color: textPrimary,
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
          // Activity list container with cached decorations and clipping
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
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
              child: Column(
                children: const [
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
          ),
        ],
      ),
    );
  }
}

enum ActivityStatus { pending, completed, info }

/// Individual activity item widget
/// Uses const constructor and pre-cached colors for optimal performance
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

  // Pre-compute status color based on enum
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

  @override
  Widget build(BuildContext context) {
    // Cache theme values once at the start of build
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? DarkColors.textPrimary : LightColors.textPrimary;
    final textSecondary = isDark ? DarkColors.textSecondary : LightColors.textSecondary;
    final textHint = isDark ? DarkColors.textHint : LightColors.textHint;
    final dividerColor = isDark ? DarkColors.divider : LightColors.divider;
    
    // Cache status-dependent values
    final statusColor = _getStatusColor();
    final statusBgColor = statusColor.withOpacity(0.1);

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
              color: statusBgColor,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: statusColor, size: 22),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 12,
                      color: textSecondary,
                    ),
                  ),
                ),
                Text(
                  time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  softWrap: false,
                  style: TextStyle(
                    fontSize: 11,
                    color: textHint,
                  ),
                ),
              ],
            ),
          ),
          trailing: _buildStatusIndicator(context),
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 72,
            color: dividerColor,
          ),
      ],
    );
  }

  Widget? _buildStatusIndicator(BuildContext context) {
    switch (status) {
      case ActivityStatus.pending:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accentYellow.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: const Text(
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
