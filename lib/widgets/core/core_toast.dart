import 'package:flutter/material.dart';

/// Toast type enum for different styles
enum CoreToastType { success, error, warning, info }

/// Beautiful custom toast notification widget
class CoreToast {
  static OverlayEntry? _currentOverlay;
  static bool _isShowing = false;

  /// Show a beautiful toast notification
  static void show(
    BuildContext context, {
    required String message,
    CoreToastType type = CoreToastType.info,
    Duration duration = const Duration(milliseconds: 2000),
    String? title,
    IconData? customIcon,
  }) {
    // Remove existing toast if any
    _dismiss();

    final overlay = Overlay.of(context);

    _currentOverlay = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        type: type,
        title: title,
        customIcon: customIcon,
        onDismiss: _dismiss,
        duration: duration,
      ),
    );

    _isShowing = true;
    overlay.insert(_currentOverlay!);
  }

  /// Show success toast
  static void success(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: CoreToastType.success, title: title);
  }

  /// Show error toast
  static void error(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: CoreToastType.error, title: title);
  }

  /// Show warning toast
  static void warning(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: CoreToastType.warning, title: title);
  }

  /// Show info toast
  static void info(BuildContext context, String message, {String? title}) {
    show(context, message: message, type: CoreToastType.info, title: title);
  }

  static void _dismiss() {
    if (_currentOverlay != null && _isShowing) {
      _currentOverlay?.remove();
      _currentOverlay = null;
      _isShowing = false;
    }
  }
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final CoreToastType type;
  final String? title;
  final IconData? customIcon;
  final VoidCallback onDismiss;
  final Duration duration;

  const _ToastWidget({
    required this.message,
    required this.type,
    this.title,
    this.customIcon,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismissWithAnimation();
      }
    });
  }

  void _dismissWithAnimation() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _dismissWithAnimation,
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity != null &&
                      details.primaryVelocity!.abs() > 100) {
                    _dismissWithAnimation();
                  }
                },
                child: _buildToastContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToastContent() {
    final config = _getTypeConfig();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [config.gradientStart, config.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: config.shadowColor.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: config.shadowColor.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated icon
          _AnimatedIcon(
            icon: widget.customIcon ?? config.icon,
            color: Colors.white,
            backgroundColor: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(width: 14),

          // Message content
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.title != null) ...[
                  Text(
                    widget.title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  widget.message,
                  style: TextStyle(
                    color: Colors.white.withOpacity(
                      widget.title != null ? 0.9 : 1.0,
                    ),
                    fontSize: 13,
                    fontWeight: widget.title != null
                        ? FontWeight.w400
                        : FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Close button
          GestureDetector(
            onTap: _dismissWithAnimation,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _ToastTypeConfig _getTypeConfig() {
    switch (widget.type) {
      case CoreToastType.success:
        return _ToastTypeConfig(
          icon: Icons.check_circle_rounded,
          gradientStart: const Color(0xFF10B981),
          gradientEnd: const Color(0xFF059669),
          shadowColor: const Color(0xFF10B981),
        );
      case CoreToastType.error:
        return _ToastTypeConfig(
          icon: Icons.error_rounded,
          gradientStart: const Color(0xFFEF4444),
          gradientEnd: const Color(0xFFDC2626),
          shadowColor: const Color(0xFFEF4444),
        );
      case CoreToastType.warning:
        return _ToastTypeConfig(
          icon: Icons.warning_rounded,
          gradientStart: const Color(0xFFF59E0B),
          gradientEnd: const Color(0xFFD97706),
          shadowColor: const Color(0xFFF59E0B),
        );
      case CoreToastType.info:
        return _ToastTypeConfig(
          icon: Icons.info_rounded,
          gradientStart: const Color(0xFF3B82F6),
          gradientEnd: const Color(0xFF2563EB),
          shadowColor: const Color(0xFF3B82F6),
        );
    }
  }
}

class _ToastTypeConfig {
  final IconData icon;
  final Color gradientStart;
  final Color gradientEnd;
  final Color shadowColor;

  _ToastTypeConfig({
    required this.icon,
    required this.gradientStart,
    required this.gradientEnd,
    required this.shadowColor,
  });
}

/// Animated icon with pulse effect
class _AnimatedIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  const _AnimatedIcon({
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });

  @override
  State<_AnimatedIcon> createState() => _AnimatedIconState();
}

class _AnimatedIconState extends State<_AnimatedIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Single pulse animation
    _controller.forward().then((_) {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(widget.icon, color: widget.color, size: 22),
      ),
    );
  }
}
