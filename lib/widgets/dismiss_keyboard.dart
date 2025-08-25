import 'package:flutter/material.dart';

/// A wrapper widget that dismisses the keyboard when tapping outside
/// of any input fields or focusable widgets
/// 
/// This widget should be used to wrap screens or forms that contain
/// input fields to provide a better UX by automatically hiding the
/// keyboard when users tap on empty areas
class DismissKeyboard extends StatelessWidget {
  /// The child widget to wrap
  final Widget child;
  
  /// Whether to dismiss keyboard on tap (default: true)
  final bool dismissOnTap;

  const DismissKeyboard({
    super.key,
    required this.child,
    this.dismissOnTap = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!dismissOnTap) {
      return child;
    }
    
    return GestureDetector(
      onTap: () {
        // Get the current focus node
        final FocusScopeNode currentFocus = FocusScope.of(context);
        
        // If there's a focused widget and it's not the primary focus,
        // unfocus it to dismiss the keyboard
        if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
          currentFocus.unfocus();
        }
      },
      // Allow child widgets to receive their own tap events
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

/// Extension to easily wrap any widget with DismissKeyboard
extension DismissKeyboardExtension on Widget {
  /// Wraps this widget with DismissKeyboard
  Widget dismissKeyboardOnTap({bool dismissOnTap = true}) {
    return DismissKeyboard(
      dismissOnTap: dismissOnTap,
      child: this,
    );
  }
}
