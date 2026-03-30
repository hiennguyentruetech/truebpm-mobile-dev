import 'package:flutter/material.dart';
import 'package:truebpm/widgets/dialogs/app_themed_dialog.dart';
import 'package:truebpm/widgets/core/core_action_print_dialog.dart';

export 'package:truebpm/widgets/core/core_action_print_dialog.dart'
    show PrintReportOption;

/// Response dialog for API actions
class CoreActionDialog {
  /// Show response dialog based on API response
  static void showResponseDialog(
    BuildContext context, {
    required Map<String, dynamic> response,
    String? title,
    VoidCallback? onSuccess,
  }) {
    final success = response['success'] == true;
    final messageType = response['messageType']?.toString().toLowerCase() ?? '';
    final message =
        response['message']?.toString() ??
        (success ? 'Operation completed successfully' : 'Operation failed');

    // Determine colors and icon based on messageType
    switch (messageType) {
      case 'success':
        break;
      case 'error':
        break;
      case 'warning':
        break;
      default:
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AppThemedDialog(
        title: title ?? (success ? 'Success' : 'Error'),
        message: message,
        type: switch (messageType) {
          'success' => AppDialogType.success,
          'warning' => AppDialogType.warning,
          'error' => AppDialogType.error,
          _ => success ? AppDialogType.success : AppDialogType.info,
        },
        confirmText: 'OK',
        onConfirm: () {
          Navigator.of(context).pop();
          if (success && onSuccess != null) {
            onSuccess();
          }
        },
      ),
    );
  }

  /// Show print report selection dialog
  static void showPrintDialog(
    BuildContext context, {
    required List<PrintReportOption> reports,
    required Function(String url) onReportSelected,
    Map<String, dynamic>? itemDetail,
  }) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) => CoreActionPrintDialog(
        reports: reports,
        primaryColor: primaryColor,
        onReportSelected: onReportSelected,
        itemDetail: itemDetail,
      ),
    );
  }
}
