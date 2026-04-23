import 'package:pharmacy_app/core/config/env_config.dart';


class ApiEndpoints {
  ApiEndpoints._();

  static const String _baseUrl = EnvConfig.apiBaseUrl;

  // ========================= Authentication =========================

  /// POST /auth/signup - User registration
  static const String signup = '$_baseUrl/auth/signup';

  /// POST /auth/login - User login
  static const String login = '$_baseUrl/auth/login';

  /// POST /auth/logout - User logout
  static const String logout = '$_baseUrl/auth/logout';

  /// POST /auth/refresh-token - Refresh authentication token
  static const String refreshToken = '$_baseUrl/auth/refresh-token';

  /// POST /auth/forgot-password - Request password reset
  static const String forgotPassword = '$_baseUrl/auth/forgot-password';

  /// POST /auth/reset-password - Reset password with token
  static const String resetPassword = '$_baseUrl/auth/reset-password';

  // ========================= User & Profile =========================

  /// GET /users/{userId} - Get user profile
  static String userProfile(String userId) => '$_baseUrl/users/$userId';

  /// PUT /users/{userId} - Update user profile
  static String updateProfile(String userId) => '$_baseUrl/users/$userId';

  /// GET /users/{userId}/stats - Get user statistics
  static String userStats(String userId) => '$_baseUrl/users/$userId/stats';

  /// GET /users/{userId}/activity - Get user activity history
  static String userActivity(String userId) => '$_baseUrl/users/$userId/activity';

  // ========================= Pharmacies =========================

  /// GET /pharmacies/nearby - Get nearby pharmacies
  static const String nearbyPharmacies = '$_baseUrl/pharmacies/nearby';

  /// GET /pharmacies/{pharmacyId} - Get pharmacy details
  static String pharmacyDetails(String pharmacyId) =>
      '$_baseUrl/pharmacies/$pharmacyId';

  /// GET /pharmacies/search - Search pharmacies
  static const String searchPharmacies = '$_baseUrl/pharmacies/search';

  /// GET /pharmacies/{pharmacyId}/hours - Get pharmacy opening hours
  static String pharmacyHours(String pharmacyId) =>
      '$_baseUrl/pharmacies/$pharmacyId/hours';

  /// GET /pharmacies/{pharmacyId}/reviews - Get pharmacy reviews
  static String pharmacyReviews(String pharmacyId) =>
      '$_baseUrl/pharmacies/$pharmacyId/reviews';

  /// POST /pharmacies/{pharmacyId}/favorite - Add pharmacy to favorites
  static String addToFavorites(String pharmacyId) =>
      '$_baseUrl/pharmacies/$pharmacyId/favorite';

  /// DELETE /pharmacies/{pharmacyId}/favorite - Remove from favorites
  static String removeFromFavorites(String pharmacyId) =>
      '$_baseUrl/pharmacies/$pharmacyId/favorite';

  /// GET /pharmacies/{pharmacyId}/medicines - Get pharmacy's medicines
  static String pharmacyMedicines(String pharmacyId) =>
      '$_baseUrl/pharmacies/$pharmacyId/medicines';

  // ========================= Posts/Q&A Forum =========================

  /// GET /posts - Get posts feed
  static const String getPosts = '$_baseUrl/posts';

  /// GET /posts/{postId} - Get post details
  static String getPostDetails(String postId) => '$_baseUrl/posts/$postId';

  /// POST /posts - Create new post
  static const String createPost = '$_baseUrl/posts';

  /// PUT /posts/{postId} - Update post
  static String updatePost(String postId) => '$_baseUrl/posts/$postId';

  /// DELETE /posts/{postId} - Delete post
  static String deletePost(String postId) => '$_baseUrl/posts/$postId';

  /// POST /posts/{postId}/replies - Reply to a post
  static String replyToPost(String postId) => '$_baseUrl/posts/$postId/replies';

  /// GET /posts/{postId}/replies - Get post replies
  static String getPostReplies(String postId) =>
      '$_baseUrl/posts/$postId/replies';

  /// POST /posts/{postId}/bookmark - Bookmark a post
  static String bookmarkPost(String postId) =>
      '$_baseUrl/posts/$postId/bookmark';

  /// DELETE /posts/{postId}/bookmark - Remove post from bookmarks
  static String removeBookmark(String postId) =>
      '$_baseUrl/posts/$postId/bookmark';

  /// GET /posts/bookmarks - Get bookmarked posts
  static const String getBookmarkedPosts = '$_baseUrl/posts/bookmarks';

  // ========================= Prescriptions =========================

  /// POST /prescriptions - Upload a new prescription
  static const String uploadPrescription = '$_baseUrl/prescriptions';

  /// GET /prescriptions - Get user's prescriptions
  static const String getPrescriptions = '$_baseUrl/prescriptions';

  /// GET /prescriptions/{prescriptionId} - Get prescription details
  static String getPrescriptionDetails(String prescriptionId) =>
      '$_baseUrl/prescriptions/$prescriptionId';

  /// DELETE /prescriptions/{prescriptionId} - Delete prescription
  static String deletePrescription(String prescriptionId) =>
      '$_baseUrl/prescriptions/$prescriptionId';

  /// GET /prescriptions/{prescriptionId}/nearby-pharmacies - Get pharmacies with medicine
  static String prescriptionNearbyPharmacies(String prescriptionId) =>
      '$_baseUrl/prescriptions/$prescriptionId/nearby-pharmacies';

  /// POST /prescriptions/{prescriptionId}/check-availability - Check availability
  static String checkMedicineAvailability(String prescriptionId) =>
      '$_baseUrl/prescriptions/$prescriptionId/check-availability';

  // ========================= Medicines =========================

  /// GET /medicines/search - Search for medicines
  static const String searchMedicines = '$_baseUrl/medicines/search';

  /// GET /medicines/{medicineId}/availability - Check medicine availability
  static String medicineAvailability(String medicineId) =>
      '$_baseUrl/medicines/$medicineId/availability';

  // ========================= Chat & Messaging =========================

  /// POST /chats - Start new chat
  static const String startChat = '$_baseUrl/chats';

  /// GET /chats - Get all chats
  static const String getChats = '$_baseUrl/chats';

  /// GET /chats/{chatId}/messages - Get messages from a chat
  static String getChatMessages(String chatId) => '$_baseUrl/chats/$chatId/messages';

  /// POST /chats/{chatId}/messages - Send message to chat
  static String sendMessage(String chatId) => '$_baseUrl/chats/$chatId/messages';

  /// PUT /chats/{chatId}/read - Mark messages as read
  static String markAsRead(String chatId) => '$_baseUrl/chats/$chatId/read';

  /// WebSocket connection for real-time chat
  static const String chatSocket = '${EnvConfig.socketBaseUrl}/socket/chat';

  // ========================= Utility Methods =========================

  /// Check if endpoint is public (no auth required)
  static bool isPublicEndpoint(String endpoint) {
    const publicEndpoints = [
      signup,
      login,
      forgotPassword,
      resetPassword,
    ];
    return publicEndpoints.contains(endpoint);
  }

  /// Get endpoint name for logging/debugging
  static String getEndpointName(String endpoint) {
    return endpoint.replaceAll(_baseUrl, '').replaceAll('/', '_');
  }
}
