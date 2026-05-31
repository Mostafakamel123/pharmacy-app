import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/features/posts/model/post_model.dart';

// Selected category filter provider
final selectedCategoryProvider = StateProvider<PostCategory?>((ref) => null);

// Posts feed provider
final postsFeedProvider =
    StateNotifierProvider<PostsFeedNotifier, AsyncValue<List<PostModel>>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  return PostsFeedNotifier(category);
});

class PostsFeedNotifier extends StateNotifier<AsyncValue<List<PostModel>>> {
  final PostCategory? _filterCategory;

  PostsFeedNotifier(this._filterCategory) : super(const AsyncValue.loading()) {
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      await Future.delayed(const Duration(milliseconds: 600));
      var posts = PostModel.sample();
      if (_filterCategory != null) {
        posts = posts.where((p) => p.category == _filterCategory).toList();
      }
      state = AsyncValue.data(posts);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    await _loadPosts();
  }
}

// Selected post provider (for navigation to details)
final selectedPostProvider = StateProvider<PostModel?>((ref) => null);

// Create post form provider
final createPostFormProvider =
    StateNotifierProvider<CreatePostNotifier, CreatePostState>((ref) {
  return CreatePostNotifier();
});

class CreatePostState {
  final String content;
  final PostCategory category;
  final bool isSubmitting;
  final bool hasImage;
  final String? error;

  const CreatePostState({
    this.content = '',
    this.category = PostCategory.general,
    this.isSubmitting = false,
    this.hasImage = false,
    this.error,
  });

  bool get isValid => content.trim().isNotEmpty;

  CreatePostState copyWith({
    String? content,
    PostCategory? category,
    bool? isSubmitting,
    bool? hasImage,
    String? error,
  }) {
    return CreatePostState(
      content: content ?? this.content,
      category: category ?? this.category,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasImage: hasImage ?? this.hasImage,
      error: error ?? this.error,
    );
  }
}

class CreatePostNotifier extends StateNotifier<CreatePostState> {
  CreatePostNotifier() : super(const CreatePostState());

  void updateContent(String content) {
    state = state.copyWith(content: content, error: null);
  }

  void updateCategory(PostCategory category) {
    state = state.copyWith(category: category);
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

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    state = const CreatePostState();
    return true;
  }
}

// Post details provider
final postRepliesProvider =
    FutureProvider.family<List<ReplyModel>, String>((ref, postId) async {
  await Future.delayed(const Duration(milliseconds: 500));
  return ReplyModel.sampleForPost(postId);
});

// Bookmark provider
final bookmarkedPostsProvider = StateProvider<Set<String>>((ref) => {});

// Sort option enum
enum PostsSort { latest, mostReplied, nearby }

final postsSortProvider = StateProvider<PostsSort>((ref) => PostsSort.latest);
