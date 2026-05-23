
class AppConstants {
  AppConstants._();

  // ========================= Durations =========================

  /// Standard animation duration
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Quick animation duration
  static const Duration quickAnimationDuration = Duration(milliseconds: 150);

  /// Splash screen duration
  static const Duration splashDuration = Duration(seconds: 2);

  /// Debounce duration for search
  static const Duration searchDebounce = Duration(milliseconds: 500);

  // ========================= Pagination =========================

  /// Default page size for pagination
  static const int defaultPageSize = 20;

  /// Initial page number
  static const int initialPageNumber = 1;

  // ========================= Validation =========================

  /// Minimum password length
  static const int minPasswordLength = 8;

  /// Minimum username length
  static const int minUsernameLength = 3;

  /// Maximum username length
  static const int maxUsernameLength = 50;

  /// Email regex pattern for validation
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  /// Phone number regex pattern (basic)
  static const String phonePattern = r'^[0-9]{10,15}$';

  // ========================= Local Storage Keys =========================

  /// Key for storing auth token
  static const String authTokenKey = 'auth_token';

  /// Key for storing refresh token
  static const String refreshTokenKey = 'refresh_token';

  /// Key for storing token expiry timestamp (milliseconds since epoch)
  static const String tokenExpiryKey = 'token_expiry';

  /// Key for storing user ID
  static const String userIdKey = 'user_id';

  /// Key for storing user role (patient/pharmacy)
  static const String userRoleKey = 'user_role';

  /// Key for storing user data
  static const String userDataKey = 'user_data';

  /// Key for storing user preferences
  static const String userPrefsKey = 'user_prefs';

  /// Key for storing theme preference
  static const String themeKey = 'theme_mode';

  /// Key for storing language preference
  static const String languageKey = 'language';

  /// Key for storing onboarding completion status
  static const String onboardingCompleteKey = 'onboarding_complete';

  // ========================= Error Messages =========================

  /// Generic error message
  static const String genericError = 'Something went wrong. Please try again.';

  /// Network error message
  static const String networkError =
      'Network error. Please check your internet connection.';

  /// Connection timeout message
  static const String connectionTimeout =
      'Connection timeout. Please try again.';

  /// Server error message
  static const String serverError = 'Server error. Please try again later.';

  /// Unauthorized error message
  static const String unauthorizedError = 'Unauthorized. Please login again.';

  /// Not found error message
  static const String notFoundError = 'Resource not found.';

  /// Validation error message
  static const String validationError = 'Please check your input.';

  // ========================= Success Messages =========================

  /// Generic success message
  static const String genericSuccess = 'Operation successful.';

  /// Login success message
  static const String loginSuccess = 'Logged in successfully.';

  /// Logout success message
  static const String logoutSuccess = 'Logged out successfully.';

  /// Profile updated message
  static const String profileUpdated = 'Profile updated successfully.';

  // ========================= Other Constants =========================

  /// Number of items to load at once
  static const int loadMoreCount = 10;

  /// Maximum retry attempts for failed requests
  static const int maxRetryAttempts = 3;

  /// Delay between retry attempts (in milliseconds)
  static const int retryDelayMs = 1000;
}
