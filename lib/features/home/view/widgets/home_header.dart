// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/home/controller/home_providers.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0C1B2A), const Color(0xFF132F3F), const Color(0xFF1A3B4F)]
              : [const Color(0xFFE0F2FE), const Color(0xFFDCFCE7), const Color(0xFFF0FDF4)],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xxl),
          bottomRight: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.primaryGreen)
                .withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left: Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Time-based greeting with icon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primaryBlue.withOpacity(0.15)
                              : AppColors.primaryGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getGreetingIcon(),
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF90CAF9)
                                  : AppColors.primaryGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF90CAF9)
                                    : AppColors.primaryGreen,
                                letterSpacing: -0.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Main greeting
                      Text(
                        'Hello, Mostafa',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.8,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Subtitle
                      Text(
                        'Find medicines بسهولة من أقرب صيدلية',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                          height: 1.4,
                          letterSpacing: -0.1,
                        ),
                      ),
                    ],
                  ),
                ),
                // Right: Actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        const _NotificationBadge(),
                        const SizedBox(width: 10),
                        // Profile avatar
                        GestureDetector(
                          onTap: () {},
                          child: Stack(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue.withOpacity(0.3),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              // Online indicator
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark
                                          ? const Color(0xFF0C1B2A)
                                          : LightColors.background,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Location pill
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.primaryBlue.withOpacity(0.12)
                            : Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: isDark
                              ? AppColors.primaryBlue.withOpacity(0.2)
                              : Colors.white,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.location_on_rounded,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF90CAF9)
                                : AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Mohandessin, Giza',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFF90CAF9)
                                  : AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: isDark
                                ? const Color(0xFF90CAF9)
                                : AppColors.primaryBlue,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }
}

class _NotificationBadge extends ConsumerWidget {
  const _NotificationBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationCount = ref.watch(notificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF1E3A4A) : LightColors.surface;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isDark ? const Color(0xFF2D4A5A) : const Color(0xFFF1F5F9),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_outlined,
            size: 22,
            color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF334155),
          ),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.accentRed,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF0C1B2A)
                      : LightColors.background,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
