import 'package:truebpm/utils/global_store.dart';

/// Validation utilities for login forms
class LoginValidators {
  /// Validates username input
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return appStrings.usernameRequired;
    }
    return null;
  }

  /// Validates password input
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return appStrings.passwordRequired;
    }
    return null;
  }
}
