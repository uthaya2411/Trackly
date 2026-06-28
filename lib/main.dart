import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/local_storage_service.dart';
import 'firebase_options.dart';
import 'presentation/providers/expense_provider.dart';
import 'presentation/screens/splash_screen.dart';

void main() async {
  // Ensure Flutter engine integrations are initialized before async boots
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize offline persistent shared preferences
  final storageService = await LocalStorageService.init();

  runApp(
    ProviderScope(
      overrides: [
        // Inject the initialized storage service directly into Riverpod
        localStorageProvider.overrideWithValue(storageService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to our global expense notifier state to react to theme toggles
    final state = ref.watch(expenseProvider);

    return MaterialApp(
      title: 'Trackly Pro',
      debugShowCheckedModeBanner: false,

      // Dynamic Material 3 double theme support
      themeMode: state.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      darkTheme: AppTheme.darkTheme,
      theme: AppTheme.lightTheme,

      // Load custom animated onboarding entry splash
      home: const SplashScreen(),
    );
  }
}
