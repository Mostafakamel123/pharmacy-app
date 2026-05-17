import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pharmacy_app/core/routing/app_router.dart';
import 'package:pharmacy_app/core/theme/app_theme.dart';
import 'package:pharmacy_app/core/helpers/local_storage_helper.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize local storage
  await LocalStorageHelper.init();

  // Enable performance overlay for debugging (optional, disable in production)
  // WidgetsApp.showPerformanceOverlayOverride = false;

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );

  Future.delayed(const Duration(seconds: 0), () {
    FlutterNativeSplash.remove();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Elaaj',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      // Performance optimizations
      builder: (context, child) {
        // Prevent text scaling from breaking layout
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // Disable text scaling for consistent UI (or limit it)
            textScaler: TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
