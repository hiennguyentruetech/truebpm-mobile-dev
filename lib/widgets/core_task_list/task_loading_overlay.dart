import 'package:flutter/material.dart';
import 'package:truebpm/styles/app_colors.dart';

/// Widget overlay cho trạng thái loading
class TaskLoadingOverlay extends StatefulWidget {
  final String message;

  const TaskLoadingOverlay({
    super.key,
    required this.message,
  });

  @override
  State<TaskLoadingOverlay> createState() => _TaskLoadingOverlayState();
}

class _TaskLoadingOverlayState extends State<TaskLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _rotateController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _rotateAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotateController,
      curve: Curves.linear,
    ));

    _fadeController.forward();
    _rotateController.repeat();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color: Colors.black.withOpacity(0.6),
            child: Center(
              child: Card(
                elevation: 16,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.white,
                        AppColors.primary.withOpacity(0.02),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Loading spinner với animation
                      AnimatedBuilder(
                        animation: _rotateAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotateAnimation.value * 2 * 3.14159,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.primary,
                                    AppColors.accent,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.sync_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Loading message
                      Text(
                        widget.message,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'Please wait...',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
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
    );
  }
}

/// Helper class để show/hide loading overlay
class TaskLoadingManager {
  static bool _isShowing = false;

  /// Show loading overlay
  static void show(BuildContext context, String message) {
    if (_isShowing) return;
    
    _isShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (context) => TaskLoadingOverlay(message: message),
    );
  }

  /// Hide loading overlay
  static void hide(BuildContext context) {
    if (!_isShowing) return;
    
    _isShowing = false;
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Check if loading is currently showing
  static bool get isShowing => _isShowing;
}
