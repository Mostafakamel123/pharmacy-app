import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:pharmacy_app/core/routing/app_router.dart';
import 'package:pharmacy_app/core/utils/user_role.dart';
import 'package:pharmacy_app/features/navigation/widgets/premium_nav_shell.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  runApp(const MyApp());

  // Remove splash after 3 seconds
  Future.delayed(const Duration(seconds: 5), () {
    FlutterNativeSplash.remove();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Toggle this to test different user roles: UserRole.patient or UserRole.pharmacy
  static const UserRole demoUserRole = UserRole.patient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Elaaj - Pharmacy App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5E9),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5E9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF111827),
      ),
      themeMode: ThemeMode.system, // Auto dark mode based on system setting
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      
      // Demo: Uncomment below to use the premium navigation shell
      // home: PremiumNavShell(userRole: demoUserRole),
    );
  }
}









