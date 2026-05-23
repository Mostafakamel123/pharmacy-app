// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/pharmacies/controller/pharmacy_providers.dart';
import 'package:pharmacy_app/features/pharmacies/view/pharmacy_details_screen.dart';
import 'package:pharmacy_app/features/pharmacies/view/widgets/pharmacy_card.dart';
import 'package:pharmacy_app/features/pharmacies/view/widgets/pharmacy_filter_bar.dart';
import 'package:pharmacy_app/features/pharmacies/view/widgets/pharmacy_map_preview.dart';

class NearbyPharmaciesScreen extends ConsumerWidget {
  const NearbyPharmaciesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmaciesAsync = ref.watch(nearbyPharmaciesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            backgroundColor:
                isDark ? DarkColors.background : LightColors.background,
            elevation: 0,
            title: const Text(
              'Nearby Pharmacies',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.my_location_rounded,
                  color: isDark
                      ? const Color(0xFF90CAF9)
                      : AppColors.primaryBlue,
                ),
                onPressed: () {
                  ref.read(nearbyPharmaciesProvider.notifier).refresh();
                },
              ),
            ],
          ),
          // Subtitle
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Find the closest pharmacies around you',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? DarkColors.textSecondary
                      : LightColors.textSecondary,
                ),
              ),
            ),
          ),
          // Search bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? DarkColors.card : LightColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : AppColors.primaryGreen)
                          .withOpacity(isDark ? 0.2 : 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: TextField(
                  onChanged: (value) => ref
                      .read(nearbyPharmaciesProvider.notifier)
                      .setSearchQuery(value),
                  decoration: InputDecoration(
                    hintText: 'Search pharmacy or medicine...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? DarkColors.textHint
                          : LightColors.textHint,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? const Color(0xFF90CAF9)
                          : AppColors.primaryGreen,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),
          // Filter bar
          const SliverToBoxAdapter(child: PharmacyFilterBar()),
          // Map preview
          pharmaciesAsync.when(
            data: (pharmacies) => pharmacies.isNotEmpty
                ? SliverToBoxAdapter(
                    child: PharmacyMapPreview(
                      pharmacies: pharmacies,
                      onTap: () {
                        // Open full map
                      },
                    ),
                  )
                : const SliverToBoxAdapter(child: SizedBox.shrink()),
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          // Pharmacies count
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: pharmaciesAsync.when(
                data: (pharmacies) => Text(
                  '${pharmacies.length} ${pharmacies.length == 1 ? 'pharmacy' : 'pharmacies'} nearby',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? DarkColors.textSecondary
                        : LightColors.textSecondary,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ),
          // Pharmacies list
          pharmaciesAsync.when(
            data: (pharmacies) {
              if (pharmacies.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(
                    isFiltering: ref.watch(nearbyPharmaciesProvider).asData?.value.isEmpty ?? false,
                    onClear: () {
                      ref.read(nearbyPharmaciesProvider.notifier).refresh();
                    },
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pharmacy = pharmacies[index];
                    return PharmacyCard(
                      pharmacy: pharmacy,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PharmacyDetailsScreen(pharmacy: pharmacy),
                          ),
                        );
                      },
                      onFavorite: () {
                        ref
                            .read(favoritePharmaciesProvider.notifier)
                            .toggleFavorite(pharmacy.id);
                      },
                    );
                  },
                  childCount: pharmacies.length,
                ),
              );
            },
            loading: () => SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: isDark ? DarkColors.card : LightColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: isDark
                          ? DarkColors.textHint
                          : LightColors.textHint,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load pharmacies',
                      style: TextStyle(
                        color: isDark
                            ? DarkColors.textHint
                            : LightColors.textHint,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(nearbyPharmaciesProvider.notifier)
                          .refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isFiltering;
  final VoidCallback onClear;

  const _EmptyState({required this.isFiltering, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFiltering
                ? Icons.filter_list_off_rounded
                : Icons.location_off_rounded,
            size: 64,
            color: isDark ? DarkColors.textHint : LightColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            isFiltering ? 'No pharmacies match filters' : 'No pharmacies nearby',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltering ? 'Try adjusting your filters' : 'Try expanding your search area',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? DarkColors.textHint : LightColors.textHint,
            ),
          ),
          if (isFiltering) ...[
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Clear Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
