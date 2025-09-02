import 'package:flutter/material.dart';

/// Mixin for handling login animations with smooth transitions
mixin LoginAnimationMixin<T extends StatefulWidget> on State<T>, TickerProviderStateMixin<T> {
  late AnimationController logoAnimationController;
  late AnimationController formAnimationController;
  late AnimationController backgroundAnimationController;
  
  late Animation<double> logoScaleAnimation;
  late Animation<Offset> logoSlideAnimation;
  late Animation<double> logoGlowAnimation;
  late Animation<double> formOpacityAnimation;
  late Animation<Offset> formSlideAnimation;
  late Animation<double> backgroundOpacityAnimation;
  late Animation<double> backgroundBlurAnimation;

  void setupAnimations() {
    // Logo animation controller - smooth transition from splash
    logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    // Form animation controller - elegant entrance
    formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    // Background animation controller - quick fade
    backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Logo scale - smooth transition from splash size to login size
    logoScaleAnimation = Tween<double>(
      begin: 1.0,  // Continue from splash size
      end: 0.7,    // Final size for login screen
    ).animate(CurvedAnimation(
      parent: logoAnimationController,
      curve: Curves.easeInOutCubic,
    ));
    
    // Logo slide - smooth upward movement
    logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0),     // Start at center
      end: const Offset(0, -0.35),   // Move up smoothly
    ).animate(CurvedAnimation(
      parent: logoAnimationController,
      curve: Curves.easeInOutQuart,
    ));
    
    // Logo glow effect - subtle pulsing glow
    logoGlowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: logoAnimationController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    ));
    
    // Background animations
    backgroundOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: backgroundAnimationController,
      curve: Curves.easeIn,
    ));
    
    // Background blur effect
    backgroundBlurAnimation = Tween<double>(
      begin: 0.0,
      end: 5.0,
    ).animate(CurvedAnimation(
      parent: backgroundAnimationController,
      curve: Curves.easeOut,
    ));
    
    // Form animations - elegant entrance from bottom
    formOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: formAnimationController,
      curve: Curves.easeIn,
    ));
    
    formSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: formAnimationController,
      curve: Curves.easeOutQuart,
    ));
  }

  void startAnimations() {
    // Smooth sequential animation start
    // Background fades in first
    backgroundAnimationController.forward();
    
    // Logo animation starts with slight delay for smooth transition
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        logoAnimationController.forward();
      }
    });
    
    // Form appears after logo is in position
    Future.delayed(const Duration(milliseconds: 600), () {
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
