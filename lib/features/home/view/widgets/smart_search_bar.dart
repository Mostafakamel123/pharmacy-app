// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/home/controller/home_providers.dart';

class SmartSearchBar extends ConsumerStatefulWidget {
  const SmartSearchBar({super.key});

  @override
  ConsumerState<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends ConsumerState<SmartSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    // Read the current state to populate controller
    final initialQuery = ref.read(searchQueryProvider);
    _controller = TextEditingController(text: initialQuery);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? DarkColors.surface : LightColors.surface;
    final divider = isDark ? DarkColors.divider : LightColors.divider;
    final iconColor =
        isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue;
    final hintColor = isDark ? DarkColors.textHint : LightColors.textHint;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x4D000000) // black @ 0.3
                  : const Color(0x140EA5E9), // blue @ 0.08
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _controller,
          onChanged: (value) {
            if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
            _debounceTimer = Timer(const Duration(milliseconds: 300), () {
              if (mounted) {
                ref.read(searchQueryProvider.notifier).state = value.trim();
              }
            });
          },
          decoration: InputDecoration(
            hintText: 'Search for pharmacy, medicine...',
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: AppTypography.body.fontSize,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: iconColor, size: 24),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 1, height: 24, color: divider),
                IconButton(
                  icon: Icon(Icons.tune_rounded, color: iconColor),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
              ],
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }
}

class StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  StickySearchBarDelegate({required this.child});

  @override
  double get minExtent => 76.0; // Search bar height + padding

  @override
  double get maxExtent => 76.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showGlass = shrinkOffset > 0;

    return Container(
      color: Colors.transparent,
      child: Stack(
        children: [
          if (showGlass)
            Positioned.fill(
              child: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    color: isDark
                        ? const Color(0xCC111827) // Dark background with opacity
                        : const Color(0xCCF9FAFB), // Light background with opacity
                  ),
                ),
              ),
            ),
          Center(
            child: child,
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant StickySearchBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}