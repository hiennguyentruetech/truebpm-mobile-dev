part of 'dashboard_charts.dart';

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

  // Animation trigger
  bool _showChart = false;

  // Touch highlight - track which section is being touched
  int _touchedIndex = -1;

  // Track current tooltip section to prevent re-animation
  int _currentTooltipIndex = -1;

  ChartDetailData get data => widget.data;
  bool get isDonut => widget.isDonut;

  /// Animation multiplier for radius: 0.0 when hidden, 1.0 when showing
  double get _radiusMultiplier => _showChart ? 1.0 : 0.0;

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
    _currentTooltipIndex = -1;
  }

  void _showPieTooltip(int sectionIndex, Offset localPosition) {
    // If tooltip is already showing for this section, don't re-create
    if (_currentTooltipIndex == sectionIndex && _tooltipOverlay != null) {
      return;
    }

    // Remove old tooltip if showing for different section
    if (_tooltipOverlay != null) {
      _tooltipOverlay!.remove();
      _tooltipOverlay = null;
    }
    _currentTooltipIndex = sectionIndex;

    final RenderBox? renderBox =
        _chartKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final globalPosition = renderBox.localToGlobal(localPosition);
    final label = _getLabelForIndex(sectionIndex);

    // Get value from yAxis
    final value =
        data.yAxis.isNotEmpty && data.yAxis.first.data.length > sectionIndex
        ? data.yAxis.first.data[sectionIndex].toDouble()
        : 0.0;
    final color =
        data.listColor?.elementAtOrNull(sectionIndex) ??
        ChartColors.getColor(sectionIndex);
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
      setState(() => _touchedIndex = -1);
    } else if (response != null && response.touchedSection != null) {
      final sectionIndex = response.touchedSection!.touchedSectionIndex;
      if (sectionIndex >= 0) {
        final localPos = event.localPosition;
        if (localPos != null) {
          _showPieTooltip(sectionIndex, localPos);
        }
        if (_touchedIndex != sectionIndex) {
          setState(() => _touchedIndex = sectionIndex);
        }
      }
    }
    // Don't remove tooltip in else case - only remove on explicit end events
  }

  /// Hide tooltip and reset touch state
  void _hideTooltipAndResetTouch() {
    _removeTooltip();
    if (_touchedIndex != -1) {
      setState(() => _touchedIndex = -1);
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
      ),
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

      // Base radius with animation
      final baseRadius = (isDonut ? 65.0 : 85.0) * _radiusMultiplier;

      for (int i = 0; i < series.data.length; i++) {
        final value = series.data[i].toDouble();
        final color =
            data.listColor?.elementAtOrNull(i) ?? ChartColors.getColor(i);

        // Touch highlight: increase radius when touched
        final isTouched = i == _touchedIndex;
        final radius = isTouched ? baseRadius + 10 : baseRadius;

        sections.add(
          PieChartSectionData(
            value: value,
            color: isTouched
                ? color
                : color.withOpacity(
                    isTouched || _touchedIndex == -1 ? 1.0 : 0.6,
                  ),
            title: value > 0 && _radiusMultiplier > 0.5
                ? value.toStringAsFixed(0)
                : '',
            titleStyle: TextStyle(
              fontSize: isTouched ? 14 : 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: const [
                Shadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            radius: radius,
            showTitle: value > 0 && _radiusMultiplier > 0.5,
            badgePositionPercentageOffset: 0.98,
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
        centerSpaceRadius: isDonut ? 55 : 0,
        sectionsSpace: 3,
        pieTouchData: PieTouchData(
          enabled: true,
          touchCallback: _handlePieTouch,
        ),
        startDegreeOffset: -90,
      ),
      swapAnimationDuration: const Duration(milliseconds: 500),
      swapAnimationCurve: Curves.easeInOutCubic,
    );
  }
}

/// Factory widget to render appropriate chart based on type
