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
        Positioned.fill(
          child: FadeTransition(
            opacity: backgroundOpacityAnimation,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF03111C).withOpacity(0.80),
                    const Color(0xFF062B45).withOpacity(0.70),
                    const Color(0xFF020A12).withOpacity(0.94),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
