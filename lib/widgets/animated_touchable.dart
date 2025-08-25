import 'package:flutter/material.dart';

class AnimatedTouchable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double scaleDownValue;
  final Duration animationDuration;
  final Curve animationCurve;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool disabled;
  final Color? splashColor;
  final Color? highlightColor;

  const AnimatedTouchable({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDownValue = 0.96,
    this.animationDuration = const Duration(milliseconds: 150),
    this.animationCurve = Curves.easeInOut,
    this.borderRadius,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.disabled = false,
    this.splashColor,
    this.highlightColor,
  });

  @override
  State<AnimatedTouchable> createState() => _AnimatedTouchableState();
}

class _AnimatedTouchableState extends State<AnimatedTouchable>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDownValue,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: widget.animationCurve,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.disabled) {
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.disabled) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.disabled) {
      _animationController.reverse();
    }
  }

  void _handleTap() {
    if (!widget.disabled && widget.onTap != null) {
      widget.onTap!();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = widget.child;

    // Apply padding if provided
    if (widget.padding != null) {
      content = Padding(
        padding: widget.padding!,
        child: content,
      );
    }

    // Apply background color if provided
    if (widget.backgroundColor != null) {
      content = Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
        ),
        child: content,
      );
    }

    Widget touchableContent = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Material(
            color: widget.backgroundColor ?? Colors.transparent,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
            child: InkWell(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
              onTap: widget.disabled ? null : _handleTap,
              onTapDown: _handleTapDown,
              onTapUp: _handleTapUp,
              onTapCancel: _handleTapCancel,
              splashColor: widget.splashColor,
              highlightColor: widget.highlightColor,
              child: content,
            ),
          ),
        );
      },
    );

    // Apply margin if provided
    if (widget.margin != null) {
      touchableContent = Container(
        margin: widget.margin,
        child: touchableContent,
      );
    }

    return touchableContent;
  }
}
