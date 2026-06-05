import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/home/controller/home_providers.dart';

// ════════════════════════════════════════════════════════════════════════════
// SMART SEARCH BAR
// ════════════════════════════════════════════════════════════════════════════

/// Debounced search field that drives [searchQueryProvider].
///
/// Performance notes:
/// • `ConsumerStatefulWidget` keeps a single [TextEditingController] alive
///   across rebuilds — no controller recreation on hot-reload or parent
///   rebuild.
/// • The 300 ms debounce prevents per-keystroke provider invalidations which
///   would trigger O(N) pharmacy list rebuilds on every character typed.
/// • The widget itself is free of any animation ticker, keeping its build
///   method purely synchronous and cheap.
class SmartSearchBar extends ConsumerStatefulWidget {
  const SmartSearchBar({super.key});

  @override
  ConsumerState<SmartSearchBar> createState() => _SmartSearchBarState();
}

class _SmartSearchBarState extends ConsumerState<SmartSearchBar> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Seed the field with the current query so it survives navigation.
    _controller = TextEditingController(text: ref.read(searchQueryProvider));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Cancel any pending timer to avoid stale updates.
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        ref.read(searchQueryProvider.notifier).state = value.trim();
      }
    });
  }

  void _onClear() {
    _controller.clear();
    _debounce?.cancel();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? DarkColors.surface : LightColors.surface;
    final divider = isDark ? DarkColors.divider : LightColors.divider;
    final iconColor = isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue;
    final hintColor = isDark ? DarkColors.textHint : LightColors.textHint;

    // Listen only to determine if we should show the clear button.
    // We deliberately do NOT watch searchQueryProvider here to avoid
    // rebuilding the whole search bar every time the query changes.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.xl)),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x4D000000)
                  : const Color(0x140EA5E9),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _controller,
          onChanged: _onChanged,
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? const Color(0xFFF9FAFB)
                : const Color(0xFF1F2937),
            fontFamily: 'Cairo',
          ),
          decoration: InputDecoration(
            hintText: 'Search for pharmacy, medicine...',
            hintStyle: TextStyle(
              color: hintColor,
              fontSize: 13.5,
              fontFamily: 'Cairo',
            ),
            // ── Search icon ─────────────────────────────────────────────
            prefixIcon: Icon(
              Icons.search_rounded,
              color: iconColor,
              size: 22,
            ),
            // ── Suffix: divider + filter button ─────────────────────────
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(width: 1, height: 24, child: ColoredBox(color: divider)),
                IconButton(
                  icon: Icon(Icons.tune_rounded, color: iconColor, size: 20),
                  onPressed: _onClear,
                  tooltip: 'Clear / Filter',
                  splashRadius: 20,
                ),
                const SizedBox(width: 4),
              ],
            ),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 4, vertical: 14),
            isDense: true,
          ),
        ),
      ),
    );
  }
}
