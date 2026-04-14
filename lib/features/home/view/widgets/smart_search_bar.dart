import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';

class SmartSearchBar extends StatelessWidget {
  const SmartSearchBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? DarkColors.surface : LightColors.surface;
    final divider = isDark ? DarkColors.divider : LightColors.divider;
    final iconColor = isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue;
    final hintColor = isDark ? DarkColors.textHint : LightColors.textHint;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppColors.primaryBlue)
                  .withOpacity(isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search for pharmacy, medicine...',
            hintStyle: TextStyle(color: hintColor, fontSize: AppTypography.body.fontSize),
            prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 24),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 1, height: 24, color: divider),
                IconButton(
                  icon: Icon(Icons.tune_rounded, color: iconColor),
                  onPressed: () {},
                ),
                Container(width: 1, height: 24, color: divider),
                IconButton(
                  icon: Icon(Icons.mic_none_rounded, color: iconColor),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
              ],
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}
