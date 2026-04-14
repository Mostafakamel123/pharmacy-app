import 'package:flutter/material.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/home/model/pharmacy_model.dart';

class PharmacyCard extends StatefulWidget {
  final PharmacyModel pharmacy;
  final VoidCallback onTap;
  final VoidCallback? onFavorite;
  final VoidCallback? onDirections;

  const PharmacyCard({
    super.key,
    required this.pharmacy,
    required this.onTap,
    this.onFavorite,
    this.onDirections,
  });

  @override
  State<PharmacyCard> createState() => _PharmacyCardState();
}

class _PharmacyCardState extends State<PharmacyCard>
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
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) {
    _controller.reverse().then((_) => widget.onTap());
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pharmacy = widget.pharmacy;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? DarkColors.card : LightColors.card,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: isDark ? DarkColors.divider : LightColors.divider,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isDark ? Colors.black : AppColors.primaryGreen)
                    .withOpacity(isDark ? 0.15 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pharmacy image/logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: pharmacy.isOpen
                        ? [const Color(0xFFE0F2FE), const Color(0xFFDCFCE7)]
                        : [const Color(0xFFFEF3C7), const Color(0xFFFEE2E2)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  pharmacy.isOpen
                      ? Icons.local_pharmacy_rounded
                      : Icons.local_pharmacy_outlined,
                  size: 32,
                  color: pharmacy.isOpen
                      ? AppColors.primaryGreen
                      : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            pharmacy.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? DarkColors.textPrimary
                                  : LightColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Favorite button
                        GestureDetector(
                          onTap: widget.onFavorite,
                          child: Icon(
                            pharmacy.isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 20,
                            color: pharmacy.isFavorite
                                ? AppColors.accentRed
                                : isDark
                                    ? DarkColors.textHint
                                    : LightColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Address
                    Text(
                      pharmacy.address,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? DarkColors.textSecondary
                            : LightColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // Stats row
                    Row(
                      children: [
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: pharmacy.isOpen
                                ? AppColors.primaryGreen.withOpacity(0.12)
                                : AppColors.accentRed.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: pharmacy.isOpen
                                      ? AppColors.primaryGreen
                                      : AppColors.accentRed,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                pharmacy.statusText,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: pharmacy.isOpen
                                      ? AppColors.primaryGreen
                                      : AppColors.accentRed,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Distance
                        Row(
                          children: [
                            Icon(
                              Icons.near_me_rounded,
                              size: 14,
                              color: isDark
                                  ? const Color(0xFF90CAF9)
                                  : AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${pharmacy.distance.toStringAsFixed(1)} km',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? const Color(0xFF90CAF9)
                                    : AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 6),
                        // Rating
                        Row(
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              pharmacy.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFF59E0B),
                              ),
                            ),
                            Text(
                              ' (${pharmacy.reviewCount})',
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? DarkColors.textHint
                                    : LightColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Badges row
                    Row(
                      children: [
                        if (pharmacy.hasDelivery) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delivery_dining_rounded,
                                    size: 12, color: AppColors.primaryBlue),
                                const SizedBox(width: 3),
                                Text(
                                  'Delivery',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (pharmacy.estimatedDeliveryMinutes != null &&
                            pharmacy.hasDelivery)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '~${pharmacy.estimatedDeliveryMinutes} min',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryGreen,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              // Arrow
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: isDark ? DarkColors.textHint : LightColors.textHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
