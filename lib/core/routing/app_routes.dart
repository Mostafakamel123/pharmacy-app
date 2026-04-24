class AppRoutes {
  // Splash and Onboarding
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  
  // Auth
  static const String auth = '/auth';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  
  // Home
  static const String home = '/home';
  
  // Chat
  static const String chats = '/chats';
  static const String chat = '/chat/:chatId';
  
  // Prescription Routing Feature
  static const String prescription = '/prescription';
  static const String uploadPrescription = '/prescription/upload';
  static const String searchingPharmacies = '/prescription/searching';
  
  // Error
  static const String notFound = '/404';
}
