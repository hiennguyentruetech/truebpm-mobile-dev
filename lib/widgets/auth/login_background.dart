import 'package:flutter/material.dart';
import 'package:truebpm/utils/global_store.dart';

class LoginBackground extends StatelessWidget {
  final Animation<double> backgroundOpacityAnimation;
  final BoxConstraints constraints;

  const LoginBackground({
    super.key,
    required this.backgroundOpacityAnimation,
    required this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Full screen background image
        Positioned.fill(
          child: FadeTransition(
            opacity: backgroundOpacityAnimation,
            child: Image.asset(
              assets.startBackground,
              fit: BoxFit.cover,
              width: constraints.maxWidth,
              height: constraints.maxHeight,
            ),
          ),
        ),
        // Gradient overlay
        Positioned.fill(
          child: FadeTransition(
            opacity: backgroundOpacityAnimation,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
