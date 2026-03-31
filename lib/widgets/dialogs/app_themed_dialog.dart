import 'package:flutter/material.dart';
import 'package:truebpm/styles/app_colors.dart';

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
      case AppDialogType.neutral:
        return Icons.info_outline_rounded;
    }
  }

  Widget _buildMessageWidget() {
    return RichText(text: _parseHtmlToTextSpan(message));
  }

  TextSpan _parseHtmlToTextSpan(String html) {
    final spans = <TextSpan>[];
    final tagPattern = RegExp(r'<(/?)(\w+)>');
    var lastIndex = 0;
    final styleStack = <String>[];

    for (final match in tagPattern.allMatches(html)) {
      if (match.start > lastIndex) {
        final text = html.substring(lastIndex, match.start);
        spans.add(TextSpan(text: text, style: _getStyleFromStack(styleStack)));
      }

      final isClosing = match.group(1) == '/';
      final tagName = match.group(2)?.toLowerCase() ?? '';

      if (isClosing) {
        styleStack.remove(tagName);
      } else if (['b', 'strong', 'i', 'em', 'u'].contains(tagName)) {
        styleStack.add(tagName);
      }

      lastIndex = match.end;
    }

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

  TextStyle _getStyleFromStack(List<String> stack) {
    final isBold = stack.contains('b') || stack.contains('strong');
    final isItalic = stack.contains('i') || stack.contains('em');
    final isUnderline = stack.contains('u');

    return TextStyle(
      fontSize: 14,
      color: AppColors.textPrimary,
      height: 1.45,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
    );
  }

  Color _toneForBusiness(
    Color color, {
    double saturationFactor = 0.60,
    double lightnessBoost = 0.06,
  }) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation((hsl.saturation * saturationFactor).clamp(0.0, 1.0))
        .withLightness((hsl.lightness + lightnessBoost).clamp(0.0, 1.0))
        .toColor();
  }

  Color _softStatusBackground(Color color) {
    return Color.alphaBlend(color.withOpacity(0.10), AppColors.surface);
  }

  @override
  Widget build(BuildContext context) {
    final base = _typeColor();
    final baseDark = _typeColorDark();
    final headerEnd = _toneForBusiness(
      baseDark,
      saturationFactor: 0.50,
      lightnessBoost: 0.06,
    );
    final actionBase = _toneForBusiness(
      base,
      saturationFactor: 0.56,
      lightnessBoost: 0.05,
    );
    final actionBaseDark = _toneForBusiness(
      baseDark,
      saturationFactor: 0.62,
      lightnessBoost: 0.03,
    );
    final panelBg = _softStatusBackground(base);
    final maxHeight = MediaQuery.of(context).size.height * 0.78;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 18,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          minWidth: 320,
          maxHeight: maxHeight,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: base.withOpacity(0.22), width: 1.3),
            color: panelBg,
            boxShadow: [
              BoxShadow(
                color: base.withOpacity(0.10),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 350),
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.44),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: base.withOpacity(0.30),
                                width: 1.4,
                              ),
                            ),
                            child: Icon(
                              _typeIcon(),
                              color: headerEnd,
                              size: 30,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: headerEnd,
                        letterSpacing: 0.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: base.withOpacity(0.20),
                            width: 1.2,
                          ),
                        ),
                        child: Scrollbar(
                          thumbVisibility: false,
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
                                  child: Icon(
                                    _typeIcon(),
                                    color: baseDark,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: _buildMessageWidget()),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        if (cancelText != null) ...[
                          Expanded(
                            child: _DialogButton(
                              text: cancelText!,
                              isSecondary: true,
                              base: actionBase,
                              baseDark: actionBaseDark,
                              onPressed: onCancel ?? () {},
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: _DialogButton(
                            text: confirmText,
                            isSecondary: false,
                            base: actionBase,
                            baseDark: actionBaseDark,
                            onPressed: onConfirm,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
