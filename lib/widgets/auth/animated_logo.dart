import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:truebpm/utils/global_store.dart';

class AnimatedLogo extends StatelessWidget {
  final AnimationController logoAnimationController;
  final Animation<double> logoScaleAnimation;
  final Animation<Offset> logoSlideAnimation;
  final Animation<double> logoGlowAnimation;

  const AnimatedLogo({
    super.key,
    required this.logoAnimationController,
    required this.logoScaleAnimation,
    required this.logoSlideAnimation,
    required this.logoGlowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: AnimatedBuilder(
        animation: logoAnimationController,
        builder: (context, child) {
          return SlideTransition(
            position: logoSlideAnimation,
            child: Transform.scale(
              scale: logoScaleAnimation.value,
              child: Hero(
                tag: 'app_logo',
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glow effect behind logo
                      if (logoGlowAnimation.value > 0)
                        Container(
                          width: 170,
                          height: 170,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withOpacity(
                                  0.3 * logoGlowAnimation.value,
                                ),
                                blurRadius: 40,
                                spreadRadius: 15,
                              ),
                              BoxShadow(
                                color: Colors.deepPurple.withOpacity(
                                  0.2 * logoGlowAnimation.value,
                                ),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      
                      // Logo with glass effect
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 1.0 * logoGlowAnimation.value,
                            sigmaY: 1.0 * logoGlowAnimation.value,
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.white.withOpacity(
                                  0.2 * logoGlowAnimation.value,
                                ),
                                width: 1.5,
                              ),
                            ),
                            child: Image.asset(
                              assets.appLogo,
                              width: 150,
                              height: 150,
                            ),
                          ),
                        ),
                      ),
                    ],
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
