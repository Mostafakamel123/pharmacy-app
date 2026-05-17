// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/features/home/controller/home_providers.dart';

class HomeHeader extends ConsumerWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Compute hour once instead of calling DateTime.now() in two separate methods
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';
    final greetingIcon = hour < 12
        ? Icons.wb_sunny_rounded
        : hour < 17
            ? Icons.wb_cloudy_rounded
            : Icons.nights_stay_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF0C1B2A),
                  Color(0xF2132F3F), // replaced withOpacity(0.95)
                  Color(0xE61A3B4F), // replaced withOpacity(0.9)
                ]
              : const [
                  Color(0xFFF0FAFE),
                  Color(0xFFE5F9F3),
                  Color(0xFFF5FEF9),
                ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0x33000000) // black @ 0.2
                : const Color(0x0F0EA5E9), // blue @ 0.06
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Row 1: Actions & Time-based Greeting
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderIconButton(
                  icon: Icons.menu_rounded,
                  onTap: () => Scaffold.of(context).openDrawer(),
                  isDark: isDark,
                ),
                // Compact Time-based greeting
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0x1F0EA5E9) // replaced withOpacity(0.12)
                        : const Color(0x1410B981), // replaced withOpacity(0.08)
                    borderRadius:
                        const BorderRadius.all(Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        greetingIcon,
                        size: 12,
                        color: isDark
                            ? const Color(0xFF38BDF8)
                            : const Color(0xFF10B981),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        greeting,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
                const _NotificationBadge(),
              ],
            ),
            const SizedBox(height: 16),
            // Row 2: Name & Location (Compact)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Mostafa Kamel',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                const _LocationPill(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _HeaderIconButton({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0x1A0EA5E9) // replaced withOpacity(0.1)
              : const Color(0xE6FFFFFF), // replaced white.withOpacity(0.9)
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            color: isDark
                ? const Color(0x330EA5E9) // replaced withOpacity(0.2)
                : const Color(0xFFE8F5E9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x1A000000) // black @ 0.1
                  : const Color(0x0F0EA5E9), // blue @ 0.06
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9),
        ),
      ),
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0x1A0EA5E9) // replaced withOpacity(0.1)
            : const Color(0xD9FFFFFF), // replaced white.withOpacity(0.85)
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(
          color: isDark
              ? const Color(0x330EA5E9) // replaced withOpacity(0.2)
              : const Color(0xFFE8F5E9),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000), // replaced black.withOpacity(0.02)
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 13.5,
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9),
          ),
          const SizedBox(width: 5),
          Text(
            'Assiut',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0F172A),
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 13.5,
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9),
          ),
        ],
      ),
    );
  }
}

class _NotificationBadge extends ConsumerWidget {
  const _NotificationBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationCount = ref.watch(notificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0x1A0EA5E9) // replaced withOpacity(0.1)
                : const Color(0xE6FFFFFF), // replaced white.withOpacity(0.9)
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: isDark
                  ? const Color(0x330EA5E9) // replaced withOpacity(0.2)
                  : const Color(0xFFE8F5E9),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0x1A000000) // black @ 0.1
                    : const Color(0x0F0EA5E9), // blue @ 0.06
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: isDark
                ? const Color(0xFF38BDF8)
                : const Color(0xFF0EA5E9),
          ),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              width: 18,
              height: 18,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x66EF4444), // replaced withOpacity(0.4)
                    blurRadius: 6,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  notificationCount > 9
                      ? '9+'
                      : notificationCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}