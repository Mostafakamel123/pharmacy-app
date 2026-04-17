// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
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
              Builder(
                builder: (context) => TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (_, __, ___) => const NearbyPharmaciesScreen(),
                        transitionsBuilder: (_, animation, __, child) {
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(1, 0),
                              end: Offset.zero,
                            ).animate(CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                            )),
                            child: child,
                          );
                        },
                      ),
                    );
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
              ),
            ],
          ),
        ),
        pharmaciesAsync.when(
          data: (pharmacies) => _PharmacyList(pharmacies: pharmacies),
          loading: () => const _ShimmerLoading(),
          error: (error, stack) => _ErrorState(onRetry: () => ref.read(nearbyPharmaciesProvider.notifier).refresh()),
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
      height: 164,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: pharmacies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final pharmacy = pharmacies[index];
          return _PharmacyCard(pharmacy: pharmacy);
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PharmacyDetailsScreen(pharmacy: pharmacy),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : const Color(0xFF0EA5E9)).withOpacity(isDark ? 0.2 : 0.06),
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
              height: 54,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E3A4A), const Color(0xFF2C5364)]
                      : [const Color(0xFFE0F7FA), const Color(0xFFE8F5E9)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Icon(
                  Icons.location_on_rounded,
                  color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF0EA5E9),
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Pharmacy name
            Text(
              pharmacy.name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            // Distance
            Row(
              children: [
                Icon(
                  Icons.directions_walk_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF6B7280),
                ),
                const SizedBox(width: 4),
                Text(
                  '${pharmacy.distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF90CAF9) : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 10),
                // Rating
                Icon(
                  Icons.star_rounded,
                  size: 14,
                  color: const Color(0xFFF59E0B),
                ),
                const SizedBox(width: 2),
                Text(
                  pharmacy.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFF59E0B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Status row
            Row(
              children: [
                // Open/Closed
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: pharmacy.isOpen
                        ? const Color(0xFF10B981).withOpacity(0.15)
                        : const Color(0xFFEF4444).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    pharmacy.isOpen ? 'Open' : 'Closed',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: pharmacy.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
                if (pharmacy.hasDelivery) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0EA5E9).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.delivery_dining_rounded, size: 12, color: const Color(0xFF0EA5E9)),
                        const SizedBox(width: 3),
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
      height: 164,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) => Container(
          width: 220,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            children: [
              Container(
                height: 54,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                height: 14,
                width: 120,
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              ),
              const SizedBox(height: 8),
              Container(
                height: 12,
                width: 80,
                color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              ),
            ],
          ),
        ),
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
      height: 120,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: isDark ? const Color(0xFF6B7280) : const Color(0xFF9CA3AF)),
            const SizedBox(height: 8),
            Text(
              'Failed to load pharmacies',
              style: TextStyle(color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
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
