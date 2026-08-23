import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';
import 'package:telecom_dashboard/data/local/storage_service.dart';
import 'package:telecom_dashboard/presentation/providers/auth_provider.dart';
import 'package:telecom_dashboard/presentation/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences-backed storage before any provider uses it.
  final storageService = StorageService();
  await storageService.init();

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
      locale: const Locale('ru', 'RU'),
      supportedLocales: const [Locale('ru', 'RU')],
    );
  }
}
