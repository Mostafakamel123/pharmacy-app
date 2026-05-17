// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pharmacy_app/features/home/controller/home_providers.dart';
import 'package:pharmacy_app/features/home/model/pharmacy_model.dart';
import 'package:pharmacy_app/features/pharmacies/view/nearby_pharmacies_screen.dart';
import 'package:pharmacy_app/features/pharmacies/view/pharmacy_details_screen.dart';

class NearbyPharmaciesSection extends ConsumerWidget {
  const NearbyPharmaciesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmaciesAsync = ref.watch(nearbyPharmaciesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Pharmacies',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    context.push('/pharmacies');
                  },
                  child: const Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0EA5E9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          pharmaciesAsync.when(
            data: (pharmacies) => _PharmacyList(pharmacies: pharmacies),
            loading: () => const _ShimmerLoading(),
            error: (error, stack) => _ErrorState(
              onRetry: () => ref
                  .read(nearbyPharmaciesProvider.notifier)
                  .refresh(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyList extends StatelessWidget {
  final List<PharmacyModel> pharmacies;

  const _PharmacyList({required this.pharmacies});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: pharmacies.length,
        // Pre-render ~2 cards off-screen for smoother scrolling
        cacheExtent: 350,
        // Stateless children don't need KeepAlive overhead
        addAutomaticKeepAlives: false,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return _PharmacyCard(pharmacy: pharmacies[index]);
        },
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;

  const _PharmacyCard({required this.pharmacy});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        context.push('/pharmacy/${pharmacy.id}', extra: pharmacy);
      },
      // Replaced AnimatedContainer with Container — no animated properties exist,
      // so AnimatedContainer's implicit animation machinery is pure overhead.
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          border: Border.all(
            color: isDark
                ? const Color(0xFF374151)
                : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x33000000) // black @ 0.2
                  : const Color(0x0F0EA5E9), // blue @ 0.06
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map placeholder
            Container(
              height: 42,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [
                          Color(0xFF1E3A4A),
                          Color(0xFF2C5364),
                        ]
                      : const [
                          Color(0xFFE0F7FA),
                          Color(0xFFE8F5E9),
                        ],
                ),
                borderRadius:
                    const BorderRadius.all(Radius.circular(10)),
              ),
              child: Center(
                child: Icon(
                  Icons.location_on_rounded,
                  color: isDark
                      ? const Color(0xFF90CAF9)
                      : const Color(0xFF0EA5E9),
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 6),
            // Pharmacy name
            Text(
              pharmacy.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            // Distance & Rating
            Row(
              children: [
                Icon(
                  Icons.directions_walk_rounded,
                  size: 12,
                  color: isDark
                      ? const Color(0xFF90CAF9)
                      : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 3),
                Text(
                  '${pharmacy.distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? const Color(0xFF90CAF9)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.star_rounded,
                  size: 12,
                  color: Color(0xFFF59E0B),
                ),
                const SizedBox(width: 2),
                Text(
                  pharmacy.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            // Status row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pharmacy.isOpen
                        ? const Color(0x2610B981) // replaced withOpacity(0.15)
                        : const Color(0x26EF4444), // replaced withOpacity(0.15)
                    borderRadius:
                        const BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Text(
                    pharmacy.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: pharmacy.isOpen
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                if (pharmacy.hasDelivery) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: const BoxDecoration(
                      color: Color(0x260EA5E9), // replaced withOpacity(0.15)
                      borderRadius:
                          BorderRadius.all(Radius.circular(6)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delivery_dining_rounded,
                            size: 12, color: Color(0xFF0EA5E9)),
                        SizedBox(width: 3),
                        Text(
                          'Delivery',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0EA5E9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerLoading extends StatelessWidget {
  const _ShimmerLoading();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 138,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        addAutomaticKeepAlives: false,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => _ShimmerCard(isDark: isDark),
      ),
    );
  }
}

/// Extracted shimmer item to avoid recreating identical decorations per index.
class _ShimmerCard extends StatelessWidget {
  final bool isDark;

  const _ShimmerCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final shimmerColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Container(
      width: 170,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.all(Radius.circular(18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: double.infinity,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius:
                  const BorderRadius.all(Radius.circular(10)),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 12,
            width: 100,
            color: shimmerColor,
          ),
          const SizedBox(height: 6),
          Container(
            height: 11,
            width: 70,
            color: shimmerColor,
          ),
          const SizedBox(height: 6),
          Container(
            height: 11,
            width: 60,
            color: shimmerColor,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 138,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 40,
                color: isDark
                    ? const Color(0xFF6B7280)
                    : const Color(0xFF9CA3AF)),
            const SizedBox(height: 8),
            Text(
              'Failed to load pharmacies',
              style: TextStyle(
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}