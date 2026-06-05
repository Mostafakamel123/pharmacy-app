// ignore_for_file: unused_local_variable, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/pharmacies/controller/pharmacy_providers.dart';

class PharmacyFilterBar extends ConsumerWidget {
  const PharmacyFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Watch the provider state to trigger rebuilds when filters are applied/toggled
    ref.watch(nearbyPharmaciesProvider);
    final notifier = ref.read(nearbyPharmaciesProvider.notifier);

    final isOpenNow = notifier.isOpenNow;
    final hasDelivery = notifier.hasDelivery;
    final onlyFavorites = notifier.onlyFavorites;
    final maxDistance = notifier.maxDistance;

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _FilterChip(
            label: 'Open Now',
            icon: Icons.schedule_rounded,
            iconColor: AppColors.primaryGreen,
            isSelected: isOpenNow,
            onTap: () => notifier.toggleOpenNow(!isOpenNow),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Delivery',
            icon: Icons.delivery_dining_rounded,
            iconColor: AppColors.primaryBlue,
            isSelected: hasDelivery,
            onTap: () => notifier.toggleDelivery(!hasDelivery),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '< 1 km',
            icon: Icons.near_me_rounded,
            iconColor: const Color(0xFFF59E0B),
            isSelected: maxDistance == 1.0,
            onTap: () => notifier.setMaxDistance(maxDistance == 1.0 ? 50.0 : 1.0),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: '< 3 km',
            icon: Icons.near_me_rounded,
            iconColor: const Color(0xFF8B5CF6),
            isSelected: maxDistance == 3.0,
            onTap: () => notifier.setMaxDistance(maxDistance == 3.0 ? 50.0 : 3.0),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Favorites',
            icon: Icons.favorite_rounded,
            iconColor: AppColors.accentRed,
            isSelected: onlyFavorites,
            onTap: () => notifier.toggleOnlyFavorites(!onlyFavorites),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatefulWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? widget.iconColor
                : isDark
                    ? DarkColors.surface
                    : LightColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected
                  ? widget.iconColor
                  : isDark
                      ? DarkColors.divider
                      : LightColors.divider,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: widget.iconColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: isSelected ? Colors.white : widget.iconColor,
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : widget.iconColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
