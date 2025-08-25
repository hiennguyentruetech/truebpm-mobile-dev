import 'package:flutter/material.dart';

class TouchableOpacity extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double opacity;
  final Duration duration;

  const TouchableOpacity({
    required this.child,
    this.onTap,
    this.opacity = 0.3,
    this.duration = const Duration(milliseconds: 50),
    super.key,
  });

  @override
  State<TouchableOpacity> createState() => _TouchableOpacityState();
}

class _TouchableOpacityState extends State<TouchableOpacity> {
  bool _pressed = false;

  void _setPressed(bool value) {
    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedOpacity(
        opacity: _pressed ? widget.opacity : 1.0,
        duration: widget.duration,
        child: widget.child,
      ),
    );
  }
}
