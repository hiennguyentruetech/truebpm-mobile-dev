import 'package:flutter/material.dart';
import 'package:truebpm/utils/global_store.dart';

class WelcomeText extends StatelessWidget {
  final Animation<double> formOpacityAnimation;
  final Animation<Offset> formSlideAnimation;

  const WelcomeText({
    super.key,
    required this.formOpacityAnimation,
    required this.formSlideAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: formOpacityAnimation,
      child: SlideTransition(
        position: formSlideAnimation,
        child: Column(
          children: [
            Text(
              appStrings.loginTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.12,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appStrings.loginDescription,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white.withOpacity(0.76),
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
