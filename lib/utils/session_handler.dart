import 'package:flutter/material.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/navigation/app_routes.dart';
import 'package:truebpm/navigation/navigation_service.dart';

class SessionHandler {
  static Future<bool> handleSessionExpired(BuildContext context) async {
    try {
      final authService = AuthService();
      // Thử auto-login nếu có credentials đã lưu
      final result = await authService.loginWithSavedCredentials();
      if (result.isSuccess) {
        // Login lại thành công
        return true;
      }
    } catch (e) {
      // Auto-login thất bại hoặc không có credentials
    }
    
    // Nếu auto-login thất bại, hiển thị dialog yêu cầu login lại
    if (context.mounted) {
      _showReLoginDialog(context);
    }
    return false;
  }

  static void _showReLoginDialog(BuildContext context) {
    CustomConfirmDialog.showSessionExpired(
      context,
      onConfirm: () {
        // Navigate về login screen bằng root navigator
        NavigationService.replaceAllWith(AppRoutes.login);
      },
    );
  }
}
