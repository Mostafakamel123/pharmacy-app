import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Elaaj/core/network/api_endpoints.dart';
import 'package:Elaaj/features/pharmacy_mode/controller/pharmacy_mode_provider.dart';
import 'package:Elaaj/features/posts/model/post_model.dart';

// Selected category filter provider (kept for legacy references, default to null)
final selectedCategoryProvider = StateProvider<PostCategory?>((ref) => null);

// Posts feed provider
final postsFeedProvider =
    StateNotifierProvider<PostsFeedNotifier, AsyncValue<List<PostModel>>>((ref) {
  return PostsFeedNotifier();
});

class PostsFeedNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final ApiEndpoints _api = ApiEndpoints();
  int _currentPage = 1;
  bool _hasMore = true;

  PostsFeedNotifier() : super(const AsyncValue.loading()) {
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      if (_currentPage == 1) {
        state = const AsyncValue.loading();
      }
      final rawPosts = await _api.getPosts(pageNumber: _currentPage, pageSize: 15);
      final newPosts = rawPosts.map((item) => PostModel.fromJson(item as Map<String, dynamic>)).toList();
      
      if (newPosts.length < 15) {
        _hasMore = false;
      }
      
      final currentList = state.value ?? [];
      state = AsyncValue.data(_currentPage == 1 ? newPosts : [...currentList, ...newPosts]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadPosts();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !_hasMore) return;
    _currentPage++;
    await _loadPosts();
  }
}

// My posts provider
final myPostsProvider =
    StateNotifierProvider<MyPostsNotifier, AsyncValue<List<PostModel>>>((ref) {
  return MyPostsNotifier(ref);
});

class MyPostsNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final Ref ref;
  final ApiEndpoints _api = ApiEndpoints();
  int _currentPage = 1;
  bool _hasMore = true;

  MyPostsNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      if (_currentPage == 1) {
        state = const AsyncValue.loading();
      }
      final rawPosts = await _api.getMyPosts(pageNumber: _currentPage, pageSize: 15);
      final newPosts = rawPosts.map((item) => PostModel.fromJson(item as Map<String, dynamic>)).toList();
      
      if (newPosts.length < 15) {
        _hasMore = false;
      }
      
      final currentList = state.value ?? [];
      state = AsyncValue.data(_currentPage == 1 ? newPosts : [...currentList, ...newPosts]);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    _currentPage = 1;
    _hasMore = true;
    await _loadPosts();
  }

  Future<void> loadMore() async {
    if (state.isLoading || !_hasMore) return;
    _currentPage++;
    await _loadPosts();
  }

  Future<(bool, String?)> deletePost(String postId) async {
    try {
      await _api.deletePost(postId: postId);
      // Remove from my posts immediately
      refresh();
      // Synchronize deletion with the main feed
      ref.read(postsFeedProvider.notifier).refresh();
      return (true, null);
    } catch (e) {
      // Log the error for debugging
      print('DEBUG: Error deleting post $postId: $e');
      final errorMsg = e.toString();
      return (false, errorMsg);
    }
  }
}

// Edit post form provider
final editPostFormProvider =
    StateNotifierProvider.family<EditPostNotifier, EditPostState, PostModel>((ref, post) {
  return EditPostNotifier(ref, post);
});

class EditPostState {
  final String content;
  final bool isSubmitting;
  final String? pickedImagePath;
  final String? existingImageUrl;
  final bool hasRemovedImage;
  final String? error;

  const EditPostState({
    this.content = '',
    this.isSubmitting = false,
    this.pickedImagePath,
    this.existingImageUrl,
    this.hasRemovedImage = false,
    this.error,
  });

  bool get isValid => content.trim().isNotEmpty;

  EditPostState copyWith({
    String? content,
    bool? isSubmitting,
    String? pickedImagePath,
    String? existingImageUrl,
    bool? hasRemovedImage,
    String? error,
  }) {
    return EditPostState(
      content: content ?? this.content,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      pickedImagePath: pickedImagePath ?? this.pickedImagePath,
      existingImageUrl: existingImageUrl ?? this.existingImageUrl,
      hasRemovedImage: hasRemovedImage ?? this.hasRemovedImage,
      error: error ?? this.error,
    );
  }
}

class EditPostNotifier extends StateNotifier<EditPostState> {
  final Ref ref;
  final PostModel post;
  final ApiEndpoints _api = ApiEndpoints();

  EditPostNotifier(this.ref, this.post)
      : super(EditPostState(
          content: post.content,
          existingImageUrl: post.imageUrl,
        ));

  void updateContent(String content) {
    state = state.copyWith(content: content, error: null);
  }

  void setPickedImage(String? path) {
    state = state.copyWith(
      pickedImagePath: path,
      hasRemovedImage: path == null ? state.hasRemovedImage : false,
    );
  }

  void clearImage() {
    state = state.copyWith(
      pickedImagePath: null,
      existingImageUrl: null,
      hasRemovedImage: true,
    );
  }

  Future<bool> submit() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please write something about your inquiry');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      String? imagePathToSend;
      if (state.pickedImagePath != null) {
        imagePathToSend = state.pickedImagePath;
      } else if (!state.hasRemovedImage) {
        imagePathToSend = state.existingImageUrl;
      }

      await _api.updatePost(
        postId: post.id,
        content: state.content,
        filePath: imagePathToSend,
      );

      // Refresh the feeds immediately
      ref.read(postsFeedProvider.notifier).refresh();
      ref.read(myPostsProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

// Selected post provider (for navigation to details)
final selectedPostProvider = StateProvider<PostModel?>((ref) => null);

// Create post form provider
final createPostFormProvider =
    StateNotifierProvider<CreatePostNotifier, CreatePostState>((ref) {
  return CreatePostNotifier(ref);
});

class CreatePostState {
  final String content;
  final PostCategory category;
  final bool isSubmitting;
  final bool hasImage;
  final String? pickedImagePath;
  final String? error;

  const CreatePostState({
    this.content = '',
    this.category = PostCategory.general,
    this.isSubmitting = false,
    this.hasImage = false,
    this.pickedImagePath,
    this.error,
  });

  bool get isValid => content.trim().isNotEmpty;

  CreatePostState copyWith({
    String? content,
    PostCategory? category,
    bool? isSubmitting,
    bool? hasImage,
    String? pickedImagePath,
    String? error,
  }) {
    return CreatePostState(
      content: content ?? this.content,
      category: category ?? this.category,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasImage: hasImage ?? this.hasImage,
      pickedImagePath: pickedImagePath ?? this.pickedImagePath,
      error: error ?? this.error,
    );
  }
}

class CreatePostNotifier extends StateNotifier<CreatePostState> {
  final Ref ref;
  final ApiEndpoints _api = ApiEndpoints();

  CreatePostNotifier(this.ref) : super(const CreatePostState());

  void updateContent(String content) {
    state = state.copyWith(content: content, error: null);
  }

  void updateCategory(PostCategory category) {
    state = state.copyWith(category: category);
  }

  void setPickedImage(String? path) {
    state = state.copyWith(pickedImagePath: path, hasImage: path != null);
  }

  void clearImage() {
    state = state.copyWith(pickedImagePath: null, hasImage: false);
  }

  void toggleImage() {
    state = state.copyWith(hasImage: !state.hasImage);
  }

  Future<bool> submit() async {
    if (!state.isValid) {
      state = state.copyWith(error: 'Please write something about your inquiry');
      return false;
    }

    state = state.copyWith(isSubmitting: true, error: null);

    try {
      await _api.createPost(
        content: state.content,
        filePath: state.pickedImagePath,
      );

      state = const CreatePostState();
      // Refresh the feeds immediately
      ref.read(postsFeedProvider.notifier).refresh();
      ref.read(myPostsProvider.notifier).refresh();
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}

// Post details replies state notifier provider
class PostRepliesNotifier extends StateNotifier<AsyncValue<List<ReplyModel>>> {
  final PostModel post;
  final ApiEndpoints _api = ApiEndpoints();
  final Ref ref;

  PostRepliesNotifier(this.ref, this.post)
      : super(AsyncValue.data(post.replies));

  Future<bool> addReply(String replyContent) async {
    try {
      // Get pharmacy ID from current pharmacy mode
      final currentPharmacy = ref.read(currentPharmacyProvider);
      if (currentPharmacy == null) {
        state = AsyncValue.error('Not in pharmacy mode', StackTrace.current);
        return false;
      }

      final response = await _api.replyToPost(
        postId: int.parse(post.id),
        replyContent: replyContent,
        receiverId: post.userId,
        pharmacyId: currentPharmacy.id,
      );

      // API returns a numeric ID, create a minimal reply model with essential data
      // The reply will be properly loaded when feed refreshes
      final replyId = response is int ? response : (response['id'] ?? 0);
      final newReply = ReplyModel(
        id: replyId.toString(),
        postId: post.id,
        pharmacyId: currentPharmacy.id,
        pharmacyName: currentPharmacy.name,
        content: replyContent,
        createdAt: DateTime.now(),
      );
      
      // Add the new reply to the current list (optimistic update)
      final currentReplies = state.value ?? [];
      final updatedReplies = [...currentReplies, newReply];
      state = AsyncValue.data(updatedReplies);

      // Refresh post feeds in background to sync with server data
      // This ensures we get the complete reply data (verified status, etc.)
      await Future.delayed(const Duration(milliseconds: 800));
      await ref.read(postsFeedProvider.notifier).refresh();
      await ref.read(myPostsProvider.notifier).refresh();

      return true;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      return false;
    }
  }
}

final postRepliesNotifierProvider = StateNotifierProvider.family<
    PostRepliesNotifier, AsyncValue<List<ReplyModel>>, PostModel>((ref, post) {
  return PostRepliesNotifier(ref, post);
});

// Legacy family provider for backward compatibility
final postRepliesProvider =
    FutureProvider.family<List<ReplyModel>, String>((ref, postId) async {
  // Return nested replies from the current feed state or mock
  final posts = ref.read(postsFeedProvider).value ?? [];
  final post = posts.firstWhere((p) => p.id == postId, orElse: () => PostModel.sample().first);
  return post.replies;
});

// Bookmark provider
final bookmarkedPostsProvider = StateProvider<Set<String>>((ref) => {});

// Sort option enum
enum PostsSort { latest, mostReplied, nearby }

final postsSortProvider = StateProvider<PostsSort>((ref) => PostsSort.latest);
