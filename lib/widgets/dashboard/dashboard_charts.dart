import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:truebpm/models/dashboard_model.dart';

/// Chart color palette
class ChartColors {
  static const List<Color> defaultColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFE91E63), // Pink/Red
    Color(0xFF9C27B0), // Purple
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFF5722), // Deep Orange
    Color(0xFF673AB7), // Deep Purple
    Color(0xFF009688), // Teal
    Color(0xFFFFC107), // Amber
  ];

  static Color getColor(int index) {
    return defaultColors[index % defaultColors.length];
  }
}

/// Professional Chart Legend Widget - Centered and Beautiful
class ChartLegend extends StatelessWidget {
  final List<ChartYAxisData> yAxis;
  final List<Color>? listColor;
  final LegendShape shape;

  const ChartLegend({
    super.key,
    required this.yAxis,
    this.listColor,
    this.shape = LegendShape.square,
  });

  @override
  Widget build(BuildContext context) {
    if (yAxis.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: yAxis.asMap().entries.map((entry) {
          final index = entry.key;
          final series = entry.value;
          final color =
              listColor?.elementAtOrNull(index) ?? ChartColors.getColor(index);

          return _LegendItem(color: color, label: series.label, shape: shape);
        }).toList(),
      ),
    );
  }
}

/// Legend shape types
enum LegendShape { square, circle, line }

/// Single legend item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final LegendShape shape;

  const _LegendItem({
    required this.color,
    required this.label,
    this.shape = LegendShape.square,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildShape(),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildShape() {
    switch (shape) {
      case LegendShape.circle:
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        );
      case LegendShape.line:
        return Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case LegendShape.square:
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        );
    }
  }
}

/// Bar Chart Widget using fl_chart
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

  ChartDetailData get data => widget.data;
  bool get showLegend => widget.showLegend;
  double get height => widget.height;

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  void _showTooltip(
    int barIndex,
    Offset localPosition, {
    bool isHorizontal = false,
  }) {
    _removeTooltip();

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
    } else if (response != null && response.spot != null) {
      final barIndex = response.spot!.touchedBarGroupIndex;
      final localPos = event.localPosition;

      if (localPos != null) {
        _showTooltip(barIndex, localPos, isHorizontal: isHorizontal);
      }
    } else {
      _removeTooltip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
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
    final barWidth = data.yAxis.length > 1 ? 12.0 : 20.0;

    for (int i = 0; i < data.xAxis.length; i++) {
      final rods = <BarChartRodData>[];

      for (int j = 0; j < data.yAxis.length; j++) {
        final value = data.yAxis[j].data.length > i
            ? data.yAxis[j].data[i].toDouble()
            : 0.0;
        final color =
            data.listColor?.elementAtOrNull(j) ?? ChartColors.getColor(j);

        rods.add(
          BarChartRodData(
            toY: value,
            color: color,
            width: barWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        );
      }

      barGroups.add(BarChartGroupData(x: i, barRods: rods, barsSpace: 4));
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
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
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
          touchExtraThreshold: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          // Disable default tooltip, using custom overlay instead
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.transparent,
            tooltipPadding: EdgeInsets.zero,
            getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
          ),
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 250),
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
        final chartWidth = constraints.maxWidth - 60; // Subtract left titles space
        final xAxisCount = data.xAxis.length;
        final rodsPerGroup = stackNames.length;
        
        // Calculate available space per group
        final groupSpacing = 12.0;
        final totalGroupSpacing = groupSpacing * (xAxisCount - 1);
        final availableWidthPerGroup = (chartWidth - totalGroupSpacing) / xAxisCount;
        
        // Calculate bar width based on available space and number of rods
        final barsSpacing = 2.0;
        final totalBarsSpacing = barsSpacing * (rodsPerGroup - 1);
        var barWidth = (availableWidthPerGroup - totalBarsSpacing) / rodsPerGroup;
        
        // Clamp bar width to reasonable limits
        barWidth = barWidth.clamp(8.0, 32.0);

        final barGroups = <BarChartGroupData>[];

        for (int xIndex = 0; xIndex < data.xAxis.length; xIndex++) {
          final rods = <BarChartRodData>[];

          // Create one rod per stack group
          for (int stackIdx = 0; stackIdx < stackNames.length; stackIdx++) {
            final stackName = stackNames[stackIdx];
            final seriesIndices = stackGroups[stackName]!;

            // Build stacked sections for this rod
            final rodStackItems = <BarChartRodStackItem>[];
            double currentY = 0;

            for (int i = 0; i < seriesIndices.length; i++) {
              final seriesIndex = seriesIndices[i];
              final value = data.yAxis[seriesIndex].data.length > xIndex
                  ? data.yAxis[seriesIndex].data[xIndex].toDouble()
                  : 0.0;

              if (value > 0) {
                final color =
                    data.listColor?.elementAtOrNull(seriesIndex) ??
                    ChartColors.getColor(seriesIndex);

                rodStackItems.add(
                  BarChartRodStackItem(currentY, currentY + value, color),
                );
                currentY += value;
              }
            }

            // Only create rod if there's data
            if (currentY > 0 || seriesIndices.isNotEmpty) {
              // Get color for single-series stack
              final primaryColor = seriesIndices.isNotEmpty
                  ? (data.listColor?.elementAtOrNull(seriesIndices.first) ??
                        ChartColors.getColor(seriesIndices.first))
                  : ChartColors.getColor(stackIdx);

              rods.add(
                BarChartRodData(
                  toY: currentY,
                  color: rodStackItems.length == 1
                      ? primaryColor
                      : Colors.transparent,
                  rodStackItems: rodStackItems.length > 1 ? rodStackItems : [],
                  width: barWidth,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
              );
            }
          }

          barGroups.add(BarChartGroupData(x: xIndex, barRods: rods, barsSpace: barsSpacing));
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
              getDrawingHorizontalLine: (value) =>
                  FlLine(color: Colors.grey.shade200, strokeWidth: 1),
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
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchCallback: _handleBarTouch,
              touchExtraThreshold: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (group) => Colors.transparent,
                tooltipPadding: EdgeInsets.zero,
                getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
              ),
            ),
          ),
          swapAnimationDuration: const Duration(milliseconds: 250),
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
                ? chartAreaHeight - barPixelHeight + 2 // Inside bar, minimal padding from top
                : chartAreaHeight - barPixelHeight - (shouldRotate ? 32.0 : 16) - 2; // Above bar, sufficient padding for rotated labels

            // Center the label on bar
            final labelLeft = leftTitlesWidth + (i * barSpacing) + (barSpacing / 2) - (labelSize / 2);

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
                                color: isLabelInside ? Colors.white : Colors.grey.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : Text(
                            labelText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isLabelInside ? Colors.white : Colors.grey.shade700,
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
    final barWidth = 16.0;

    for (int i = 0; i < data.xAxis.length; i++) {
      final rods = <BarChartRodData>[];

      for (int j = 0; j < data.yAxis.length; j++) {
        final value = data.yAxis[j].data.length > i
            ? data.yAxis[j].data[i].toDouble()
            : 0.0;
        final color =
            data.listColor?.elementAtOrNull(j) ?? ChartColors.getColor(j);

        rods.add(
          BarChartRodData(
            toY: value,
            color: color,
            width: barWidth,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        );
      }

      barGroups.add(BarChartGroupData(x: i, barRods: rods, barsSpace: 4));
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
            getDrawingHorizontalLine: (value) =>
                FlLine(color: Colors.grey.shade200, strokeWidth: 1),
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
                      data.formatYAxisValue(value),
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
            touchExtraThreshold: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            // Disable default tooltip, using custom overlay instead
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 250),
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
class DashboardLineChart extends StatefulWidget {
  final ChartDetailData data;
  final bool showLegend;
  final double height;

  const DashboardLineChart({
    super.key,
    required this.data,
    this.showLegend = true,
    this.height = 300,
  });

  @override
  State<DashboardLineChart> createState() => _DashboardLineChartState();
}

class _DashboardLineChartState extends State<DashboardLineChart> {
  final GlobalKey _chartKey = GlobalKey();
  OverlayEntry? _tooltipOverlay;

  ChartDetailData get data => widget.data;

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  void _showTooltip(int xIndex, Offset localPosition) {
    _removeTooltip();

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
    } else if (response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
      final spot = response.lineBarSpots!.first;
      final xIndex = spot.x.toInt();
      final localPos = event.localPosition;

      if (localPos != null) {
        _showTooltip(xIndex, localPos);
      }
    } else {
      _removeTooltip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend - using shared ChartLegend widget
        if (widget.showLegend && data.yAxis.isNotEmpty)
          ChartLegend(
            yAxis: data.yAxis,
            listColor: data.listColor,
            shape: LegendShape.line, // Line shape for line chart
          ),

        const SizedBox(height: 16),

        // Chart
        SizedBox(
          key: _chartKey,
          height: widget.height,
          child: _buildLineChart(),
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
    );
  }

  Widget _buildLineChart() {
    final lineBars = <LineChartBarData>[];

    for (int j = 0; j < data.yAxis.length; j++) {
      final spots = <FlSpot>[];
      final series = data.yAxis[j];
      final color =
          data.listColor?.elementAtOrNull(j) ?? ChartColors.getColor(j);

      for (int i = 0; i < series.data.length; i++) {
        spots.add(FlSpot(i.toDouble(), series.data[i].toDouble()));
      }

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: color,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: color,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
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
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
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
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) => null).toList(),
          ),
        ),
      ),
    );
  }
}

/// Area Chart Widget using fl_chart
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

  ChartDetailData get data => widget.data;

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  void _showTooltip(int xIndex, Offset localPosition) {
    _removeTooltip();

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
    } else if (response != null && response.lineBarSpots != null && response.lineBarSpots!.isNotEmpty) {
      final spot = response.lineBarSpots!.first;
      final xIndex = spot.x.toInt();
      final localPos = event.localPosition;

      if (localPos != null) {
        _showTooltip(xIndex, localPos);
      }
    } else {
      _removeTooltip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        spots.add(FlSpot(i.toDouble(), series.data[i].toDouble()));
      }

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: color,
          barWidth: 2,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 3,
                color: Colors.white,
                strokeWidth: 2,
                strokeColor: color,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: color.withOpacity(0.3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [color.withOpacity(0.4), color.withOpacity(0.0)],
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
          getDrawingHorizontalLine: (value) =>
              FlLine(color: Colors.grey.shade200, strokeWidth: 1),
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
            getTooltipItems: (touchedSpots) => touchedSpots.map((s) => null).toList(),
          ),
        ),
      ),
    );
  }
}

/// Pie/Donut Chart Widget using fl_chart
class DashboardPieChart extends StatefulWidget {
  final ChartDetailData data;
  final bool showLegend;
  final double height;
  final bool isDonut;

  const DashboardPieChart({
    super.key,
    required this.data,
    this.showLegend = true,
    this.height = 300,
    this.isDonut = true,
  });

  @override
  State<DashboardPieChart> createState() => _DashboardPieChartState();
}

class _DashboardPieChartState extends State<DashboardPieChart> {
  final GlobalKey _chartKey = GlobalKey();
  OverlayEntry? _tooltipOverlay;

  ChartDetailData get data => widget.data;
  bool get isDonut => widget.isDonut;

  @override
  void dispose() {
    _removeTooltip();
    super.dispose();
  }

  void _removeTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  void _showPieTooltip(int sectionIndex, Offset localPosition) {
    _removeTooltip();

    final RenderBox? renderBox =
        _chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final globalPosition = renderBox.localToGlobal(localPosition);
    final label = _getLabelForIndex(sectionIndex);
    
    // Get value from yAxis
    final value = data.yAxis.isNotEmpty && data.yAxis.first.data.length > sectionIndex
        ? data.yAxis.first.data[sectionIndex].toDouble()
        : 0.0;
    final color = data.listColor?.elementAtOrNull(sectionIndex) ?? ChartColors.getColor(sectionIndex);
    final formattedValue = data.formatTooltipValue(value);

    _tooltipOverlay = OverlayEntry(
      builder: (context) => _CustomPieTooltipOverlay(
        position: globalPosition,
        label: label,
        value: formattedValue,
        color: color,
      ),
    );

    Overlay.of(context).insert(_tooltipOverlay!);
  }

  void _handlePieTouch(FlTouchEvent event, PieTouchResponse? response) {
    if (event is FlTapUpEvent ||
        event is FlPanEndEvent ||
        event is FlLongPressEnd ||
        event is FlPointerExitEvent) {
      _removeTooltip();
    } else if (response != null && response.touchedSection != null) {
      final sectionIndex = response.touchedSection!.touchedSectionIndex;
      if (sectionIndex >= 0) {
        final localPos = event.localPosition;
        if (localPos != null) {
          _showPieTooltip(sectionIndex, localPos);
        }
      }
    } else {
      _removeTooltip();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend - using shared PieChartLegend widget
        if (widget.showLegend) _buildPieLegend(),

        const SizedBox(height: 16),

        // Chart
        SizedBox(
          key: _chartKey,
          height: widget.height,
          child: _buildPieChart(),
        ),
      ],
    );
  }

  /// Build pie chart legend with xAxis labels
  Widget _buildPieLegend() {
    final sections = _buildSections();
    if (sections.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 10,
        children: sections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;
          final label = _getLabelForIndex(index);

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: section.color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: section.color.withOpacity(0.3),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final sections = <PieChartSectionData>[];

    // For pie chart, usually xAxis contains labels and yAxis[0] contains values
    if (data.yAxis.isNotEmpty) {
      final series = data.yAxis.first;

      for (int i = 0; i < series.data.length; i++) {
        final value = series.data[i].toDouble();
        final color =
            data.listColor?.elementAtOrNull(i) ?? ChartColors.getColor(i);

        sections.add(
          PieChartSectionData(
            value: value,
            color: color,
            title: value > 0 ? value.toStringAsFixed(0) : '',
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            radius: isDonut ? 60 : 80,
            showTitle: value > 0,
          ),
        );
      }
    }

    return sections;
  }

  String _getLabelForIndex(int index) {
    // Use xAxis labels if available, otherwise use yAxis series labels
    if (index < data.xAxis.length) {
      return data.xAxis[index];
    }
    if (data.yAxis.isNotEmpty && data.yAxis.length > index) {
      return data.yAxis[index].label;
    }
    return 'Item $index';
  }

  Widget _buildPieChart() {
    return PieChart(
      PieChartData(
        sections: _buildSections(),
        centerSpaceRadius: isDonut ? 50 : 0,
        sectionsSpace: 2,
        pieTouchData: PieTouchData(
          enabled: true,
          touchCallback: _handlePieTouch,
        ),
      ),
    );
  }
}

/// Factory widget to render appropriate chart based on type
class DashboardChartWidget extends StatelessWidget {
  final ChartDetailData data;
  final double height;
  final bool showLegend;

  const DashboardChartWidget({
    super.key,
    required this.data,
    this.height = 280,
    this.showLegend = true,
  });

  @override
  Widget build(BuildContext context) {
    switch (data.chartType) {
      case DashboardChartType.bar:
        return DashboardBarChart(
          data: data,
          height: height,
          showLegend: showLegend,
        );
      case DashboardChartType.line:
        return DashboardLineChart(
          data: data,
          height: height,
          showLegend: showLegend,
        );
      case DashboardChartType.area:
        return DashboardAreaChart(
          data: data,
          height: height,
          showLegend: showLegend,
        );
      case DashboardChartType.pie:
        return DashboardPieChart(
          data: data,
          height: height,
          showLegend: showLegend,
        );
    }
  }
}

/// Custom Stacked Tooltip Overlay Widget
/// Shows all series values for a specific x-axis item
class _CustomStackedTooltipOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final seriesItems = <Widget>[];
    
    // Build list of all series with their values
    for (int i = 0; i < data.yAxis.length; i++) {
      final series = data.yAxis[i];
      final value = series.data.length > xIndex
          ? series.data[xIndex].toDouble()
          : 0.0;
      
      // Skip series with zero value
      if (value == 0) continue;
      
      final color = data.listColor?.elementAtOrNull(i) ?? ChartColors.getColor(i);
      final formattedValue = data.formatTooltipValue(value);
      
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
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                series.label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
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
    const minTooltipWidth = 180.0;
    const maxTooltipWidth = 280.0;
    final tooltipHeight = 40.0 + (seriesItems.length * 28.0);
    const padding = 16.0;

    double left = position.dx - minTooltipWidth / 2;
    double top = position.dy - tooltipHeight - padding;

    // Ensure tooltip stays within screen bounds
    if (left < padding) left = padding;
    if (left + maxTooltipWidth > screenSize.width - padding) {
      left = screenSize.width - maxTooltipWidth - padding;
    }
    if (top < padding) {
      // Show below the touch point if not enough space above
      top = position.dy + padding;
    }

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: minTooltipWidth,
            maxWidth: maxTooltipWidth,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with xAxis label
              Container(
                padding: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  xAxisLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Series list
              ...seriesItems,
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom Pie Chart Tooltip Overlay
class _CustomPieTooltipOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    const minTooltipWidth = 150.0;
    const maxTooltipWidth = 250.0;
    const tooltipHeight = 60.0;
    const padding = 16.0;

    double left = position.dx - minTooltipWidth / 2;
    double top = position.dy - tooltipHeight - padding;

    // Ensure tooltip stays within screen bounds
    if (left < padding) left = padding;
    if (left + maxTooltipWidth > screenSize.width - padding) {
      left = screenSize.width - maxTooltipWidth - padding;
    }
    if (top < padding) {
      top = position.dy + padding;
    }

    return Positioned(
      left: left,
      top: top,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: minTooltipWidth,
            maxWidth: maxTooltipWidth,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
