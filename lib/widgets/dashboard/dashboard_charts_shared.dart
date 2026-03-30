part of 'dashboard_charts.dart';

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

  /// Get gradient for bar chart with subtle shine effect
  static LinearGradient getBarGradient(
    Color baseColor, {
    bool isHorizontal = false,
  }) {
    final lighterColor = Color.lerp(baseColor, Colors.white, 0.25)!;
    final darkerColor = Color.lerp(baseColor, Colors.black, 0.1)!;

    if (isHorizontal) {
      return LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [darkerColor, baseColor, lighterColor],
        stops: const [0.0, 0.6, 1.0],
      );
    }
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [darkerColor, baseColor, lighterColor],
      stops: const [0.0, 0.6, 1.0],
    );
  }

  /// Get shadow color for glow effect
  static Color getShadowColor(Color baseColor) {
    return baseColor.withOpacity(0.4);
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
