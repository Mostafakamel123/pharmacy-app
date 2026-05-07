import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/posts/controller/posts_providers.dart';
import 'package:pharmacy_app/features/posts/model/post_model.dart';
import 'package:pharmacy_app/features/posts/view/post_details_screen.dart';
import 'package:pharmacy_app/features/posts/view/widgets/post_card.dart';
import 'package:pharmacy_app/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:pharmacy_app/features/pharmacy_mode/widgets/pharmacy_drawer.dart';

class PostsFeedScreen extends ConsumerWidget {
  const PostsFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(postsFeedProvider);
    final pharmacyModeState = ref.watch(pharmacyModeProvider);
    final currentPharmacy = pharmacyModeState.currentPharmacy;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      drawer: PharmacyDrawer(currentPharmacy),
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
              'Posts',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            actions: [
              // Filter
              PopupMenuButton<PostsSort>(
                icon: Icon(
                  Icons.tune_rounded,
                  color: isDark
                      ? const Color(0xFF90CAF9)
                      : AppColors.primaryBlue,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                onSelected: (sort) {
                  ref.read(postsSortProvider.notifier).state = sort;
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: PostsSort.latest,
                    child: Text('Latest'),
                  ),
                  const PopupMenuItem(
                    value: PostsSort.mostReplied,
                    child: Text('Most Replied'),
                  ),
                  const PopupMenuItem(
                    value: PostsSort.nearby,
                    child: Text('Nearby'),
                  ),
                ],
              ),
            ],
          ),
          // Category filter chips
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, _) {
                final sort = ref.watch(postsSortProvider);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: SizedBox(
                    height: 36,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          icon: Icons.all_inclusive_rounded,
                          isSelected: sort == PostsSort.latest,
                          onTap: () => ref.read(postsSortProvider.notifier).state = PostsSort.latest,
                        ),
                        _FilterChip(
                          label: 'General',
                          icon: Icons.help_outline_rounded,
                          onTap: () => ref.read(postsFeedProvider.notifier).filterByCategory(PostCategory.general),
                        ),
                        _FilterChip(
                          label: 'Prescription',
                          icon: Icons.description_rounded,
                          onTap: () => ref.read(postsFeedProvider.notifier).filterByCategory(PostCategory.prescription),
                        ),
                        _FilterChip(
                          label: 'Emergency',
                          icon: Icons.local_hospital_rounded,
                          onTap: () => ref.read(postsFeedProvider.notifier).filterByCategory(PostCategory.emergency),
                        ),
                        _FilterChip(
                          label: 'Advice',
                          icon: Icons.lightbulb_outline_rounded,
                          onTap: () => ref.read(postsFeedProvider.notifier).filterByCategory(PostCategory.advice),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Posts list
          postsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return const SliverFillRemaining(
                  child: _EmptyState(),
                );
              }
              // PERF FIX: Add addRepaintBoundaries and addAutomaticKeepAlives to delegate
              // PERF FIX: Wrap PostCard with RepaintBoundary to isolate repaints
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    return RepaintBoundary(  // PERF FIX: Isolate repaint for each card
                      child: PostCard(
                        key: ValueKey(post.id),  // PERF FIX: Stable key for list items
                        post: post,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PostDetailsScreen(post: post),
                            ),
                          );
                        },
                        onBookmark: () {
                          final bookmarks = ref
                              .read(bookmarkedPostsProvider.notifier)
                              .state;
                          final updated = Set<String>.from(bookmarks);
                          if (updated.contains(post.id)) {
                            updated.remove(post.id);
                          } else {
                            updated.add(post.id);
                          }
                          ref.read(bookmarkedPostsProvider.notifier).state =
                              updated;
                        },
                      ),
                    );
                  },
                  childCount: posts.length,
                  addRepaintBoundaries: true,  // PERF FIX: Enable repaint boundaries
                  addAutomaticKeepAlives: false,  // PERF FIX: Disable keep-alive for feed items
                  addAutomaticKeepAlives: false, // PERF FIX: items don't need keepAlive
                  addRepaintBoundaries: true,    // PERF FIX: isolate repaints per item
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: _PostsShimmer(),
            ),
            error: (error, _) => SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline_rounded,
                        size: 48, color: isDark ? DarkColors.textHint : LightColors.textHint),
                    const SizedBox(height: 12),
                    Text(
                      'Failed to load posts',
                      style: TextStyle(
                          color: isDark
                              ? DarkColors.textHint
                              : LightColors.textHint),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(postsFeedProvider.notifier).refresh(),
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

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.icon,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryBlue
                : isDark
                    ? DarkColors.surface
                    : LightColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryBlue
                  : isDark
                      ? DarkColors.divider
                      : LightColors.divider,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? DarkColors.textSecondary
                        : LightColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : isDark
                          ? DarkColors.textSecondary
                          : LightColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_rounded,
            size: 64,
            color: isDark ? DarkColors.textHint : LightColors.textHint,
          ),
          const SizedBox(height: 16),
          Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _PostsShimmer extends StatelessWidget {
  const _PostsShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? DarkColors.card : LightColors.card,
                borderRadius: BorderRadius.circular(AppRadius.xl),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(width: 100, height: 14, color: shimmerColor),
                          const SizedBox(height: 6),
                          Container(width: 60, height: 12, color: shimmerColor),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(width: double.infinity, height: 14, color: shimmerColor),
                  const SizedBox(height: 6),
                  Container(width: 180, height: 14, color: shimmerColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
