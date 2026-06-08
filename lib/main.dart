import 'package:Elaaj/core/helpers/local_storage_helper.dart';
import 'package:Elaaj/core/routing/app_router.dart';
import 'package:Elaaj/core/theme/app_theme.dart';
import 'package:Elaaj/features/profile/controller/profile_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize local storage
  await LocalStorageHelper.init();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );


  Future.delayed(const Duration(seconds: 0), () {
    FlutterNativeSplash.remove();
  });
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Elaaj',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
