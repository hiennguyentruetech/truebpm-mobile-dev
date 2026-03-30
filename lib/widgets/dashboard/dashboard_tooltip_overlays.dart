part of 'dashboard_charts.dart';

class _CustomStackedTooltipOverlay extends StatefulWidget {
  final Offset position;
  final String xAxisLabel;
  final ChartDetailData data;
  final int xIndex;

  const _CustomStackedTooltipOverlay({
    required this.position,
    required this.xAxisLabel,
    required this.data,
    required this.xIndex,
  });

  @override
  State<_CustomStackedTooltipOverlay> createState() =>
      _CustomStackedTooltipOverlayState();
}

class _CustomStackedTooltipOverlayState
    extends State<_CustomStackedTooltipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final seriesItems = <Widget>[];

    // Build list of all series with their values
    for (int i = 0; i < widget.data.yAxis.length; i++) {
      final series = widget.data.yAxis[i];
      final value = series.data.length > widget.xIndex
          ? series.data[widget.xIndex].toDouble()
          : 0.0;

      // Skip series with zero value
      if (value == 0) continue;

      final color =
          widget.data.listColor?.elementAtOrNull(i) ?? ChartColors.getColor(i);
      final formattedValue = widget.data.formatTooltipValue(value);

      seriesItems.add(
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  series.label,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  softWrap: true,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formattedValue,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Calculate tooltip width based on content - use intrinsic width
    const maxTooltipWidth = 320.0;
    final tooltipHeight =
        40.0 + (seriesItems.length * 32.0); // Increased height for wrapped text
    const padding = 16.0;

    double left = widget.position.dx - 100; // Approximate center, will adjust
    double top = widget.position.dy - tooltipHeight - padding;

    // Ensure tooltip stays within screen bounds
    if (left < padding) left = padding;
    if (left + maxTooltipWidth > screenSize.width - padding) {
      left = screenSize.width - maxTooltipWidth - padding;
    }
    if (top < padding) {
      // Show below the touch point if not enough space above
      top = widget.position.dy + padding;
    }

    return Positioned(
      left: left,
      top: top,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: IntrinsicWidth(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: maxTooltipWidth),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey.shade800, Colors.grey.shade900],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with xAxis label
                      Container(
                        padding: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.15),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 4,
                              height: 16,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.xAxisLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Series list
                      ...seriesItems,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Pie Chart Tooltip Overlay with Animation
class _CustomPieTooltipOverlay extends StatefulWidget {
  final Offset position;
  final String label;
  final String value;
  final Color color;

  const _CustomPieTooltipOverlay({
    required this.position,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  State<_CustomPieTooltipOverlay> createState() =>
      _CustomPieTooltipOverlayState();
}

class _CustomPieTooltipOverlayState extends State<_CustomPieTooltipOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const maxTooltipWidth = 320.0;
    const tooltipHeight = 70.0;
    const padding = 16.0;

    double left = widget.position.dx - 100; // Approximate center, will adjust
    double top = widget.position.dy - tooltipHeight - padding;

    // Ensure tooltip stays within screen bounds
    if (left < padding) left = padding;
    if (left + maxTooltipWidth > screenSize.width - padding) {
      left = screenSize.width - maxTooltipWidth - padding;
    }
    if (top < padding) {
      top = widget.position.dy + padding;
    }

    return Positioned(
      left: left,
      top: top,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            alignment: Alignment.bottomCenter,
            child: Material(
              color: Colors.transparent,
              child: IntrinsicWidth(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: maxTooltipWidth),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey.shade800, Colors.grey.shade900],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.color.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.color.withOpacity(0.2),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withOpacity(0.5),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                          softWrap: true,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        widget.value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
