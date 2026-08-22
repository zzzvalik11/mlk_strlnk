/// Input validators for auth forms.
class Validators {
  Validators._();

  /// Validates a PIN code.
  ///
  /// Returns an error message string if invalid, or `null` if valid.
  /// Expected: exactly 6 numeric digits.
  static String? validatePin(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите ПИН-код';
    }

    final pin = value.trim();

    if (pin.length != 6) {
      return 'ПИН-код должен содержать 6 цифр';
    }

    final isNumeric = RegExp(r'^\d{6}$').hasMatch(pin);
    if (!isNumeric) {
      return 'ПИН-код должен содержать только цифры';
    }

    return null;
  }

  /// Validates a password.
  ///
  /// Returns an error message string if invalid, or `null` if valid.
  /// Minimum 6 characters.
  static String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите пароль';
    }

    final password = value.trim();

    if (password.length < 6) {
      return 'Пароль должен содержать минимум 6 символов';
    }

    return null;
  }
}
