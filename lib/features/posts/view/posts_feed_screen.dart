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
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
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
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
          // Posts list
          postsAsync.when(
            data: (posts) {
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyState(),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final post = posts[index];
                    return PostCard(
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
                    );
                  },
                  childCount: posts.length,
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



class _EmptyState extends StatelessWidget {
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
