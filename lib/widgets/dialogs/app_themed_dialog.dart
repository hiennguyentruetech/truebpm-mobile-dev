import 'package:flutter/material.dart';
import 'package:truebpm/styles/app_colors.dart';

/// Unified App Dialog styled after TakeTaskDialog, with color variants
/// for info, success, warning, and error. Supports 1 or 2 actions.
enum AppDialogType { neutral, info, success, warning, error }

class AppThemedDialog extends StatelessWidget {
  final String title;
  final String message;
  final AppDialogType type;
  final String confirmText;
  final VoidCallback onConfirm;
  final String? cancelText;
  final VoidCallback? onCancel;
  final IconData? icon;

  const AppThemedDialog({
    super.key,
    required this.title,
    required this.message,
    required this.type,
    required this.confirmText,
    required this.onConfirm,
    this.cancelText,
    this.onCancel,
    this.icon,
  });

  Color _typeColor() {
    switch (type) {
      case AppDialogType.success:
        return AppColors.success;
      case AppDialogType.warning:
        return AppColors.warning;
      case AppDialogType.error:
        return AppColors.error;
      case AppDialogType.info:
        return AppColors.info;
      case AppDialogType.neutral:
      default:
        return AppColors.primary;
    }
  }

  Color _typeColorDark() {
    switch (type) {
      case AppDialogType.success:
        return AppColors.successDark;
      case AppDialogType.warning:
        return AppColors.warningDark;
      case AppDialogType.error:
        return AppColors.errorDark;
      case AppDialogType.info:
        return AppColors.infoDark;
      case AppDialogType.neutral:
      default:
        return AppColors.primaryDark;
    }
  }

  IconData _typeIcon() {
    if (icon != null) return icon!;
    switch (type) {
      case AppDialogType.success:
        return Icons.check_circle_rounded;
      case AppDialogType.warning:
        return Icons.warning_amber_rounded;
      case AppDialogType.error:
        return Icons.error_outline_rounded;
      case AppDialogType.info:
        return Icons.info_outline_rounded;
      case AppDialogType.neutral:
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final base = _typeColor();
    final baseDark = _typeColorDark();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              base.withOpacity(0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 400),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          base.withOpacity(0.1),
                          baseDark.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: base.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Icon(_typeIcon(), color: base, size: 32),
                  ),
                );
              },
            ),
            const SizedBox(height: 7),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Message block
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: base.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: base.withOpacity(0.2), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(_typeIcon(), color: base, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Buttons
            Row(
              children: [
                if (cancelText != null) ...[
                  Expanded(
                    child: _DialogButton(
                      text: cancelText!,
                      isSecondary: true,
                      base: base,
                      baseDark: baseDark,
                      onPressed: onCancel ?? () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: _DialogButton(
                    text: confirmText,
                    isSecondary: false,
                    base: base,
                    baseDark: baseDark,
                    onPressed: onConfirm,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;
  final bool isSecondary;
  final Color base;
  final Color baseDark;

  const _DialogButton({
    required this.onPressed,
    required this.text,
    required this.isSecondary,
    required this.base,
    required this.baseDark,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                gradient: widget.isSecondary
                    ? null
                    : LinearGradient(
                        colors: [widget.base, widget.baseDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: widget.isSecondary ? Colors.transparent : null,
                borderRadius: BorderRadius.circular(8),
                border: widget.isSecondary
                    ? Border.all(color: AppColors.divider, width: 1.5)
                    : null,
                boxShadow: widget.isSecondary
                    ? null
                    : [
                        BoxShadow(
                          color: widget.base.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: widget.onPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: widget.isSecondary ? AppColors.textSecondary : Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

