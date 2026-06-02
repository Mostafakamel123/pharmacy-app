import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/home/controller/home_providers.dart';
import 'package:pharmacy_app/features/profile/controller/profile_providers.dart';

// ════════════════════════════════════════════════════════════════════════════
// HOME HEADER
// ════════════════════════════════════════════════════════════════════════════

/// Top hero section of the patient home screen.
///
/// Performance notes:
/// • [HomeHeader] is a plain StatelessWidget — it does NOT watch any provider.
///   This means whenever a provider rebuilds (profile, notifications) the
///   header Container itself does NOT rebuild; only the internal Consumer
///   sub-widgets do.
/// • The gradient and boxShadow are computed once per dark-mode toggle via
///   Theme.of(), which is already internally cached by Flutter.
/// • No BackdropFilter or ClipRRect is used anywhere in this widget tree.
class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Compute hour once — used for both greeting string and icon.
    final hour = DateTime.now().hour;
    final greeting =
        hour < 12 ? 'Good Morning' : hour < 17 ? 'Good Afternoon' : 'Good Evening';
    final greetingIcon = hour < 12
        ? Icons.wb_sunny_rounded
        : hour < 17
            ? Icons.wb_cloudy_rounded
            : Icons.nights_stay_rounded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF0C1B2A),
                  Color(0xF2132F3F),
                  Color(0xE61A3B4F),
                ]
              : const [
                  Color(0xFFF0FAFE),
                  Color(0xFFE5F9F3),
                  Color(0xFFF5FEF9),
                ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppRadius.xxl),
          bottomRight: Radius.circular(AppRadius.xxl),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x33000000) : const Color(0x0F0EA5E9),
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
            // ── Row 1: Menu · Greeting pill · Notification ──────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _HeaderIconButton(
                  icon: Icons.menu_rounded,
                  onTap: () => Scaffold.of(context).openDrawer(),
                  isDark: isDark,
                ),
                _GreetingPill(
                  greeting: greeting,
                  icon: greetingIcon,
                  isDark: isDark,
                ),
                const _NotificationBadge(),
              ],
            ),
            const SizedBox(height: 16),
            // ── Row 2: Name · Location pill ──────────────────────────────
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _ProfileNameWidget()),
                SizedBox(width: 12),
                _ProfileLocationWidget(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// GREETING PILL
// ════════════════════════════════════════════════════════════════════════════

class _GreetingPill extends StatelessWidget {
  final String greeting;
  final IconData icon;
  final bool isDark;

  const _GreetingPill({
    required this.greeting,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        isDark ? const Color(0xFF38BDF8) : const Color(0xFF10B981);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0x1F0EA5E9)
            : const Color(0x1410B981),
        borderRadius: const BorderRadius.all(Radius.circular(16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            greeting,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PROFILE NAME WIDGET
// ════════════════════════════════════════════════════════════════════════════

class _ProfileNameWidget extends ConsumerWidget {
  const _ProfileNameWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    const style = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
    );

    return ref.watch(profileProvider).when(
          data: (profile) {
            final name = profile.name.trim().isEmpty ? 'User' : profile.name;
            return Text(
              name,
              style: style.copyWith(color: textColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
          loading: () => RepaintBoundary(
            child: _FlatShimmer(
              width: 140,
              height: 22,
              isDark: isDark,
            ),
          ),
          error: (_, __) => Text(
            'User',
            style: style.copyWith(color: textColor),
          ),
        );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// PROFILE LOCATION WIDGET
// ════════════════════════════════════════════════════════════════════════════

class _ProfileLocationWidget extends ConsumerWidget {
  const _ProfileLocationWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ref.watch(profileProvider).when(
          data: (profile) => _LocationPill(location: profile.location),
          loading: () => RepaintBoundary(
            child: _FlatShimmer(width: 80, height: 28, borderRadius: 20, isDark: isDark),
          ),
          error: (_, __) => const _LocationPill(location: 'Assiut'),
        );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HEADER ICON BUTTON
// ════════════════════════════════════════════════════════════════════════════

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
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0x1A0EA5E9)
              : const Color(0xE6FFFFFF),
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(
            color: isDark
                ? const Color(0x330EA5E9)
                : const Color(0xFFE8F5E9),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x1A000000)
                  : const Color(0x0F0EA5E9),
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

// ════════════════════════════════════════════════════════════════════════════
// LOCATION PILL
// ════════════════════════════════════════════════════════════════════════════

class _LocationPill extends StatelessWidget {
  final String? location;
  const _LocationPill({this.location});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final display =
        (location == null || location!.trim().isEmpty) ? 'Assiut' : location!;
    final color =
        isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0x1A0EA5E9)
            : const Color(0xD9FFFFFF),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        border: Border.all(
          color: isDark
              ? const Color(0x330EA5E9)
              : const Color(0xFFE8F5E9),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.location_on_rounded, size: 13.5, color: color),
          const SizedBox(width: 5),
          Text(
            display,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? const Color(0xFF38BDF8)
                  : const Color(0xFF0F172A),
              letterSpacing: -0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down_rounded, size: 13.5, color: color),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// NOTIFICATION BADGE
// ════════════════════════════════════════════════════════════════════════════

class _NotificationBadge extends ConsumerWidget {
  const _NotificationBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(notificationCountProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0x1A0EA5E9)
                : const Color(0xE6FFFFFF),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(
              color: isDark
                  ? const Color(0x330EA5E9)
                  : const Color(0xFFE8F5E9),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? const Color(0x1A000000)
                    : const Color(0x0F0EA5E9),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_none_rounded,
            size: 20,
            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0EA5E9),
          ),
        ),
        if (count > 0)
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
                    color: Color(0x66EF4444),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  count > 9 ? '9+' : '$count',
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

// ════════════════════════════════════════════════════════════════════════════
// FLAT SHIMMER  (replaces the old per-instance AnimationController shimmer)
// ════════════════════════════════════════════════════════════════════════════

/// A lightweight fade-pulsing skeleton placeholder.
///
/// Performance differences vs. the old _HeaderShimmer:
/// • Uses a single [AnimationController] per shimmer widget — fine because
///   the shimmer only shows when data is loading (short-lived state).
/// • Wrapped in [RepaintBoundary] at the call-site so its animation repaints
///   are isolated to its own layer, not the whole header.
/// • The animation tween is a simple opacity fade — no heavy gradient shader.
class _FlatShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;
  final bool isDark;

  const _FlatShimmer({
    required this.width,
    required this.height,
    this.borderRadius = 8,
    required this.isDark,
  });

  @override
  State<_FlatShimmer> createState() => _FlatShimmerState();
}

class _FlatShimmerState extends State<_FlatShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.isDark
        ? const Color(0x2BFFFFFF)
        : const Color(0x14000000);

    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius:
              BorderRadius.all(Radius.circular(widget.borderRadius)),
        ),
      ),
    );
  }
}