// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/theme/app_colors.dart';
import 'package:pharmacy_app/features/posts/controller/posts_providers.dart';
import 'package:pharmacy_app/features/posts/model/post_model.dart';
import 'package:pharmacy_app/features/posts/view/widgets/post_card.dart';
import 'package:pharmacy_app/features/posts/view/widgets/reply_card.dart';

class PostDetailsScreen extends ConsumerWidget {
  final PostModel post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repliesAsync = ref.watch(postRepliesProvider(post.id));

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
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? DarkColors.textPrimary : LightColors.textPrimary,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.bookmark_border_rounded,
                  color: isDark ? DarkColors.textSecondary : LightColors.textSecondary,
                ),
                onPressed: () {},
              ),
            ],
          ),

          // Post content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: PostCard(
                post: post,
                onTap: () {},
              ),
            ),
          ),

          // Replies header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: Row(
                children: [
                  Text(
                    'Replies',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? DarkColors.textPrimary
                          : LightColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      '${post.replyCount}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Sort by: Latest',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? DarkColors.textHint
                          : LightColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Replies list
          repliesAsync.when(
            data: (replies) {
              // Best replies first
              replies.sort((a, b) => b.isBestReply ? 1 : -1);

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final reply = replies[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ReplyCard(
                        reply: reply,
                        isBestReply: reply.isBestReply,
                      ),
                    );
                  },
                  childCount: replies.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _RepliesShimmer(),
              ),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: isDark
                            ? DarkColors.textHint
                            : LightColors.textHint,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load replies',
                        style: TextStyle(
                            color: isDark
                                ? DarkColors.textHint
                                : LightColors.textHint),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _RepliesShimmer extends StatelessWidget {
  const _RepliesShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerColor =
        isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB);

    return Column(
      children: List.generate(
        2,
        (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(width: 120, height: 14, color: shimmerColor),
                        const SizedBox(height: 4),
                        Container(width: 50, height: 12, color: shimmerColor),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(width: double.infinity, height: 14, color: shimmerColor),
                const SizedBox(height: 6),
                Container(width: 200, height: 14, color: shimmerColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
