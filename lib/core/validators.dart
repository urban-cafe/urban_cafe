class AppValidators {
  // Validates that the field is not empty
  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} cannot be empty';
    }
    return null;
  }

  // Validates email format
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  // Validates that the value is a valid number
  static String? number(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Price'} cannot be empty';
    }
    if (double.tryParse(value) == null) {
      return 'Please enter a valid number';
    }
    return null;
  }

  // Validates password (matches Supabase requirements)
  // - Minimum 8 characters
  // - Must contain: lowercase, uppercase, digits, and symbols
  static String? password(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    // Check for lowercase letter
    if (!RegExp(r'[a-z]').hasMatch(value)) {
      return 'Password must contain at least one lowercase letter';
    }

    // Check for uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter';
    }

    // Check for digit
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return 'Password must contain at least one digit';
    }

    // Check for symbol/special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return 'Password must contain at least one symbol (!@#\$%^&*...)';
    }

    return null;
  }

  // Validates that two values match (e.g. confirm password)
  static String? Function(String?) confirmPassword(String Function() getPassword) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return 'Please confirm your password';
      }
      if (value != getPassword()) {
        return 'Passwords do not match';
      }
      return null;
    };
  }
}
