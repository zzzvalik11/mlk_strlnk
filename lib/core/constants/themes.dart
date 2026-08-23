import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // ─── Brand Colors ───────────────────────────────────────────
  static const Color orange500 = Color(0xFFF37021);
  static const Color orange50 = Color(0xFFFFF5F0);
  static const Color orange100 = Color(0xFFFFEADB);
  static const Color orange200 = Color(0xFFFFD4B5);
  static const Color orange600 = Color(0xFFD95F12);
  static const Color orange700 = Color(0xFFC04E0D);

  // ─── Neutrals ───────────────────────────────────────────────
  static const Color gray50 = Color(0xFFF9FAFB);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // ─── Semantic Colors ────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Text Styles ────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: gray900,
    height: 1.2,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: gray900,
    height: 1.3,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: gray900,
    height: 1.4,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: gray900,
    height: 1.4,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: gray700,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: gray600,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: gray500,
    height: 1.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: gray500,
    height: 1.4,
  );

  // ─── Balance Amount ─────────────────────────────────────────
  static const TextStyle balanceAmount = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    color: gray900,
    height: 1.1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle balanceCurrency = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: gray500,
    height: 1.1,
  );

  // ─── Padding Constants ──────────────────────────────────────
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 16,
    vertical: 12,
  );

  static const EdgeInsets cardPadding = EdgeInsets.all(16);

  static const EdgeInsets cardPaddingSmall = EdgeInsets.all(12);

  static const EdgeInsets sectionSpacing = EdgeInsets.only(top: 24);

  static const EdgeInsets bottomNavPadding = EdgeInsets.only(
    top: 8,
    bottom: 24,
  );

  // ─── Border Radius ──────────────────────────────────────────
  static const BorderRadius cardRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius buttonRadius =
      BorderRadius.all(Radius.circular(12));
  static const BorderRadius inputRadius =
      BorderRadius.all(Radius.circular(8));

  // ─── Shadows ────────────────────────────────────────────────
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 10,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> elevatedShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
}
