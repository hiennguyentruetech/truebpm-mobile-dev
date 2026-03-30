part of 'dashboard_widgets.dart';

class DashboardChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
  final String?
  chartType; // Chart type: 'bar', 'line', 'pie', 'donut', 'stacked', etc.
  final List<ChartFilter>? filters;
  final Map<String, String>? currentFilterValues;
  final ValueChanged<Map<String, String>>? onFilterChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onRefresh;
  final VoidCallback? onChangeChart;
  final bool isLoading;
  final bool showRemoveButton;

  const DashboardChartCard({
    super.key,
    required this.title,
    required this.chart,
    this.chartType,
    this.filters,
    this.currentFilterValues,
    this.onFilterChanged,
    this.onRemove,
    this.onRefresh,
    this.onChangeChart,
    this.isLoading = false,
    this.showRemoveButton = true,
  });

  /// Get icon based on chart type
  IconData get _chartIcon {
    final type = chartType?.toLowerCase() ?? '';

    // Pie/Donut charts - check first (before bar) since these are common
    if (type.contains('pie') ||
        type.contains('donut') ||
        type.contains('doughnut') ||
        type.contains('ring') ||
        type.contains('circle') ||
        type.contains('round')) {
      return Icons.pie_chart_rounded;
    }

    // Line charts
    if (type.contains('line')) {
      return Icons.show_chart_rounded;
    }

    // Area charts
    if (type.contains('area')) {
      return Icons.area_chart_rounded;
    }

    // Bar charts
    if (type.contains('bar') || type.contains('column')) {
      if (type.contains('horizontal')) {
        return Icons.align_horizontal_left_rounded;
      }
      if (type.contains('stacked')) {
        return Icons.stacked_bar_chart_rounded;
      }
      return Icons.bar_chart_rounded;
    }

    // Scatter/Bubble charts
    if (type.contains('scatter') || type.contains('bubble')) {
      return Icons.bubble_chart_rounded;
    }

    // Radar/Spider charts
    if (type.contains('radar') || type.contains('spider')) {
      return Icons.hexagon_rounded;
    }

    // Gauge charts
    if (type.contains('gauge') || type.contains('meter')) {
      return Icons.speed_rounded;
    }

    // Funnel charts
    if (type.contains('funnel')) {
      return Icons.filter_alt_rounded;
    }

    // Heatmap
    if (type.contains('heat') || type.contains('matrix')) {
      return Icons.grid_on_rounded;
    }

    // Treemap
    if (type.contains('tree')) {
      return Icons.dashboard_rounded;
    }

    // Default: bar chart
    return Icons.bar_chart_rounded;
  }

  /// Get gradient colors based on chart type
  List<Color> get _chartIconColors {
    final type = chartType?.toLowerCase() ?? '';

    // Pie/Donut charts
    if (type.contains('pie') ||
        type.contains('donut') ||
        type.contains('doughnut') ||
        type.contains('ring') ||
        type.contains('circle') ||
        type.contains('round')) {
      return [Colors.orange.shade400, Colors.orange.shade600];
    }
    if (type.contains('line')) {
      return [Colors.green.shade400, Colors.green.shade600];
    }
    if (type.contains('area')) {
      return [Colors.teal.shade400, Colors.teal.shade600];
    }
    if (type.contains('scatter') || type.contains('bubble')) {
      return [Colors.purple.shade400, Colors.purple.shade600];
    }
    if (type.contains('radar')) {
      return [Colors.cyan.shade400, Colors.cyan.shade600];
    }
    if (type.contains('gauge')) {
      return [Colors.red.shade400, Colors.red.shade600];
    }

    // Default: blue for bar charts
    return [Colors.blue.shade400, Colors.blue.shade600];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 7,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          _buildHeader(context),

          // Filters with popup style
          if (filters != null && filters!.isNotEmpty) _buildFilters(context),

          // Chart content
          Container(
            padding: const EdgeInsets.fromLTRB(7, 7, 7, 7),
            child: isLoading
                ? const SizedBox(
                    height: 280,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: 12),
                          Text(
                            'Loading chart...',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : chart,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color.fromARGB(255, 188, 226, 255), Colors.white],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Chart icon - dynamic based on chart type
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: _chartIconColors),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: _chartIconColors.first.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(_chartIcon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),

          // Title - allow multiline for long titles
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Action buttons
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Change chart button
        if (onChangeChart != null)
          _ActionIconButton(
            icon: Icons.swap_horiz_rounded,
            color: Colors.blue,
            tooltip: 'Change Chart',
            onPressed: onChangeChart!,
          ),

        // Remove button
        if (showRemoveButton && onRemove != null)
          _ActionIconButton(
            icon: Icons.delete_outline_rounded,
            color: Colors.red,
            tooltip: 'Remove',
            onPressed: onRemove!,
          ),

        // Refresh button
        if (onRefresh != null)
          _ActionIconButton(
            icon: Icons.refresh_rounded,
            color: Colors.grey,
            tooltip: 'Refresh',
            onPressed: onRefresh!,
          ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 7),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: filters!.map((filter) {
          final currentValue =
              currentFilterValues?[filter.field] ??
              filter.defaultOption?.value ??
              '';

          // Find selected option label
          final selectedOption = filter.options.firstWhere(
            (option) => option.value == currentValue,
            orElse: () => filter.options.isNotEmpty
                ? filter.options.first
                : ChartFilterOption(value: '', label: 'Select...'),
          );

          return _FilterChip(
            label: filter.label,
            value: selectedOption.label,
            options: filter.options,
            onSelected: (option) {
              if (onFilterChanged != null) {
                final newFilters = Map<String, String>.from(
                  currentFilterValues ?? {},
                );
                newFilters[filter.field] = option.value;
                onFilterChanged!(newFilters);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

/// Action icon button with hover effect
class _ActionIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color.withOpacity(0.7), size: 20),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 18,
      ),
    );
  }
}

/// Filter chip using CoreSelect DropdownTypeBuilder - Compact version
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final List<ChartFilterOption> options;
  final ValueChanged<ChartFilterOption> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
  });

  // Check if this is a Year-type filter
  bool get _isYearFilter {
    final lowerLabel = label.toLowerCase();
    return lowerLabel.contains('year') || lowerLabel.contains('năm');
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _ChartFilterDropdownDialog(
        label: label,
        options: options,
        selectedValue: value,
        showIndex: !_isYearFilter, // Hide index for Year filter
        onSelected: (option) {
          Navigator.pop(context);
          onSelected(option);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use IntrinsicWidth to auto-size based on content
    return IntrinsicWidth(
      child: _CompactDropdownField(
        label: label,
        value: value,
        isYearFilter: _isYearFilter,
        onTap: () => _showFilterDialog(context),
      ),
    );
  }
}

/// Compact dropdown field for chart filters
class _CompactDropdownField extends StatelessWidget {
  final String label;
  final String value;
  final bool isYearFilter;
  final VoidCallback onTap;

  const _CompactDropdownField({
    required this.label,
    required this.value,
    required this.isYearFilter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isYearFilter ? 8 : 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300, width: 1),
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.08),
                    spreadRadius: 1,
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Show full text without ellipsis
                  Text(
                    value.isNotEmpty ? value : 'Select...',
                    style: TextStyle(
                      color: value.isNotEmpty
                          ? Colors.grey.shade800
                          : Colors.grey.shade500,
                      fontSize: isYearFilter ? 12 : 13,
                      fontWeight: value.isNotEmpty
                          ? FontWeight.w500
                          : FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.blue.shade600,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Floating label
        Positioned(
          left: 6,
          top: -7,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF5B5B5B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chart Filter Dropdown Dialog - Reusing CoreSelect DropdownDialog style
class _ChartFilterDropdownDialog extends StatefulWidget {
  final String label;
  final List<ChartFilterOption> options;
  final bool showIndex;
  final String selectedValue;
  final ValueChanged<ChartFilterOption> onSelected;

  const _ChartFilterDropdownDialog({
    required this.label,
    required this.options,
    required this.selectedValue,
    this.showIndex = true,
    required this.onSelected,
  });

  @override
  State<_ChartFilterDropdownDialog> createState() =>
      _ChartFilterDropdownDialogState();
}

class _ChartFilterDropdownDialogState
    extends State<_ChartFilterDropdownDialog> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<ChartFilterOption> _filteredOptions = [];

  @override
  void initState() {
    super.initState();
    _filteredOptions = List.from(widget.options);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _filterOptions(String searchText) {
    setState(() {
      if (searchText.isEmpty) {
        _filteredOptions = List.from(widget.options);
      } else {
        final searchLower = searchText.toLowerCase();
        _filteredOptions = widget.options
            .where(
              (option) =>
                  option.label.toLowerCase().contains(searchLower) ||
                  option.value.toLowerCase().contains(searchLower),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Reusing CoreSelect DropdownDialog style exactly
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(10),
      child: Listener(
        onPointerDown: (_) {
          _searchFocusNode.unfocus();
        },
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.7,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                spreadRadius: 5,
                blurRadius: 20,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              // Beautiful header with gradient - same as CoreSelect
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(7),
                    topRight: Radius.circular(7),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.filter_list_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select ${widget.label}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.options.length} options available',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Material(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search field with elegant design - same as CoreSelect
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: TextFormField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  autofocus: false,
                  onChanged: _filterOptions,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Search options...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    prefixIcon: Container(
                      padding: const EdgeInsets.all(7),
                      child: Icon(
                        Icons.search_rounded,
                        color: Colors.blue.shade400,
                        size: 20,
                      ),
                    ),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, child) {
                        return value.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.clear_rounded,
                                  color: Colors.grey.shade400,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _filterOptions('');
                                },
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide(
                        color: Colors.blue.shade400,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 0,
                      vertical: 5,
                    ),
                  ),
                ),
              ),

              // Options list - CoreSelect style
              Expanded(
                child: _filteredOptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No options found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(10),
                        itemCount: _filteredOptions.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final option = _filteredOptions[index];
                          final isSelected =
                              option.label == widget.selectedValue;

                          // CoreSelect OptionCard style
                          return _ChartFilterOptionCard(
                            option: option,
                            index: index + 1,
                            isSelected: isSelected,
                            showIndex: widget.showIndex,
                            onTap: () {
                              _searchFocusNode.unfocus();
                              widget.onSelected(option);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Option Card - CoreSelect style (compact)
class _ChartFilterOptionCard extends StatelessWidget {
  final ChartFilterOption option;
  final int index;
  final bool isSelected;
  final bool showIndex;
  final VoidCallback onTap;

  const _ChartFilterOptionCard({
    required this.option,
    required this.index,
    required this.isSelected,
    this.showIndex = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? Colors.blue.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            children: [
              // Index number circle - only show if showIndex is true
              if (showIndex) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.blue.shade600
                        : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],

              // Option content - only show label, hide value/id
              Expanded(
                child: Text(
                  option.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? Colors.blue.shade700
                        : const Color(0xFF374151),
                  ),
                ),
              ),

              // Check icon
              if (isSelected)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Chart selector dropdown with tree structure
