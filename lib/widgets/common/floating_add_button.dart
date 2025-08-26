import 'package:flutter/material.dart';

class FloatingAddButton extends StatelessWidget {
  const FloatingAddButton({
    super.key,
    required this.onPressed,
    this.size = 50,
    this.gradient,
    this.icon = const Icon(Icons.add_rounded, color: Colors.white, size: 40),
  });

  final VoidCallback onPressed;
  final double size;
  final Gradient? gradient;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? const LinearGradient(
          colors: [
            Color(0xFF42A5F5), // blue 400
            Color(0xFF1E88E5), // blue 600
            Color(0xFF1565C0), // blue 800
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(size / 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onPressed,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

