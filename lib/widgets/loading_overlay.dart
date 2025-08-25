import 'package:flutter/material.dart';
import 'package:truebpm/utils/global_store.dart';

class LoadingOverlay {
  static OverlayEntry? _overlayEntry;
  static bool _isShowing = false;

  /// Show loading overlay with professional design
  static void show(BuildContext context, {String? message}) {
    if (_isShowing) return;
    
    _isShowing = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => LoadingOverlayWidget(message: message),
    );
    
    // Defer overlay insertion to the end of current frame to avoid build-phase mutations
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_overlayEntry != null) {
        Overlay.of(context).insert(_overlayEntry!);
      }
    });
  }

  /// Hide loading overlay
  static void hide() {
    // Defer removal to next frame to avoid interfering mid-build
    if (_overlayEntry != null) {
      final entry = _overlayEntry!;
      _overlayEntry = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          entry.remove();
        } catch (_) {}
        _isShowing = false;
      });
    }
  }

  /// Check if overlay is currently showing
  static bool get isShowing => _isShowing;
}

class LoadingOverlayWidget extends StatefulWidget {
  final String? message;

  const LoadingOverlayWidget({
    super.key,
    this.message,
  });

  @override
  State<LoadingOverlayWidget> createState() => _LoadingOverlayWidgetState();
}

class _LoadingOverlayWidgetState extends State<LoadingOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Loading Animation
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Loading Message
                        Text(
                          widget.message ?? appStrings.loading,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        const SizedBox(height: 8),
                        
                        Text(
                          appStrings.pleaseWaitAMoment,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
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

/// Extension for easy use with context
extension LoadingOverlayExtension on BuildContext {
  void showLoading({String? message}) {
    LoadingOverlay.show(this, message: message);
  }

  void hideLoading() {
    LoadingOverlay.hide();
  }
}
