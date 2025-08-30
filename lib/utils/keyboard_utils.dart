import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utility class for handling keyboard operations across the app
class KeyboardUtils {
  /// Dismiss keyboard globally
  static void dismissKeyboard() {
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  /// Dismiss keyboard by unfocusing current focus node
  static void dismissKeyboardByUnfocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Check if keyboard is currently visible
  static bool isKeyboardVisible(BuildContext context) {
    return MediaQuery.of(context).viewInsets.bottom > 0;
  }

  /// Dismiss keyboard when tapping outside
  static Widget dismissKeyboardOnTap({
    required Widget child,
    bool dismissOnTap = true,
  }) {
    if (!dismissOnTap) return child;
    
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
      child: child,
    );
  }

  /// Wrap widget with keyboard dismissal on tap outside
  static Widget withKeyboardDismissal({
    required Widget child,
    bool dismissOnTap = true,
  }) {
    if (!dismissOnTap) return child;
    
    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      },
      child: child,
    );
  }
}

/// Extension for BuildContext to easily dismiss keyboard
extension KeyboardDismissalExtension on BuildContext {
  /// Dismiss keyboard using current context
  void dismissKeyboard() {
    KeyboardUtils.dismissKeyboardByUnfocus(this);
  }

  /// Check if keyboard is visible
  bool get isKeyboardVisible => KeyboardUtils.isKeyboardVisible(this);
}

/// Mixin for widgets that need keyboard dismissal functionality
mixin KeyboardDismissalMixin<T extends StatefulWidget> on State<T> {
  /// Dismiss keyboard
  void dismissKeyboard() {
    KeyboardUtils.dismissKeyboard();
  }

  /// Dismiss keyboard by unfocusing
  void dismissKeyboardByUnfocus() {
    KeyboardUtils.dismissKeyboardByUnfocus(context);
  }

  /// Wrap child with keyboard dismissal
  Widget withKeyboardDismissal(Widget child, {bool dismissOnTap = true}) {
    return KeyboardUtils.withKeyboardDismissal(
      child: child,
      dismissOnTap: dismissOnTap,
    );
  }
}
