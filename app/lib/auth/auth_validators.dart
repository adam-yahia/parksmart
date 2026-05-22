class AuthValidators {
  static String? validateEmail(String username) {
    if (username.trim().isEmpty) return 'Enter your username.';
    if (username.trim().length < 3) return 'Username must be at least 3 characters.';
    return null;
  }

  static String? validatePassword(String password) {
    if (password.isEmpty) return 'Enter your password.';
    if (password.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }
}
