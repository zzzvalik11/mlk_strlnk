import 'package:intl/intl.dart';

/// Formats a monetary amount in RUB with Russian locale.
///
/// Example: `formatCurrency(112.5)` → "112,50 ₽"
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'ru_RU',
    symbol: '₽',
    decimalDigits: 2,
  );

  /// Formats [amount] as a Russian currency string.
  static String formatCurrency(double amount) {
    return _formatter.format(amount);
  }

  /// Formats [amount] with a custom number of decimal places.
  static String formatCurrencyCustom(
    double amount, {
    int decimalDigits = 2,
  }) {
    final formatter = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: '₽',
      decimalDigits: decimalDigits,
    );
    return formatter.format(amount);
  }

  /// Formats a signed amount with + or - prefix.
  static String formatSignedCurrency(double amount) {
    final sign = amount >= 0 ? '+' : '';
    return '$sign${_formatter.format(amount)}';
  }
}
