// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/theme/app_colors.dart';
import 'package:Elaaj/features/posts/controller/posts_providers.dart';
import 'package:Elaaj/features/posts/model/post_model.dart';
import 'package:Elaaj/features/posts/view/widgets/post_card.dart';
import 'package:Elaaj/features/posts/view/widgets/reply_card.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';

class PostDetailsScreen extends ConsumerStatefulWidget {
  final PostModel post;

  const PostDetailsScreen({super.key, required this.post});

  @override
  ConsumerState<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends ConsumerState<PostDetailsScreen> {
  late TextEditingController _replyController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _replyController = TextEditingController();
  }

  @override
  void dispose() {
    _replyController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPharmacyMode = ref.watch(isPharmacyModeProvider);
    
    // Watch reactive replies from our new family provider
    final repliesAsync = ref.watch(postRepliesNotifierProvider(widget.post));

    return Scaffold(
      backgroundColor: isDark ? DarkColors.background : LightColors.background,
      body: CustomScrollView(
        controller: _scrollController,
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
            title: const Text(
              'Discussion',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            centerTitle: false,
          ),

          // Post content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: PostCard(
                post: widget.post,
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
                  repliesAsync.maybeWhen(
                    data: (replies) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${replies.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
                      ),
                    ),
                    orElse: () => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${widget.post.replyCount}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryGreen,
                        ),
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
              if (replies.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 48,
                          color: isDark ? DarkColors.textHint : LightColors.textHint,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No replies yet',
                          style: TextStyle(
                            color: isDark ? DarkColors.textHint : LightColors.textHint,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Create copy to sort replies (verified/best first, then chronological)
              final sortedReplies = List<ReplyModel>.from(replies);
              sortedReplies.sort((a, b) => b.isBestReply ? 1 : -1);

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final reply = sortedReplies[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: ReplyCard(
                        reply: reply,
                        isBestReply: reply.isBestReply,
                      ),
                    );
                  },
                  childCount: sortedReplies.length,
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
            child: SizedBox(height: 120),
          ),
        ],
      ),
      bottomNavigationBar: isPharmacyMode ? _buildReplyInput(context) : null,
    );
  }

  Widget _buildReplyInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final repliesState = ref.watch(postRepliesNotifierProvider(widget.post));
    final isSubmitting = repliesState.maybeWhen(
      loading: () => true,
      orElse: () => false,
    );

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? DarkColors.card : LightColors.card,
        border: Border(
          top: BorderSide(
            color: isDark ? DarkColors.divider : LightColors.divider,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? DarkColors.surfaceVariant : LightColors.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? DarkColors.divider : LightColors.divider,
                  width: 1,
                ),
              ),
              child: TextField(
                controller: _replyController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type your official pharmacy reply...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? DarkColors.textHint.withOpacity(0.6)
                        : LightColors.textHint.withOpacity(0.6),
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          isSubmitting
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primaryBlue,
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                    onPressed: () async {
                      final text = _replyController.text.trim();
                      if (text.isEmpty) return;

                      HapticFeedback.lightImpact();
                      FocusScope.of(context).unfocus();
                      
                      final success = await ref
                          .read(postRepliesNotifierProvider(widget.post).notifier)
                          .addReply(text);

                      if (success) {
                        _replyController.clear();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Your reply has been posted successfully!'),
                              backgroundColor: AppColors.primaryGreen,
                            ),
                          );
                        }
                        // Smoothly scroll down to see the new reply
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              _scrollController.position.maxScrollExtent,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        });
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Failed to submit reply. Please try again.'),
                              backgroundColor: AppColors.accentRed,
                            ),
                          );
                        }
                      }
                    },
                  ),
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
