import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:telecom_dashboard/core/constants/themes.dart';

void main() {
  runApp(const _DiagnosticApp());
}

/// DIAGNOSTIC: If you see GREEN screen with white text → code delivery works.
/// If you still see orange/white blank screen → you are NOT running this code.
class _DiagnosticApp extends StatelessWidget {
  const _DiagnosticApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.green,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.check_circle, color: Colors.white, size: 80),
              SizedBox(height: 24),
              Text(
                'CODE DELIVERY OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'If you see this, git pull works.',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
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
