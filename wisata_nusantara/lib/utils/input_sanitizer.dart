
class InputSanitizer {
  // Sanitasi email
  static String sanitizeEmail(String email) {
    return email.trim();
  }

  // Validasi format email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(email);
  }

  // Sanitasi nama pengguna
  static String sanitizeName(String name) {
    return name
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  // Sanitasi input pencarian
  static String sanitizeSearch(String query) {
    return query
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .trim();
  }

  // Validasi nama pengguna
  static bool isValidName(String name) {
    return name.trim().isNotEmpty && name.trim().length <= 50;
  }
}
