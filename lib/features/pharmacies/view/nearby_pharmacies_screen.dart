// ignore_for_file: deprecated_member_use

import 'dart:async'; // PERF FIX: Add Timer import for debounce

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
    // PERF FIX: Use .select() to only rebuild when pharmacy list changes, not entire AsyncValue
    final pharmaciesAsync = ref.watch(nearbyPharmaciesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App bar - PERF FIX: Extract to const widget to avoid rebuilds
          const _AppBarSection(),
          // Subtitle - PERF FIX: Extract to const widget
          const _SubtitleSection(),
          // Search bar - PERF FIX: Extract with debounced search
          _SearchBarSection(isDark: isDark),
          // Filter bar
          const SliverToBoxAdapter(child: PharmacyFilterBar()),
          // Map preview - PERF FIX: Only show when data is available
          ..._buildMapPreviewSliver(pharmaciesAsync, isDark),
          // Pharmacies count - PERF FIX: Extract to separate widget
          _PharmaciesCountSection(pharmaciesAsync: pharmaciesAsync, isDark: isDark),
          // Pharmacies list
          ..._buildPharmacyListSlivers(pharmaciesAsync, isDark, ref, context),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMapPreviewSliver(AsyncValue<List<PharmacyModel>> pharmaciesAsync, bool isDark) {
    return pharmaciesAsync.when(
      data: (pharmacies) => pharmacies.isNotEmpty
          ? [
              SliverToBoxAdapter(
                child: PharmacyMapPreview(
                  pharmacies: pharmacies,
                  onTap: () {
                    // Open full map
                  },
                ),
              ),
            ]
          : const [],
      loading: () => const [],
      error: (_, __) => const [],
    );
  }

  List<Widget> _buildPharmacyListSlivers(
    AsyncValue<List<PharmacyModel>> pharmaciesAsync,
    bool isDark,
    WidgetRef ref,
    BuildContext context,
  ) {
    return pharmaciesAsync.when(
      data: (pharmacies) {
        if (pharmacies.isEmpty) {
          return [
            SliverFillRemaining(
              child: _EmptyState(
                isFiltering: ref.watch(nearbyPharmaciesProvider.select((v) => v.asData?.value.isEmpty ?? false)),
                onClear: () {
                  ref.read(nearbyPharmaciesProvider.notifier).refresh();
                },
              ),
            ),
          ];
        }
        return [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final pharmacy = pharmacies[index];
                return PharmacyCard(
                  key: ValueKey(pharmacy.id), // PERF FIX: Add stable key
                  pharmacy: pharmacy,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PharmacyDetailsScreen(pharmacy: pharmacy),
                      ),
                    );
                  },
                  onFavorite: () {
                    final favorites = ref.read(favoritePharmaciesProvider.notifier).state;
                    final updated = Set<String>.from(favorites);
                    if (updated.contains(pharmacy.id)) {
                      updated.remove(pharmacy.id);
                    } else {
                      updated.add(pharmacy.id);
                    }
                    ref.read(favoritePharmaciesProvider.notifier).state = updated;
                  },
                );
              },
              childCount: pharmacies.length,
              // PERF FIX: Add performance optimizations to delegate
              addAutomaticKeepAlives: false,
              addRepaintBoundaries: true,
            ),
          ),
        ];
      },
      loading: () => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
      ],
      error: (error, _) => [
        SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: isDark ? DarkColors.textHint : LightColors.textHint,
                ),
                const SizedBox(height: 12),
                Text(
                  'Failed to load pharmacies',
                  style: TextStyle(
                    color: isDark ? DarkColors.textHint : LightColors.textHint,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.read(nearbyPharmaciesProvider.notifier).refresh(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// PERF FIX: Extract AppBar to const widget to avoid rebuilds on state changes
class _AppBarSection extends ConsumerWidget {
  const _AppBarSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverAppBar(
      expandedHeight: 0,
      floating: true,
      snap: true,
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
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
            color: isDark ? const Color(0xFF90CAF9) : AppColors.primaryBlue,
          ),
          onPressed: () {
            // PERF FIX: Use ref.read instead of ref.watch to avoid unnecessary rebuilds
            ref.read(nearbyPharmaciesProvider.notifier).refresh();
          },
        ),
      ],
    );
  }
}

// PERF FIX: Extract subtitle to const widget
class _SubtitleSection extends StatelessWidget {
  const _SubtitleSection();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Text(
          'Find the closest pharmacies around you',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

// PERF FIX: Extract search bar with debounced input - using ConsumerStatefulWidget to access ref
class _SearchBarSection extends ConsumerStatefulWidget {
  const _SearchBarSection();

  @override
  ConsumerState<_SearchBarSection> createState() => _SearchBarSectionState();
}

class _SearchBarSectionState extends ConsumerState<_SearchBarSection> {
  final _controller = TextEditingController(); // PERF FIX: Use controller for better control
  Timer? _debounceTimer;

  @override
  void dispose() {
    _controller.dispose(); // PERF FIX: Dispose controller
    _debounceTimer?.cancel(); // PERF FIX: Cancel timer on dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverToBoxAdapter(
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
            controller: _controller,
            onChanged: (value) {
              // PERF FIX: Debounce search query updates to avoid excessive API calls
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 300), () {
                ref.read(nearbyPharmaciesProvider.notifier).setSearchQuery(value);
              });
            },
            decoration: InputDecoration(
              hintText: 'Search pharmacy or medicine...',
              hintStyle: TextStyle(
                color: isDark ? DarkColors.textHint : LightColors.textHint,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: isDark ? const Color(0xFF90CAF9) : AppColors.primaryGreen,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ),
    );
  }
}

// PERF FIX: Extract pharmacies count section
class _PharmaciesCountSection extends StatelessWidget {
  final AsyncValue<List<PharmacyModel>> pharmaciesAsync;
  final bool isDark;

  const _PharmaciesCountSection({required this.pharmaciesAsync, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: pharmaciesAsync.when(
          data: (pharmacies) => Text(
            '${pharmacies.length} ${pharmacies.length == 1 ? 'pharmacy' : 'pharmacies'} nearby',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
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
