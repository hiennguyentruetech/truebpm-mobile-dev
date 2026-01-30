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
  int? _touchedBarIndex;

  ChartDetailData get data => widget.data;
  bool get showLegend => widget.showLegend;
  double get height => widget.height;

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
        _buildVerticalBarChart(),
        // Always show labels, but hide the touched bar's label
        Positioned.fill(
          child: _buildBarLabelsOverlay(hiddenBarIndex: _touchedBarIndex),
        ),
      ],
    );
  }

  Widget _buildVerticalBarChart() {
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
          touchCallback: (FlTouchEvent event, barTouchResponse) {
            setState(() {
              if (event is FlTapUpEvent ||
                  event is FlPanEndEvent ||
                  event is FlLongPressEnd) {
                _touchedBarIndex = null;
              } else if (barTouchResponse != null &&
                  barTouchResponse.spot != null) {
                _touchedBarIndex = barTouchResponse.spot!.touchedBarGroupIndex;
              } else {
                _touchedBarIndex = null;
              }
            });
          },
          touchTooltipData: BarTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            tooltipRoundedRadius: 8,
            getTooltipColor: (group) => Colors.grey.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final seriesName = data.yAxis.length > rodIndex
                  ? data.yAxis[rodIndex].label
                  : '';
              return BarTooltipItem(
                '${data.xAxis[groupIndex]}\n$seriesName: ${data.formatTooltipValue(rod.toY)}',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
      ),
      swapAnimationDuration: const Duration(milliseconds: 250),
    );
  }

  /// Build widget for data labels overlay on bar chart
  /// [hiddenBarIndex] - if set, hide the label for this bar index (when tooltip is showing)
  Widget _buildBarLabelsOverlay({int? hiddenBarIndex}) {
    final maxY = data.maxYValue;
    const bottomTitlesHeight = 32.0;
    const leftTitlesWidth = 40.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartAreaHeight = constraints.maxHeight - bottomTitlesHeight;
        final chartWidth = constraints.maxWidth - leftTitlesWidth;
        final barCount = data.xAxis.length;
        final barSpacing = chartWidth / barCount;

        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(barCount, (i) {
            // Skip the touched bar's label to let tooltip show clearly
            if (hiddenBarIndex == i) return const SizedBox.shrink();

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

            // Calculate label position
            final labelTop = isLabelInside
                ? chartAreaHeight -
                      barPixelHeight +
                      5 // Inside bar, 5px from top
                : chartAreaHeight - barPixelHeight - 18; // Above bar

            final labelLeft =
                leftTitlesWidth + (i * barSpacing) + (barSpacing / 2) - 15;

            return Positioned(
              top: labelTop,
              left: labelLeft,
              child: IgnorePointer(
                child: SizedBox(
                  width: 30,
                  child: Text(
                    _formatBarLabel(value),
                    textAlign: TextAlign.center,
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

  /// Format bar label value (compact format)
  String _formatBarLabel(double value) {
    if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  /// Build horizontal bar chart with data labels overlay
  Widget _buildHorizontalBarChartWithLabels() {
    // Only show labels for single series charts
    if (data.yAxis.length != 1) {
      return _buildHorizontalBarChart();
    }

    return Stack(
      children: [
        _buildHorizontalBarChart(),
        // Always show labels, but hide the touched bar's label
        Positioned.fill(
          child: _buildHorizontalBarLabelsOverlay(
            hiddenBarIndex: _touchedBarIndex,
          ),
        ),
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
            touchCallback: (FlTouchEvent event, barTouchResponse) {
              setState(() {
                if (event is FlTapUpEvent ||
                    event is FlPanEndEvent ||
                    event is FlLongPressEnd) {
                  _touchedBarIndex = null;
                } else if (barTouchResponse != null &&
                    barTouchResponse.spot != null) {
                  _touchedBarIndex =
                      barTouchResponse.spot!.touchedBarGroupIndex;
                } else {
                  _touchedBarIndex = null;
                }
              });
            },
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              tooltipMargin: 16,
              tooltipRoundedRadius: 8,
              direction: TooltipDirection.bottom,
              rotateAngle: -90, // Rotate tooltip back to vertical
              maxContentWidth: 150,
              getTooltipColor: (group) => Colors.grey.shade800,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final seriesName = data.yAxis.length > rodIndex
                    ? data.yAxis[rodIndex].label
                    : '';
                final value = data.formatTooltipValue(rod.toY);
                return BarTooltipItem(
                  '${data.xAxis[groupIndex]}\n$seriesName: $value',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
          ),
        ),
        swapAnimationDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  /// Build widget for data labels overlay on horizontal bar chart
  Widget _buildHorizontalBarLabelsOverlay({int? hiddenBarIndex}) {
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
            // Skip the touched bar's label to let tooltip show clearly
            if (hiddenBarIndex == i) return const SizedBox.shrink();

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
class DashboardLineChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend - using shared ChartLegend widget
        if (showLegend && data.yAxis.isNotEmpty)
          ChartLegend(
            yAxis: data.yAxis,
            listColor: data.listColor,
            shape: LegendShape.line, // Line shape for line chart
          ),

        const SizedBox(height: 16),

        // Chart
        SizedBox(height: height, child: _buildLineChart()),

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
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            tooltipRoundedRadius: 8,
            getTooltipColor: (touchedSpot) => Colors.grey.shade800,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final seriesName = data.yAxis.length > spot.barIndex
                    ? data.yAxis[spot.barIndex].label
                    : '';
                return LineTooltipItem(
                  '$seriesName: ${data.formatTooltipValue(spot.y)}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

/// Area Chart Widget using fl_chart
class DashboardAreaChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend - using shared ChartLegend widget
        if (showLegend && data.yAxis.isNotEmpty)
          ChartLegend(
            yAxis: data.yAxis,
            listColor: data.listColor,
            shape: LegendShape.square, // Square shape for area chart
          ),

        const SizedBox(height: 16),

        // Chart
        SizedBox(height: height, child: _buildAreaChart()),

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
          touchTooltipData: LineTouchTooltipData(
            fitInsideHorizontally: true,
            fitInsideVertically: true,
            tooltipPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            tooltipRoundedRadius: 8,
            getTooltipColor: (touchedSpot) => Colors.grey.shade800,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final seriesName = data.yAxis.length > spot.barIndex
                    ? data.yAxis[spot.barIndex].label
                    : '';
                return LineTooltipItem(
                  '$seriesName: ${data.formatTooltipValue(spot.y)}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

/// Pie/Donut Chart Widget using fl_chart
class DashboardPieChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend - using shared PieChartLegend widget
        if (showLegend) _buildPieLegend(),

        const SizedBox(height: 16),

        // Chart
        SizedBox(height: height, child: _buildPieChart()),
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
          touchCallback: (FlTouchEvent event, pieTouchResponse) {
            // Handle touch events if needed
          },
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
