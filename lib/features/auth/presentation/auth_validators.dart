class AuthValidators {
  static String? requiredFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Enter your first name.";
    }

    return null;
  }

  static String? requiredLastNameOrInitial(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Enter your last name or initial.";
    }

    return null;
  }

  static String? email(String? value) {
    final email = value?.trim() ?? "";

    if (email.isEmpty || !email.contains("@")) {
      return "Enter a valid email.";
    }

    return null;
  }

  static String? password(String? value) {
    if (value == null || value.length < 6) {
      return "Min 6 characters.";
    }

    return null;
  }

  static String? confirmPassword({
    required String? value,
    required String password,
  }) {
    if (value == null || value.isEmpty) {
      return "Re-enter your password.";
    }

    if (value != password) {
      return "Passwords do not match.";
    }

    return null;
  }
}
