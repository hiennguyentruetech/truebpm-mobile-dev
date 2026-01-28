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

/// Bar Chart Widget using fl_chart
class DashboardBarChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        if (showLegend && data.yAxis.isNotEmpty) _buildLegend(),
        
        const SizedBox(height: 16),
        
        // Chart
        SizedBox(
          height: height,
          child: data.isHorizontal 
              ? _buildHorizontalBarChart() 
              : _buildVerticalBarChart(),
        ),
        
        // X-Axis label
        if (data.xAxisUnit != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                data.xAxisUnit!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: data.yAxis.asMap().entries.map((entry) {
        final index = entry.key;
        final series = entry.value;
        final color = data.listColor?.elementAtOrNull(index) ?? 
                     ChartColors.getColor(index);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              series.label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
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
        final color = data.listColor?.elementAtOrNull(j) ?? 
                     ChartColors.getColor(j);
        
        rods.add(BarChartRodData(
          toY: value,
          color: color,
          width: barWidth,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ));
      }
      
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: rods,
        barsSpace: 4,
      ));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: data.maxYValue,
        barGroups: barGroups,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: data.maxYValue / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatAxisValue(value),
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
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (group) => Colors.grey.shade800,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final seriesName = data.yAxis.length > rodIndex 
                  ? data.yAxis[rodIndex].label 
                  : '';
              return BarTooltipItem(
                '${data.xAxis[groupIndex]}\n$seriesName: ${rod.toY.toStringAsFixed(1)}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
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
        final color = data.listColor?.elementAtOrNull(j) ?? 
                     ChartColors.getColor(j);
        
        rods.add(BarChartRodData(
          toY: value,
          color: color,
          width: barWidth,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(4),
            bottomRight: Radius.circular(4),
          ),
        ));
      }
      
      barGroups.add(BarChartGroupData(
        x: i,
        barRods: rods,
        barsSpace: 4,
      ));
    }

    return RotatedBox(
      quarterTurns: 1,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.maxYValue,
          barGroups: barGroups,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: data.maxYValue / 5,
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            show: true,
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
                reservedSize: 60,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return RotatedBox(
                    quarterTurns: -1,
                    child: Text(
                      _formatAxisValue(value),
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
        ),
      ),
    );
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
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
        // Legend
        if (showLegend && data.yAxis.isNotEmpty) _buildLegend(),
        
        const SizedBox(height: 16),
        
        // Chart
        SizedBox(
          height: height,
          child: _buildLineChart(),
        ),
        
        // X-Axis label
        if (data.xAxisUnit != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                data.xAxisUnit!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: data.yAxis.asMap().entries.map((entry) {
        final index = entry.key;
        final series = entry.value;
        final color = data.listColor?.elementAtOrNull(index) ?? 
                     ChartColors.getColor(index);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              series.label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildLineChart() {
    final lineBars = <LineChartBarData>[];
    
    for (int j = 0; j < data.yAxis.length; j++) {
      final spots = <FlSpot>[];
      final series = data.yAxis[j];
      final color = data.listColor?.elementAtOrNull(j) ?? ChartColors.getColor(j);
      
      for (int i = 0; i < series.data.length; i++) {
        spots.add(FlSpot(i.toDouble(), series.data[i].toDouble()));
      }
      
      lineBars.add(LineChartBarData(
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
      ));
    }

    return LineChart(
      LineChartData(
        lineBarsData: lineBars,
        minY: 0,
        maxY: data.maxYValue,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: data.maxYValue / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatAxisValue(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.grey.shade800,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final seriesName = data.yAxis.length > spot.barIndex 
                    ? data.yAxis[spot.barIndex].label 
                    : '';
                return LineTooltipItem(
                  '$seriesName: ${spot.y.toStringAsFixed(1)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
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
        // Legend
        if (showLegend && data.yAxis.isNotEmpty) _buildLegend(),
        
        const SizedBox(height: 16),
        
        // Chart
        SizedBox(
          height: height,
          child: _buildAreaChart(),
        ),
        
        // X-Axis label
        if (data.xAxisUnit != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
              child: Text(
                data.xAxisUnit!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLegend() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: data.yAxis.asMap().entries.map((entry) {
        final index = entry.key;
        final series = entry.value;
        final color = data.listColor?.elementAtOrNull(index) ?? 
                     ChartColors.getColor(index);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color.withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              series.label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAreaChart() {
    final lineBars = <LineChartBarData>[];
    
    for (int j = 0; j < data.yAxis.length; j++) {
      final spots = <FlSpot>[];
      final series = data.yAxis[j];
      final color = data.listColor?.elementAtOrNull(j) ?? ChartColors.getColor(j);
      
      for (int i = 0; i < series.data.length; i++) {
        spots.add(FlSpot(i.toDouble(), series.data[i].toDouble()));
      }
      
      lineBars.add(LineChartBarData(
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
            colors: [
              color.withOpacity(0.4),
              color.withOpacity(0.0),
            ],
          ),
        ),
      ));
    }

    return LineChart(
      LineChartData(
        lineBarsData: lineBars,
        minY: 0,
        maxY: data.maxYValue,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: data.maxYValue / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          show: true,
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatAxisValue(value),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                  ),
                );
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => Colors.grey.shade800,
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final seriesName = data.yAxis.length > spot.barIndex 
                    ? data.yAxis[spot.barIndex].label 
                    : '';
                return LineTooltipItem(
                  '$seriesName: ${spot.y.toStringAsFixed(1)}',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  String _formatAxisValue(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    } else if (value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
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
        // Legend
        if (showLegend) _buildLegend(),
        
        const SizedBox(height: 16),
        
        // Chart
        SizedBox(
          height: height,
          child: _buildPieChart(),
        ),
      ],
    );
  }

  Widget _buildLegend() {
    final sections = _buildSections();
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: sections.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value;
        final label = _getLabelForIndex(index);
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: section.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final sections = <PieChartSectionData>[];
    
    // For pie chart, usually xAxis contains labels and yAxis[0] contains values
    if (data.yAxis.isNotEmpty) {
      final series = data.yAxis.first;
      
      for (int i = 0; i < series.data.length; i++) {
        final value = series.data[i].toDouble();
        final color = data.listColor?.elementAtOrNull(i) ?? ChartColors.getColor(i);
        
        sections.add(PieChartSectionData(
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
        ));
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
