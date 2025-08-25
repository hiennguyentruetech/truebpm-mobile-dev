import 'package:flutter/material.dart';
import 'package:truebpm/utils/global_store.dart';

class AnimatedLogo extends StatelessWidget {
  final AnimationController logoAnimationController;
  final Animation<double> logoScaleAnimation;
  final Animation<Offset> logoSlideAnimation;
  final Animation<double> logoRotationAnimation;
  final Animation<double> logoPulseAnimation;

  const AnimatedLogo({
    super.key,
    required this.logoAnimationController,
    required this.logoScaleAnimation,
    required this.logoSlideAnimation,
    required this.logoRotationAnimation,
    required this.logoPulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: AnimatedBuilder(
        animation: logoAnimationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: logoRotationAnimation.value,
            child: Transform.scale(
              scale: logoScaleAnimation.value * logoPulseAnimation.value,
              child: SlideTransition(
                position: logoSlideAnimation,
                child: Hero(
                  tag: 'app_logo',
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        assets.appLogo,
                        width: 150,
                        height: 150,
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
