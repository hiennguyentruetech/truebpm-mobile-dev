import 'package:flutter/material.dart';

/// Widget for clear button with scale animation
class ClearButtonWithAnimation extends StatefulWidget {
  final VoidCallback onTap;

  const ClearButtonWithAnimation({
    super.key,
    required this.onTap,
  });

  @override
  State<ClearButtonWithAnimation> createState() => _ClearButtonWithAnimationState();
}

class _ClearButtonWithAnimationState extends State<ClearButtonWithAnimation> {
  double _buttonScale = 1.0;
  bool _isTapped = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _buttonScale = 0.85; // Slightly more scale for small button
          _isTapped = true;
        });
      },
      onTapUp: (_) {
        setState(() {
          _buttonScale = 1.0;
          _isTapped = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _buttonScale = 1.0;
          _isTapped = false;
        });
      },
      child: AnimatedScale(
        scale: _isTapped ? _buttonScale : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            splashColor: Colors.red.shade100.withValues(alpha: 0.3),
            highlightColor: Colors.red.shade50.withValues(alpha: 0.5),
            onTap: widget.onTap,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.red.shade600,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
