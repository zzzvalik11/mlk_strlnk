/// Formats a [DateTime] to a Russian locale string.
///
/// Example: `DateTime(2025, 8, 11)` → "11 августа 2025"
class DateFormatter {
  DateFormatter._();

  static const Map<int, String> _monthNames = {
    1: 'января',
    2: 'февраля',
    3: 'марта',
    4: 'апреля',
    5: 'мая',
    6: 'июня',
    7: 'июля',
    8: 'августа',
    9: 'сентября',
    10: 'октября',
    11: 'ноября',
    12: 'декабря',
  };

  /// Formats [date] as "d monthName yyyy" in Russian.
  static String formatDate(DateTime date) {
    final day = date.day;
    final month = _monthNames[date.month] ?? '';
    final year = date.year;
    return '$day $month $year';
  }

  /// Formats [date] as "до d monthName" (used for paidUntil labels).
  static String formatPaidUntil(DateTime date) {
    final day = date.day;
    final month = _monthNames[date.month] ?? '';
    return 'до $day $month';
  }

  /// Formats [date] with time: "d monthName yyyy, HH:mm".
  static String formatDateTime(DateTime date) {
    final day = date.day;
    final month = _monthNames[date.month] ?? '';
    final year = date.year;
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }
}
