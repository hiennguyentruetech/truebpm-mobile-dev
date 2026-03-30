part of 'dashboard_charts.dart';

class DashboardAreaChart extends StatefulWidget {
  final ChartDetailData data;
  final bool showLegend;
  final double height;

  const DashboardAreaChart({
    super.key,
    required this.data,
    this.showLegend = true,
    this.height = 300,
  });

  @override
  State<DashboardAreaChart> createState() => _DashboardAreaChartState();
}

class _DashboardAreaChartState extends State<DashboardAreaChart> {
  final GlobalKey _chartKey = GlobalKey();
  OverlayEntry? _tooltipOverlay;

  // Animation trigger
  bool _showChart = false;

  // Touch tracking
  int _touchedXIndex = -1;
  int _currentTooltipXIndex = -1;

  ChartDetailData get data => widget.data;

  /// Animation multiplier: 0.0 when hidden, 1.0 when showing
  double get _animationMultiplier => _showChart ? 1.0 : 0.0;

  @override
  void initState() {
    super.initState();
    // Trigger animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _showChart = true);
      }
    });
  }

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
    _currentTooltipXIndex = -1;
  }

  void _showTooltip(int xIndex, Offset localPosition) {
    // If tooltip is already showing for this index, don't re-create
    if (_currentTooltipXIndex == xIndex && _tooltipOverlay != null) {
      return;
    }

    // Remove old tooltip if showing for different index
    if (_tooltipOverlay != null) {
      _tooltipOverlay!.remove();
      _tooltipOverlay = null;
    }
    _currentTooltipXIndex = xIndex;

    final RenderBox? renderBox =
        _chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final globalPosition = renderBox.localToGlobal(localPosition);
    final xAxisLabel = data.xAxis.length > xIndex ? data.xAxis[xIndex] : '';

    _tooltipOverlay = OverlayEntry(
      builder: (context) => _CustomStackedTooltipOverlay(
        position: globalPosition,
        xAxisLabel: xAxisLabel,
        data: data,
        xIndex: xIndex,
      ),
    );

    Overlay.of(context).insert(_tooltipOverlay!);
  }

  void _handleLineTouch(FlTouchEvent event, LineTouchResponse? response) {
    if (event is FlTapUpEvent ||
        event is FlPanEndEvent ||
        event is FlLongPressEnd ||
        event is FlPointerExitEvent) {
      _removeTooltip();
      if (_touchedXIndex != -1) {
        setState(() => _touchedXIndex = -1);
      }
    } else if (response != null &&
        response.lineBarSpots != null &&
        response.lineBarSpots!.isNotEmpty) {
      final spot = response.lineBarSpots!.first;
      final xIndex = spot.x.toInt();
      final localPos = event.localPosition;

      // Update touched index if changed
      if (_touchedXIndex != xIndex) {
        setState(() => _touchedXIndex = xIndex);
      }

      if (localPos != null) {
        _showTooltip(xIndex, localPos);
      }
    }
    // Don't remove tooltip in else case - only remove on explicit end events
  }

  /// Hide tooltip and reset touch state
  void _hideTooltipAndResetTouch() {
    _removeTooltip();
    if (_touchedXIndex != -1) {
      setState(() => _touchedXIndex = -1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Handle pointer events to ensure tooltip is hidden on swipe out
      onPointerUp: (_) => _hideTooltipAndResetTouch(),
      onPointerCancel: (_) => _hideTooltipAndResetTouch(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend - using shared ChartLegend widget
          if (widget.showLegend && data.yAxis.isNotEmpty)
            ChartLegend(
              yAxis: data.yAxis,
              listColor: data.listColor,
              shape: LegendShape.square, // Square shape for area chart
            ),

          const SizedBox(height: 16),

          // Chart
          SizedBox(
            key: _chartKey,
            height: widget.height,
            child: _buildAreaChart(),
          ),

          // X-Axis label
          if (data.xAxisUnit != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(
                child: Text(
                  data.xAxisUnit!,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAreaChart() {
    final lineBars = <LineChartBarData>[];

    for (int j = 0; j < data.yAxis.length; j++) {
      final spots = <FlSpot>[];
      final series = data.yAxis[j];
      final color =
          data.listColor?.elementAtOrNull(j) ?? ChartColors.getColor(j);

      for (int i = 0; i < series.data.length; i++) {
        spots.add(
          FlSpot(
            i.toDouble(),
            series.data[i].toDouble() * _animationMultiplier,
          ),
        );
      }

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: color,
          barWidth: 3,
          isStrokeCapRound: true,
          shadow: Shadow(
            color: color.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              // Touch highlight effect
              final isTouched = index == _touchedXIndex;
              return FlDotCirclePainter(
                radius: isTouched ? 8 : 4,
                color: isTouched ? color : Colors.white,
                strokeWidth: isTouched ? 3 : 2.5,
                strokeColor: isTouched ? Colors.white : color,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withOpacity(0.35),
                color.withOpacity(0.15),
                color.withOpacity(0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        lineBarsData: lineBars,
        minY: 0,
        maxY: data.maxYValue,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: data.yAxisInterval,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
            dashArray: [5, 3],
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < data.xAxis.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      data.xAxis[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
              reservedSize: 32,
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: data.yAxisInterval,
              getTitlesWidget: (value, meta) {
                if (value == meta.min || value == meta.max) {
                  return const SizedBox.shrink();
                }
                return Text(
                  data.formatYAxisValue(value),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchCallback: _handleLineTouch,
          // Disable default tooltip, use custom overlay
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            getTooltipItems: (touchedSpots) =>
                touchedSpots.map((s) => null).toList(),
          ),
        ),
      ),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }
}

/// Pie/Donut Chart Widget using fl_chart
