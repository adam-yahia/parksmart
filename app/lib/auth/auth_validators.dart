class AuthValidators {
  // Standard RFC-compliant email pattern — accepts any domain
  static final RegExp _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    caseSensitive: false,
  );

  static String? validateEmail(String email) {
    if (email.trim().isEmpty) return 'Enter your email.';
    if (!_emailRegex.hasMatch(email.trim())) return 'Enter a valid email.';
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Enter your password.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }
}
