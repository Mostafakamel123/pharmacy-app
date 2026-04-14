import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/profile/model/profile_model.dart';

class QuickStats extends StatelessWidget {
  final UserProfileModel profile;

  const QuickStats({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? DarkColors.card : LightColors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: isDark ? DarkColors.divider : LightColors.divider,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.primaryBlue)
                  .withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StatItem(
              icon: Icons.article_rounded,
              value: profile.postsCount.toString(),
              label: 'Posts',
              color: AppColors.primaryBlue,
            ),
            Container(
              width: 1,
              height: 32,
              color: isDark ? DarkColors.divider : LightColors.divider,
            ),
            _StatItem(
              icon: Icons.chat_bubble_rounded,
              value: profile.repliesCount.toString(),
              label: 'Replies',
              color: AppColors.primaryGreen,
            ),
            Container(
              width: 1,
              height: 32,
              color: isDark ? DarkColors.divider : LightColors.divider,
            ),
            _StatItem(
              icon: Icons.bookmark_rounded,
              value: profile.savedCount.toString(),
              label: 'Saved',
              color: AppColors.accentYellow,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Icon(icon, size: 22, color: color),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? DarkColors.textHint : LightColors.textHint,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
