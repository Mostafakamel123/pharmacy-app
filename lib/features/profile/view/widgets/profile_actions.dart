import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';

class ProfileSection extends StatelessWidget {
  final String title;
  final List<ProfileActionItem> items;

  const ProfileSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          Container(
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
                      .withOpacity(isDark ? 0.15 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: items.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                return Column(
                  children: [
                    ProfileActionTile(item: item),
                    if (index < items.length - 1)
                      Padding(
                        padding: const EdgeInsets.only(left: 52),
                        child: Divider(
                          height: 1,
                          color: isDark
                              ? DarkColors.divider
                              : LightColors.divider,
                        ),
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileActionItem {
  final String title;
  final IconData icon;
  final Color iconColor;
  final IconData trailingIcon;
  final bool isToggle;
  final bool? toggleValue;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;

  const ProfileActionItem({
    required this.title,
    required this.icon,
    this.iconColor = AppColors.primaryBlue,
    this.trailingIcon = Icons.chevron_right_rounded,
    this.isToggle = false,
    this.toggleValue,
    this.onTap,
    this.onToggle,
  });
}

class ProfileActionTile extends StatelessWidget {
  final ProfileActionItem item;

  const ProfileActionTile({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: item.isToggle ? null : item.onTap,
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: item.iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Icon(
            item.icon,
            size: 20,
            color: item.iconColor,
          ),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
          ),
        ),
        trailing: item.isToggle
            ? Switch.adaptive(
                value: item.toggleValue ?? false,
                onChanged: item.onToggle,
                activeColor: AppColors.primaryGreen,
              )
            : Icon(
                item.trailingIcon,
                size: 20,
                color: isDark ? DarkColors.textHint : LightColors.textHint,
              ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
