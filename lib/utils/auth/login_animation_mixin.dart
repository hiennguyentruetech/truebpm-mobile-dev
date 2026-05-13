import 'package:flutter/material.dart';

/// Mixin for handling login animations with smooth transitions
mixin LoginAnimationMixin<T extends StatefulWidget>
    on State<T>, TickerProviderStateMixin<T> {
  late AnimationController logoAnimationController;
  late AnimationController formAnimationController;
  late AnimationController backgroundAnimationController;

  late Animation<double> logoOpacityAnimation;
  late Animation<double> logoScaleAnimation;
  late Animation<Offset> logoSlideAnimation;
  late Animation<double> logoGlowAnimation;
  late Animation<double> formOpacityAnimation;
  late Animation<Offset> formSlideAnimation;
  late Animation<double> backgroundOpacityAnimation;

  void setupAnimations() {
    logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 720),
      vsync: this,
    );

    formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 640),
      vsync: this,
    );

    backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    logoOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: logoAnimationController,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );

    logoScaleAnimation = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: logoAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    logoSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: logoAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );

    logoGlowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: logoAnimationController,
        curve: const Interval(0.18, 1.0, curve: Curves.easeOut),
      ),
    );

    backgroundOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: backgroundAnimationController,
        curve: Curves.easeOut,
      ),
    );

    formOpacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: formAnimationController, curve: Curves.easeIn),
    );

    formSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
          CurvedAnimation(
            parent: formAnimationController,
            curve: Curves.easeOutCubic,
          ),
        );
  }

  void startAnimations({bool fromSplash = false}) {
    final logoDelay = fromSplash
        ? const Duration(milliseconds: 140)
        : const Duration(milliseconds: 80);
    final formDelay = fromSplash
        ? const Duration(milliseconds: 340)
        : const Duration(milliseconds: 220);

    backgroundAnimationController.forward();

    Future.delayed(logoDelay, () {
      if (mounted) {
        logoAnimationController.forward();
      }
    });

    Future.delayed(formDelay, () {
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
