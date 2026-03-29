class AuthValidators {
  static String? requiredField(String? value, {String label = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  static String? email(String? value) {
    final requiredError = requiredField(value, label: 'Email');
    if (requiredError != null) {
      return requiredError;
    }
    final trimmed = value!.trim();
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? password(String? value) {
    final requiredError = requiredField(value, label: 'Password');
    if (requiredError != null) {
      return requiredError;
    }
    if (value!.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    final requiredError = requiredField(value, label: 'Confirm password');
    if (requiredError != null) {
      return requiredError;
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
