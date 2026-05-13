import 'package:flutter/material.dart';
import 'package:truebpm/utils/global_store.dart';

class AnimatedLogo extends StatelessWidget {
  final AnimationController logoAnimationController;
  final Animation<double> logoOpacityAnimation;
  final Animation<double> logoScaleAnimation;
  final Animation<Offset> logoSlideAnimation;
  final Animation<double> logoGlowAnimation;

  const AnimatedLogo({
    super.key,
    required this.logoAnimationController,
    required this.logoOpacityAnimation,
    required this.logoScaleAnimation,
    required this.logoSlideAnimation,
    required this.logoGlowAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 142,
      child: AnimatedBuilder(
        animation: logoAnimationController,
        builder: (context, child) {
          return FadeTransition(
            opacity: logoOpacityAnimation,
            child: SlideTransition(
              position: logoSlideAnimation,
              child: Transform.scale(
                scale: logoScaleAnimation.value,
                child: Hero(
                  tag: 'app_logo',
                  child: Center(
                    child: Container(
                      width: 112,
                      height: 112,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.94),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.55),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2A75BC).withOpacity(
                              0.18 + (0.08 * logoGlowAnimation.value),
                            ),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(assets.appLogo, fit: BoxFit.cover),
                      ),
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
