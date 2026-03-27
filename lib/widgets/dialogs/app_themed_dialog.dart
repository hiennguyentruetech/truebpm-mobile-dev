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
        return AppColors.dialogSuccess;
      case AppDialogType.warning:
        return AppColors.dialogWarning;
      case AppDialogType.error:
        return AppColors.dialogError;
      case AppDialogType.info:
        return AppColors.dialogInfo;
      case AppDialogType.neutral:
        return AppColors.primary;
    }
  }

  Color _typeColorDark() {
    switch (type) {
      case AppDialogType.success:
        return AppColors.dialogSuccessDark;
      case AppDialogType.warning:
        return AppColors.dialogWarningDark;
      case AppDialogType.error:
        return AppColors.dialogErrorDark;
      case AppDialogType.info:
        return AppColors.dialogInfoDark;
      case AppDialogType.neutral:
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
        return Icons.info_outline_rounded;
    }
  }

  /// Parse simple HTML tags and return RichText widget
  Widget _buildMessageWidget() {
    return RichText(text: _parseHtmlToTextSpan(message));
  }

  /// Parse HTML string to TextSpan with basic tag support
  TextSpan _parseHtmlToTextSpan(String html) {
    final List<TextSpan> spans = [];
    final RegExp tagPattern = RegExp(r'<(/?)(\w+)>');

    int lastIndex = 0;
    final List<String> styleStack = [];

    for (final match in tagPattern.allMatches(html)) {
      // Add text before this tag
      if (match.start > lastIndex) {
        final text = html.substring(lastIndex, match.start);
        spans.add(TextSpan(text: text, style: _getStyleFromStack(styleStack)));
      }

      final isClosing = match.group(1) == '/';
      final tagName = match.group(2)?.toLowerCase() ?? '';

      if (isClosing) {
        // Remove last matching tag from stack
        styleStack.remove(tagName);
      } else {
        // Add tag to stack
        if (['b', 'strong', 'i', 'em', 'u'].contains(tagName)) {
          styleStack.add(tagName);
        }
      }

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < html.length) {
      final text = html.substring(lastIndex);
      spans.add(TextSpan(text: text, style: _getStyleFromStack(styleStack)));
    }

    return TextSpan(
      children: spans,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.textPrimary,
        height: 1.45,
      ),
    );
  }

  /// Build TextStyle based on active HTML tags
  TextStyle _getStyleFromStack(List<String> stack) {
    bool isBold = stack.contains('b') || stack.contains('strong');
    bool isItalic = stack.contains('i') || stack.contains('em');
    bool isUnderline = stack.contains('u');

    return TextStyle(
      fontSize: 14,
      color: AppColors.textPrimary,
      height: 1.45,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = _typeColor();
    final baseDark = _typeColorDark();

    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 16,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: base.withOpacity(0.16)),
            gradient: LinearGradient(
              colors: [AppColors.surface, base.withOpacity(0.07)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 400),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            base.withOpacity(0.14),
                            baseDark.withOpacity(0.16),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: base.withOpacity(0.26),
                          width: 2,
                        ),
                      ),
                      child: Icon(_typeIcon(), color: base, size: 34),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Message block - scrollable when content is too long
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: base.withOpacity(0.22),
                      width: 1.2,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: base.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_typeIcon(), color: baseDark, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: _buildMessageWidget()),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Buttons - always visible at bottom
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
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
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
                color: widget.isSecondary ? AppColors.surface : null,
                borderRadius: BorderRadius.circular(12),
                border: widget.isSecondary
                    ? Border.all(
                        color: widget.base.withOpacity(0.35),
                        width: 1.6,
                      )
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
                  borderRadius: BorderRadius.circular(12),
                  onTap: widget.onPressed,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Text(
                      widget.text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: widget.isSecondary
                            ? widget.baseDark
                            : AppColors.surface,
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
