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

  /// Validates an email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите E-mail';
    }
    final email = value.trim();
    final regex = RegExp(r'^[\w.\-+]+@[\w\-]+(\.[\w\-]+)+$');
    if (!regex.hasMatch(email)) {
      return 'Введите корректный E-mail';
    }
    return null;
  }

  /// Validates a Russian mobile phone number.
  ///
  /// Accepts formats like +79001234567, 79001234567, 9001234567.
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите номер телефона';
    }
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.length != 11) {
      return 'Номер должен содержать 11 цифр (например +79001234567)';
    }
    if (!digits.startsWith('7')) {
      return 'Номер должен начинаться с 7 (формат +7XXXXXXXXXX)';
    }
    return null;
  }

  /// Formats phone input to +7XXXXXXXXXX.
  static String formatPhone(String value) {
    final digits = value.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('8')) return '+7${digits.substring(1)}';
    if (digits.startsWith('7')) return '+$digits';
    return '+7$digits';
  }

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
