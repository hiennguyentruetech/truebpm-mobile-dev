import 'package:flutter/material.dart';

/// Custom confirm dialog với thiết kế chuyên nghiệp
/// Có thể tái sử dụng cho nhiều mục đích khác nhau trong app
class CustomConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String cancelText;
  final String confirmText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Color? confirmButtonColor;
  final Color? cancelButtonColor;
  final IconData? icon;
  final Color? iconColor;
  final bool isDangerous;

  const CustomConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.cancelText = 'Cancel',
    this.confirmText = 'Confirm',
    this.onConfirm,
    this.onCancel,
    this.confirmButtonColor,
    this.cancelButtonColor,
    this.icon,
    this.iconColor,
    this.isDangerous = false,
  });

  /// Factory constructor cho delete confirmation
  factory CustomConfirmDialog.delete({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
  }) {
    return CustomConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmButtonColor: Colors.red,
      icon: Icons.delete_outline,
      iconColor: Colors.red,
      isDangerous: true,
    );
  }

  /// Factory constructor cho session expired
  factory CustomConfirmDialog.sessionExpired({
    required VoidCallback onConfirm,
    String title = 'Session Expired',
    String message = 'Your session has expired. Please login again.',
    String confirmText = 'Login',
    String cancelText = 'Cancel',
  }) {
    return CustomConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      confirmButtonColor: Colors.blue,
      icon: Icons.lock_clock_outlined,
      iconColor: Colors.orange,
      isDangerous: false,
    );
  }

  /// Factory constructor cho cancel changes
  factory CustomConfirmDialog.cancelChanges({
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String title = 'Confirm Cancel',
    String message = 'Do you want to cancel the ongoing process? Once canceled, this ticket will be void.',
    String confirmText = 'Yes, Cancel',
    String cancelText = 'No',
  }) {
    return CustomConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmButtonColor: Colors.orange,
      icon: Icons.warning_outlined,
      iconColor: Colors.orange,
      isDangerous: true,
    );
  }

  /// Factory constructor cho general warning
  factory CustomConfirmDialog.warning({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Continue',
    String cancelText = 'Cancel',
  }) {
    return CustomConfirmDialog(
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: onConfirm,
      onCancel: onCancel,
      confirmButtonColor: Colors.orange,
      icon: Icons.warning_outlined,
      iconColor: Colors.orange,
      isDangerous: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 8,
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          minWidth: 320,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon (if provided)
            if (icon != null) ...[
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: (iconColor ?? Colors.blue).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: iconColor ?? Colors.blue,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDangerous ? Colors.red.shade700 : null,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Cancel Button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    onCancel?.call();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: cancelButtonColor ?? Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    cancelText,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 12),

                // Confirm Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    onConfirm?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmButtonColor ?? 
                        (isDangerous ? Colors.red : Colors.blue),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    confirmText,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Static method để show dialog và return Future<bool?>
  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    String cancelText = 'Cancel',
    String confirmText = 'Confirm',
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Color? confirmButtonColor,
    Color? cancelButtonColor,
    IconData? icon,
    Color? iconColor,
    bool isDangerous = false,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomConfirmDialog(
        title: title,
        message: message,
        cancelText: cancelText,
        confirmText: confirmText,
        onConfirm: onConfirm,
        onCancel: onCancel,
        confirmButtonColor: confirmButtonColor,
        cancelButtonColor: cancelButtonColor,
        icon: icon,
        iconColor: iconColor,
        isDangerous: isDangerous,
      ),
    );
  }

  /// Static method để show delete confirmation
  static Future<bool?> showDelete(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomConfirmDialog.delete(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  /// Static method để show session expired
  static Future<bool?> showSessionExpired(
    BuildContext context, {
    required VoidCallback onConfirm,
    String title = 'Session Expired',
    String message = 'Your session has expired. Please login again.',
    String confirmText = 'Login',
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomConfirmDialog.sessionExpired(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
      ),
    );
  }

  /// Static method để show cancel changes
  static Future<bool?> showCancelChanges(
    BuildContext context, {
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String title = 'Confirm Cancel',
    String message = 'Do you want to cancel the ongoing process? Once canceled, this ticket will be void.',
    String confirmText = 'Yes, Cancel',
    String cancelText = 'No',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomConfirmDialog.cancelChanges(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }

  /// Static method để show warning
  static Future<bool?> showWarning(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    VoidCallback? onCancel,
    String confirmText = 'Continue',
    String cancelText = 'Cancel',
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomConfirmDialog.warning(
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: cancelText,
        onConfirm: onConfirm,
        onCancel: onCancel,
      ),
    );
  }
}
