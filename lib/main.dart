import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';
import 'package:telecom_dashboard/core/constants/app_constants.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/data/local/storage_service.dart';
import 'package:telecom_dashboard/data/services/fcm_service.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';
import 'package:telecom_dashboard/presentation/router/app_router.dart';
import 'package:telecom_dashboard/presentation/router/auth_change_notifier.dart';

/// Global reference to the ProviderContainer — used by widgets to read
/// authProvider directly (bypasses WidgetRef which triggers
/// NotInitializedError on web through the widget-tree framework layer).
late final ProviderContainer appContainer;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env — gracefully skip if missing (web / CI / no .env file).
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // Firebase — gracefully skip if not configured or on web without options.
  if (!kIsWeb) {
    try {
      await Firebase.initializeApp();
      final fcmService = FcmService();
      await fcmService.init();
    } catch (_) {
      // Firebase not configured — skip silently.
    }
  }

  // Initialize storage.
  final storageService = StorageService();
  try {
    await storageService.init();
  } catch (e) {
    print('[Storage] Init skipped: $e');
  }

  // Create ProviderContainer with overrides.
  appContainer = ProviderContainer(
    overrides: [storageServiceProvider.overrideWithValue(storageService)],
  );

  // Build the router OUTSIDE the widget tree so provider errors
  // (e.g. NotInitializedError from plugins on web) don't crash the build.
  final authChangeNotifier = AuthChangeNotifier(appContainer);
  final router = createGoRouter(authChangeNotifier);

  runApp(
    UncontrolledProviderScope(
      container: appContainer,
      child: TelecomApp(router: router),
    ),
  );
}

class TelecomApp extends StatelessWidget {
  final GoRouter router;
  const TelecomApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
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
        inputDecorationTheme: const InputDecorationTheme(
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
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
