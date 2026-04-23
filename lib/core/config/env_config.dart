
class EnvConfig {
  EnvConfig._();

  // ========================= API Configuration =========================
  
  //
  static const String apiBaseUrl = 'https://api.pharmacy-app.com';

  static const String socketBaseUrl = 'wss://api.pharmacy-app.com';

  // ========================= Timeouts =========================

  /// Request timeout duration in milliseconds
  static const int requestTimeout = 30000; // 30 seconds

  /// Connection timeout duration in milliseconds
  static const int connectionTimeout = 15000; // 15 seconds

  /// Receive timeout duration in milliseconds
  static const int receiveTimeout = 30000; // 30 seconds

  // ========================= API Keys & Tokens =========================

  
  static const String apiKey = 'your-api-key-here';

  /// Firebase or other service keys can be added here
  static const String firebaseProjectId = 'your-firebase-project-id';

  // ========================= Feature Flags =========================

  /// Enable/disable logging in production
  static const bool enableLogging = true;

  /// Enable/disable network interceptor debugging
  static const bool enableNetworkDebug = true;

  // ========================= Build Configuration =========================

  /// App version
  static const String appVersion = '1.0.0';

  /// Build number
  static const String buildNumber = '1';
}
