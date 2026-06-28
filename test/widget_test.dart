import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:trackly/main.dart';
import 'package:trackly/data/repositories/local_storage_service.dart';
import 'package:trackly/presentation/providers/expense_provider.dart';

void setupFirebaseAuthMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FirebasePlatform.instance = MockFirebasePlatform();
}

class MockFirebasePlatform extends FirebasePlatform {
  MockFirebasePlatform() : super();

  @override
  Future<FirebaseAppPlatform> initializeApp({
    String? name,
    FirebaseOptions? options,
  }) async {
    return MockFirebaseApp(name: name ?? defaultFirebaseAppName, options: options);
  }

  @override
  FirebaseAppPlatform app([String name = defaultFirebaseAppName]) {
    return MockFirebaseApp(name: name);
  }
}

class MockFirebaseApp extends FirebaseAppPlatform {
  MockFirebaseApp({required String name, FirebaseOptions? options})
      : super(
          name,
          options ??
              const FirebaseOptions(
                apiKey: 'test',
                appId: 'test',
                messagingSenderId: 'test',
                projectId: 'test',
              ),
        );
}

void main() {
  setupFirebaseAuthMocks();

  setUpAll(() async {
    await Firebase.initializeApp();
  });

  testWidgets('Trackly Pro smoke test - boots successfully on SplashScreen', (
    WidgetTester tester,
  ) async {
    // Seed Mock values in-memory to prevent SharedPreferences errors
    SharedPreferences.setMockInitialValues({});
    final storageService = await LocalStorageService.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storageService)],
        child: const MyApp(),
      ),
    );

    // Re-draw animations frame
    await tester.pump();

    // Verify splash elements are present
    expect(find.text('TRACKLY PRO'), findsOneWidget);
    expect(find.text('PREMIUM WEALTH INTELLIGENCE'), findsOneWidget);
  });
}
