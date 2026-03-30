part of 'dashboard_charts.dart';

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

/// Custom Stacked Tooltip Overlay Widget with Animation
/// Shows all series values for a specific x-axis item
