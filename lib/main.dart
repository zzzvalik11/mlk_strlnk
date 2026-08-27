import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:telecom_dashboard/core/constants/app_constants.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/data/local/storage_service.dart';
import 'package:telecom_dashboard/data/services/fcm_service.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';
import 'package:telecom_dashboard/presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env — gracefully skip if missing (web / CI / no .env file).
  // app_constants.dart uses fallback values when dotenv is empty.
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env not found in asset bundle — OK, fallbacks in AppConstants will be used.
  }

  // Firebase — gracefully skip if not configured (e.g. web without Firebase).
  try {
    await Firebase.initializeApp();

    // FCM push notifications
    final fcmService = FcmService();
    await fcmService.init();
    print('[FCM] Device token: ${fcmService.currentToken}');
  } catch (e) {
    print('[Firebase] Init skipped: $e');
  }

  // Initialize SharedPreferences-backed storage before any provider uses it.
  // On web or if SharedPreferences fails, the app still starts —
  // providers that need storage will handle null/uninitialized state.
  final storageService = StorageService();
  try {
    await storageService.init();
  } catch (e) {
    print('[Storage] Init skipped: $e');
  }

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const TelecomApp(),
    ),
  );
}

class TelecomApp extends ConsumerWidget {
  const TelecomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Starlink',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: AppTheme.orange500,
        scaffoldBackgroundColor: AppTheme.orange50,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppTheme.orange50,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.orange500,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: AppTheme.inputRadius,
            borderSide: BorderSide(color: AppTheme.gray200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppTheme.inputRadius,
            borderSide: BorderSide(color: AppTheme.gray200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppTheme.inputRadius,
            borderSide: BorderSide(color: AppTheme.orange500, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
    );
  }
}
