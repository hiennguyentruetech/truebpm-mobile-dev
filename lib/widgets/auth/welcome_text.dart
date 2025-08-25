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
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              appStrings.loginDescription,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
