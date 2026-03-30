part of 'dashboard_charts.dart';

class DashboardBarChart extends StatefulWidget {
  final ChartDetailData data;
  final bool showLegend;
  final double height;

  const DashboardBarChart({
    super.key,
    required this.data,
    this.showLegend = true,
    this.height = 300,
  });

  @override
  State<DashboardBarChart> createState() => _DashboardBarChartState();
}

class _DashboardBarChartState extends State<DashboardBarChart> {
  // For custom overlay tooltip
  OverlayEntry? _tooltipOverlay;
  final GlobalKey _chartKey = GlobalKey();

  // Animation trigger
  bool _showChart = false;

  // Touch highlight tracking
  int _touchedBarIndex = -1;
  int _touchedRodIndex = -1;

  // Track current tooltip bar index to prevent re-animation
  int _currentTooltipBarIndex = -1;

  ChartDetailData get data => widget.data;
  bool get showLegend => widget.showLegend;
  double get height => widget.height;

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
    _currentTooltipBarIndex = -1;
  }

  void _showTooltip(
    int barIndex,
    Offset localPosition, {
    bool isHorizontal = false,
  }) {
    // If tooltip is already showing for this bar, don't re-create (prevents re-animation)
    if (_currentTooltipBarIndex == barIndex && _tooltipOverlay != null) {
      return;
    }

    // Remove old tooltip if showing for different bar
    if (_tooltipOverlay != null) {
      _tooltipOverlay!.remove();
      _tooltipOverlay = null;
    }
    _currentTooltipBarIndex = barIndex;

    final RenderBox? renderBox =
        _chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final chartSize = renderBox.size;
    Offset adjustedLocalPosition;

    if (isHorizontal) {
      // For horizontal bar chart, calculate position based on bar index
      // The chart is rotated 90 degrees, so bars are stacked vertically
      final barCount = data.xAxis.length;
      final topPadding = 40.0; // Reserved for top titles
      final chartAreaHeight = chartSize.height - topPadding;
      final barSpacing = chartAreaHeight / barCount;

      // Calculate Y position based on which bar was touched
      final barY = topPadding + (barIndex * barSpacing) + (barSpacing / 2);

      // X position: use the touch X position directly (horizontal position on bar)
      adjustedLocalPosition = Offset(localPosition.dy, barY);
    } else {
      adjustedLocalPosition = localPosition;
    }

    final globalPosition = renderBox.localToGlobal(adjustedLocalPosition);

    // Get tooltip content
    final xAxisLabel = data.xAxis[barIndex];

    // Use unified stacked-style tooltip for all chart types
    _tooltipOverlay = OverlayEntry(
      builder: (context) => _CustomStackedTooltipOverlay(
        position: globalPosition,
        xAxisLabel: xAxisLabel,
        data: data,
        xIndex: barIndex,
      ),
    );

    Overlay.of(context).insert(_tooltipOverlay!);
  }

  void _handleBarTouch(
    FlTouchEvent event,
    BarTouchResponse? response, {
    bool isHorizontal = false,
  }) {
    if (event is FlTapUpEvent ||
        event is FlPanEndEvent ||
        event is FlLongPressEnd ||
        event is FlPointerExitEvent) {
      _removeTooltip();
      if (_touchedBarIndex != -1) {
        setState(() {
          _touchedBarIndex = -1;
          _touchedRodIndex = -1;
        });
      }
    } else if (response != null && response.spot != null) {
      final barIndex = response.spot!.touchedBarGroupIndex;
      final rodIndex = response.spot!.touchedRodDataIndex;
      final localPos = event.localPosition;

      if (localPos != null) {
        _showTooltip(barIndex, localPos, isHorizontal: isHorizontal);
      }

      if (_touchedBarIndex != barIndex || _touchedRodIndex != rodIndex) {
        setState(() {
          _touchedBarIndex = barIndex;
          _touchedRodIndex = rodIndex;
        });
      }
    }
    // Don't remove tooltip in else case - only remove on explicit end events
    // This prevents flickering when touch starts but hasn't hit a bar yet
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
          if (showLegend && data.yAxis.isNotEmpty)
            ChartLegend(
              yAxis: data.yAxis,
              listColor: data.listColor,
              shape: LegendShape.square,
            ),

          const SizedBox(height: 16),

          // Chart with data labels overlay
          SizedBox(
            key: _chartKey,
            height: height,
            child: data.isHorizontal
                ? _buildHorizontalBarChartWithLabels()
                : _buildVerticalBarChartWithLabels(),
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

  /// Hide tooltip and reset touch state
  void _hideTooltipAndResetTouch() {
    _removeTooltip();
    if (_touchedBarIndex != -1) {
      setState(() {
        _touchedBarIndex = -1;
        _touchedRodIndex = -1;
      });
    }
  }

  /// Build vertical bar chart with data labels overlay
  Widget _buildVerticalBarChartWithLabels() {
    // Only show labels for single series charts
    if (data.yAxis.length != 1) {
      return _buildVerticalBarChart();
    }

    return Stack(
      children: [
        // Chart first (below in z-order)
        _buildVerticalBarChart(),
        // Labels always on top
        Positioned.fill(child: _buildBarLabelsOverlay()),
      ],
    );
  }

  Widget _buildVerticalBarChart() {
    // Use stacked chart if layout is stacked
    if (data.isStacked) {
      return _buildStackedVerticalBarChart();
    }
    return _buildGroupedVerticalBarChart();
  }

  /// Build grouped vertical bar chart (multiple bars side by side)
  Widget _buildGroupedVerticalBarChart() {
    final barGroups = <BarChartGroupData>[];
    final barWidth = data.yAxis.length > 1 ? 14.0 : 22.0;

    for (int i = 0; i < data.xAxis.length; i++) {
      final rods = <BarChartRodData>[];
      final isTouchedGroup = i == _touchedBarIndex;

      for (int j = 0; j < data.yAxis.length; j++) {
        final value = data.yAxis[j].data.length > i
            ? data.yAxis[j].data[i].toDouble() * _animationMultiplier
            : 0.0;
        final baseColor =
            data.listColor?.elementAtOrNull(j) ?? ChartColors.getColor(j);

        // Touch highlight: brighten the touched bar
        final isTouchedRod = isTouchedGroup && j == _touchedRodIndex;
        final color = isTouchedRod
            ? Color.lerp(baseColor, Colors.white, 0.2)!
            : baseColor;
        final rodWidth = isTouchedRod ? barWidth + 4 : barWidth;

        rods.add(
          BarChartRodData(
            toY: value,
            gradient: ChartColors.getBarGradient(color),
            width: rodWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: data.maxYValue,
              color: isTouchedGroup
                  ? Colors.grey.shade200
                  : Colors.grey.shade100,
            ),
          ),
        );
      }

      barGroups.add(BarChartGroupData(x: i, barRods: rods, barsSpace: 6));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.maxYValue,
        minY: 0,
        barGroups: barGroups,
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
                // Skip if value is at the boundaries that may cause overlap
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
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: _handleBarTouch,
          touchExtraThreshold: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 12,
          ),
          // Disable default tooltip, using custom overlay instead
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
          ),
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 400),
      swapAnimationCurve: Curves.easeInOutCubic,
    );
  }

  /// Build stacked vertical bar chart
  /// Groups series by their 'stack' property and stacks them on top of each other
  Widget _buildStackedVerticalBarChart() {
    final stackGroups = data.stackGroups;
    final stackNames = stackGroups.keys.toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive bar width
        final chartWidth =
            constraints.maxWidth - 60; // Subtract left titles space
        final xAxisCount = data.xAxis.length;
        final rodsPerGroup = stackNames.length;

        // Calculate available space per group
        final groupSpacing = 12.0;
        final totalGroupSpacing = groupSpacing * (xAxisCount - 1);
        final availableWidthPerGroup =
            (chartWidth - totalGroupSpacing) / xAxisCount;

        // Calculate bar width based on available space and number of rods
        final barsSpacing = 2.0;
        final totalBarsSpacing = barsSpacing * (rodsPerGroup - 1);
        var barWidth =
            (availableWidthPerGroup - totalBarsSpacing) / rodsPerGroup;

        // Clamp bar width to reasonable limits
        barWidth = barWidth.clamp(8.0, 32.0);

        final barGroups = <BarChartGroupData>[];

        for (int xIndex = 0; xIndex < data.xAxis.length; xIndex++) {
          final rods = <BarChartRodData>[];
          final isTouchedGroup = xIndex == _touchedBarIndex;

          // Create one rod per stack group
          for (int stackIdx = 0; stackIdx < stackNames.length; stackIdx++) {
            final stackName = stackNames[stackIdx];
            final seriesIndices = stackGroups[stackName]!;
            final isTouchedRod = isTouchedGroup && stackIdx == _touchedRodIndex;

            // Build stacked sections for this rod
            final rodStackItems = <BarChartRodStackItem>[];
            double currentY = 0;

            for (int i = 0; i < seriesIndices.length; i++) {
              final seriesIndex = seriesIndices[i];
              final rawValue = data.yAxis[seriesIndex].data.length > xIndex
                  ? data.yAxis[seriesIndex].data[xIndex].toDouble()
                  : 0.0;
              final value = rawValue * _animationMultiplier;

              if (value > 0) {
                final baseColor =
                    data.listColor?.elementAtOrNull(seriesIndex) ??
                    ChartColors.getColor(seriesIndex);
                // Brighten color when touched
                final color = isTouchedRod
                    ? Color.lerp(baseColor, Colors.white, 0.2)!
                    : baseColor;

                rodStackItems.add(
                  BarChartRodStackItem(
                    currentY,
                    currentY + value,
                    color,
                    BorderSide.none,
                  ),
                );
                currentY += value;
              }
            }

            // Only create rod if there's data
            if (currentY > 0 || seriesIndices.isNotEmpty) {
              // Get color for single-series stack
              final basePrimaryColor = seriesIndices.isNotEmpty
                  ? (data.listColor?.elementAtOrNull(seriesIndices.first) ??
                        ChartColors.getColor(seriesIndices.first))
                  : ChartColors.getColor(stackIdx);
              final primaryColor = isTouchedRod
                  ? Color.lerp(basePrimaryColor, Colors.white, 0.2)!
                  : basePrimaryColor;

              final rodWidth = isTouchedRod ? barWidth + 4 : barWidth;

              rods.add(
                BarChartRodData(
                  toY: currentY,
                  gradient: rodStackItems.length == 1
                      ? ChartColors.getBarGradient(primaryColor)
                      : null,
                  color: rodStackItems.length == 1 ? null : Colors.transparent,
                  rodStackItems: rodStackItems.length > 1 ? rodStackItems : [],
                  width: rodWidth,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: data.maxYValue,
                    color: isTouchedGroup
                        ? Colors.grey.shade200
                        : Colors.grey.shade100,
                  ),
                ),
              );
            }
          }

          barGroups.add(
            BarChartGroupData(x: xIndex, barRods: rods, barsSpace: barsSpacing),
          );
        }

        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceEvenly,
            groupsSpace: groupSpacing,
            maxY: data.maxYValue,
            minY: 0,
            barGroups: barGroups,
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
                  reservedSize: 50,
                  interval: data.yAxisInterval,
                  getTitlesWidget: (value, meta) {
                    if (value == meta.min || value == meta.max) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      data.formatYAxisValue(value),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchCallback: _handleBarTouch,
              touchExtraThreshold: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ),
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
              ),
            ),
          ),
          swapAnimationDuration: const Duration(milliseconds: 400),
          swapAnimationCurve: Curves.easeInOutCubic,
        );
      },
    );
  }

  /// Build widget for data labels overlay on bar chart
  Widget _buildBarLabelsOverlay() {
    final maxY = data.maxYValue;
    const bottomTitlesHeight = 32.0;
    const leftTitlesWidth = 40.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartAreaHeight = constraints.maxHeight - bottomTitlesHeight;
        final chartWidth = constraints.maxWidth - leftTitlesWidth;
        final barCount = data.xAxis.length;
        final barSpacing = chartWidth / barCount;

        // Pre-calculate: Check if ANY label is long (> 3 chars)
        // If any label is long, rotate ALL labels for consistency
        bool anyLabelIsLong = false;
        for (int i = 0; i < barCount; i++) {
          final value = data.yAxis.isNotEmpty && data.yAxis[0].data.length > i
              ? data.yAxis[0].data[i].toDouble()
              : 0.0;
          if (value == 0) continue;

          final labelText = _formatBarLabel(value);
          if (labelText.length > 3) {
            anyLabelIsLong = true;
            break;
          }
        }

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(barCount, (i) {
            // Get the first series value for single series chart
            final value = data.yAxis.isNotEmpty && data.yAxis[0].data.length > i
                ? data.yAxis[0].data[i].toDouble()
                : 0.0;

            if (value == 0) return const SizedBox.shrink();

            // Calculate position
            final barHeightRatio = maxY > 0 ? value / maxY : 0.0;
            final barPixelHeight = barHeightRatio * chartAreaHeight;

            // Determine if label should be inside or outside the bar
            // >= 25% of max: label inside bar
            // < 25% of max: label above bar
            final isLabelInside = barHeightRatio >= 0.25;

            // Get formatted label text
            final labelText = _formatBarLabel(value);

            // Use consistent rotation: if ANY label is long, rotate ALL labels
            final shouldRotate = anyLabelIsLong;

            // Size depends on rotation
            final labelSize = shouldRotate ? 36.0 : 30.0;

            // Calculate label position - adequate padding to prevent overlap for rotated long labels
            final labelTop = isLabelInside
                ? chartAreaHeight -
                      barPixelHeight +
                      2 // Inside bar, minimal padding from top
                : chartAreaHeight -
                      barPixelHeight -
                      (shouldRotate ? 32.0 : 16) -
                      2; // Above bar, sufficient padding for rotated labels

            // Center the label on bar
            final labelLeft =
                leftTitlesWidth +
                (i * barSpacing) +
                (barSpacing / 2) -
                (labelSize / 2);

            return Positioned(
              top: labelTop,
              left: labelLeft,
              child: IgnorePointer(
                child: SizedBox(
                  width: labelSize,
                  height: shouldRotate ? labelSize : 16,
                  child: Center(
                    child: shouldRotate
                        ? RotatedBox(
                            quarterTurns: -1, // Rotate 90° for long text
                            child: Text(
                              labelText,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isLabelInside
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Text(
                            labelText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isLabelInside
                                  ? Colors.white
                                  : Colors.grey.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Format bar label value (compact format like Y-axis)
  String _formatBarLabel(double value) {
    // Use compact format for bar labels (same as Y-axis)
    return data.formatYAxisValue(value);
  }

  /// Build horizontal bar chart with data labels overlay
  Widget _buildHorizontalBarChartWithLabels() {
    // Only show labels for single series charts
    if (data.yAxis.length != 1) {
      return _buildHorizontalBarChart();
    }

    return Stack(
      children: [
        // Chart first (below in z-order)
        _buildHorizontalBarChart(),
        // Labels always on top
        Positioned.fill(child: _buildHorizontalBarLabelsOverlay()),
      ],
    );
  }

  Widget _buildHorizontalBarChart() {
    final barGroups = <BarChartGroupData>[];
    final barWidth = 18.0;

    for (int i = 0; i < data.xAxis.length; i++) {
      final rods = <BarChartRodData>[];
      final isTouchedGroup = i == _touchedBarIndex;

      for (int j = 0; j < data.yAxis.length; j++) {
        final value = data.yAxis[j].data.length > i
            ? data.yAxis[j].data[i].toDouble() * _animationMultiplier
            : 0.0;
        final baseColor =
            data.listColor?.elementAtOrNull(j) ?? ChartColors.getColor(j);

        // Touch highlight: brighten the touched bar
        final isTouchedRod = isTouchedGroup && j == _touchedRodIndex;
        final color = isTouchedRod
            ? Color.lerp(baseColor, Colors.white, 0.2)!
            : baseColor;
        final rodWidth = isTouchedRod ? barWidth + 4 : barWidth;

        rods.add(
          BarChartRodData(
            toY: value,
            gradient: ChartColors.getBarGradient(color, isHorizontal: true),
            width: rodWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: data.maxYValue,
              color: isTouchedGroup
                  ? Colors.grey.shade200
                  : Colors.grey.shade100,
            ),
          ),
        );
      }

      barGroups.add(BarChartGroupData(x: i, barRods: rods, barsSpace: 6));
    }

    return RotatedBox(
      quarterTurns: 1,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.maxYValue,
          minY: 0,
          barGroups: barGroups,
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
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.xAxis.length) {
                    return RotatedBox(
                      quarterTurns: -1,
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
                reservedSize: 50,
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
                  return RotatedBox(
                    quarterTurns: -1,
                    child: Text(
                      data.formatXAxisValue(value),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchCallback: (event, response) =>
                _handleBarTouch(event, response, isHorizontal: true),
            touchExtraThreshold: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            // Disable default tooltip, using custom overlay instead
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
        swapAnimationCurve: Curves.easeInOutCubic,
      ),
    );
  }

  /// Build widget for data labels overlay on horizontal bar chart
  Widget _buildHorizontalBarLabelsOverlay() {
    final maxY = data.maxYValue;
    const leftLabelsWidth = 50.0;
    const topLabelsHeight = 40.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartAreaWidth = constraints.maxWidth - leftLabelsWidth;
        final chartAreaHeight = constraints.maxHeight - topLabelsHeight;
        final barCount = data.xAxis.length;
        final barSpacing = chartAreaHeight / barCount;

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(barCount, (i) {
            // Get the first series value for single series chart
            final value = data.yAxis.isNotEmpty && data.yAxis[0].data.length > i
                ? data.yAxis[0].data[i].toDouble()
                : 0.0;

            if (value == 0) return const SizedBox.shrink();

            // Calculate position for horizontal bar (rotated chart)
            final barWidthRatio = maxY > 0 ? value / maxY : 0.0;
            final barPixelWidth = barWidthRatio * chartAreaWidth;

            // Determine if label should be inside or outside the bar
            // >= 25% of max: label inside bar (near the end)
            // < 25% of max: label outside bar (after the bar)
            final isLabelInside = barWidthRatio >= 0.25;

            // Calculate label position
            final labelLeft = isLabelInside
                ? leftLabelsWidth +
                      barPixelWidth -
                      40 // Inside bar, near the end with more padding
                : leftLabelsWidth + barPixelWidth + 5; // Outside bar, after

            // Position from top (reversed because bars are from top to bottom)
            final labelTop =
                topLabelsHeight + (i * barSpacing) + (barSpacing / 2) - 8;

            return Positioned(
              top: labelTop,
              left: labelLeft,
              child: IgnorePointer(
                child: Container(
                  width: 35,
                  padding: EdgeInsets.only(right: isLabelInside ? 8 : 0),
                  child: Text(
                    _formatBarLabel(value),
                    textAlign: isLabelInside ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      color: isLabelInside
                          ? Colors.white
                          : Colors.grey.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Line Chart Widget using fl_chart
