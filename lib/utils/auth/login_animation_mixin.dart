import 'package:flutter/material.dart';

/// Mixin for handling login animations
mixin LoginAnimationMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController logoAnimationController;
  late AnimationController formAnimationController;
  late AnimationController backgroundAnimationController;
  
  late Animation<double> logoScaleAnimation;
  late Animation<Offset> logoSlideAnimation;
  late Animation<double> logoRotationAnimation;
  late Animation<double> logoPulseAnimation;
  late Animation<double> formOpacityAnimation;
  late Animation<Offset> formSlideAnimation;
  late Animation<double> backgroundOpacityAnimation;

  void setupAnimations() {
    // Logo animation controller - enhanced with multiple effects
    logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    // Form animation controller - faster timing
    formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Background animation controller - faster
    backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    // Logo animations - start from splash position (center) and move to login position
    logoScaleAnimation = Tween<double>(
      begin: 1.0, // Start at splash size
      end: 0.8,   // Scale down for login position
    ).animate(CurvedAnimation(
      parent: logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
    ));
    
    logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0), // Start at center (splash position)
      end: const Offset(0, -0.3), // Move up for login position
    ).animate(CurvedAnimation(
      parent: logoAnimationController,
      curve: const Interval(0.0, 0.8, curve: Curves.easeOutCubic),
    ));
    
    // Subtle rotation for wow effect
    logoRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02, // Reduced rotation for smoother transition
    ).animate(CurvedAnimation(
      parent: logoAnimationController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
    ));
    
    // Pulse effect during transition
    logoPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05, // Reduced pulse effect
    ).animate(CurvedAnimation(
      parent: logoAnimationController,
      curve: const Interval(0.1, 0.3, curve: Curves.elasticOut),
    ));
    
    // Background opacity for smooth transition
    backgroundOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: backgroundAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Form animations with enhanced timing
    formOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: formAnimationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeInOut),
    ));
    
    formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: formAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));
  }

  void startAnimations() {
    // Start background fade immediately
    backgroundAnimationController.forward();
    
    // Start logo animation immediately for smooth transition from splash
    logoAnimationController.forward();
    
    // Start form animation much earlier for faster appearance
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        formAnimationController.forward();
      }
    });
  }

  void disposeAnimations() {
    logoAnimationController.dispose();
    formAnimationController.dispose();
    backgroundAnimationController.dispose();
  }
}
