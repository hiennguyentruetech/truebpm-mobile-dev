import 'package:flutter/material.dart';
import 'package:truebpm/models/dashboard_model.dart';

/// Inbox Card Widget for Dashboard - Web-style Design (Horizontal Scroll)
class DashboardInboxCard extends StatelessWidget {
  final InboxDataItem item;
  final VoidCallback? onTap;
  final int index;

  const DashboardInboxCard({
    super.key,
    required this.item,
    this.onTap,
    this.index = 0,
  });

  // Icon colors based on index (matching web design)
  Color get _iconColor {
    final colors = [
      const Color(0xFF3B82F6), // Blue
      const Color(0xFFF97316), // Orange
      const Color(0xFF10B981), // Green
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEC4899), // Pink
      const Color(0xFF06B6D4), // Cyan
    ];
    return colors[index % colors.length];
  }

  Color get _iconBgColor {
    final bgColors = [
      const Color(0xFFEFF6FF), // Light Blue
      const Color(0xFFFFF7ED), // Light Orange
      const Color(0xFFECFDF5), // Light Green
      const Color(0xFFF5F3FF), // Light Purple
      const Color(0xFFFDF2F8), // Light Pink
      const Color(0xFFECFEFF), // Light Cyan
    ];
    return bgColors[index % bgColors.length];
  }

  // Value color based on value (negative = blue, zero/positive = default)
  Color get _valueColor {
    // Safely check if value is negative
    final numValue = item.value is num ? item.value as num : 0;
    if (numValue < 0) {
      return const Color(0xFF3B82F6); // Blue for negative
    }
    return _iconColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 100,
      margin: const EdgeInsets.only(right: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(7),
          child: Padding(
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon + Title row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _iconBgColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(item.icon, color: _iconColor, size: 14),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                // Value + Unit
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      item.formattedValue,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _valueColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (item.unit != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        item.unit!,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrolling inbox list with web-style design
class DashboardInboxList extends StatelessWidget {
  final List<InboxDataItem> items;
  final int selectedYear;
  final List<int> availableYears;
  final ValueChanged<int>? onYearChanged;
  final bool isLoading;

  const DashboardInboxList({
    super.key,
    required this.items,
    required this.selectedYear,
    required this.availableYears,
    this.onYearChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue, Colors.blue.shade600],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: Label on left, Year selector on right
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Label on left
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.visibility_rounded,
                        color: Colors.white.withOpacity(0.9),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'My Watchlist',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  // Year selector on right
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedYear,
                        isDense: true,
                        dropdownColor: Colors.blue.shade700,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        items: availableYears.map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(
                              year.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            onYearChanged?.call(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Inbox cards - horizontal scroll
            SizedBox(
              height: 110,
              child: isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withOpacity(0.8),
                        ),
                      ),
                    )
                  : items.isEmpty
                  ? Center(
                      child: Text(
                        'No data available',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return DashboardInboxCard(
                          item: items[index],
                          index: index,
                        );
                      },
                    ),
            ),

            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

/// Chart card wrapper with title and actions
class DashboardChartCard extends StatelessWidget {
  final String title;
  final Widget chart;
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
    this.filters,
    this.currentFilterValues,
    this.onFilterChanged,
    this.onRemove,
    this.onRefresh,
    this.onChangeChart,
    this.isLoading = false,
    this.showRemoveButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(context),

          // Filters
          if (filters != null && filters!.isNotEmpty) _buildFilters(context),

          const Divider(height: 1),

          // Chart content
          Padding(
            padding: const EdgeInsets.all(16),
            child: isLoading
                ? const SizedBox(
                    height: 280,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : chart,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Title with dropdown icon (tappable to change chart)
          Expanded(
            child: InkWell(
              onTap: onChangeChart,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (onChangeChart != null)
                      Icon(
                        Icons.swap_horiz_rounded,
                        color: Colors.blue.shade400,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showRemoveButton && onRemove != null)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                  onPressed: onRemove,
                  tooltip: 'Remove',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              if (onRefresh != null)
                IconButton(
                  icon: Icon(
                    Icons.refresh_rounded,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: onRefresh,
                  tooltip: 'Refresh',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: filters!.map((filter) {
          final currentValue =
              currentFilterValues?[filter.field] ??
              filter.defaultOption?.value ??
              '';

          // Check if currentValue exists in options
          final valueExistsInOptions = filter.options.any(
            (option) => option.value == currentValue,
          );

          // Only use the value if it exists in options
          final dropdownValue = valueExistsInOptions && currentValue.isNotEmpty
              ? currentValue
              : null;

          return Container(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filter.label,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: dropdownValue,
                      isDense: true,
                      isExpanded: true,
                      hint: const Text('Select...'),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      items: filter.options.map((option) {
                        return DropdownMenuItem(
                          value: option.value,
                          child: Text(
                            option.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && onFilterChanged != null) {
                          final newFilters = Map<String, String>.from(
                            currentFilterValues ?? {},
                          );
                          newFilters[filter.field] = value;
                          onFilterChanged!(newFilters);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Chart selector dropdown with tree structure
class ChartSelectorDropdown extends StatefulWidget {
  final List<ChartConfigItem> chartTree;
  final ChartConfigItem? selectedChart;
  final ValueChanged<ChartConfigItem>? onChartSelected;

  const ChartSelectorDropdown({
    super.key,
    required this.chartTree,
    this.selectedChart,
    this.onChartSelected,
  });

  @override
  State<ChartSelectorDropdown> createState() => _ChartSelectorDropdownState();
}

class _ChartSelectorDropdownState extends State<ChartSelectorDropdown> {
  bool _isExpanded = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final Map<String, bool> _expandedNodes = {};

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected chart button
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (_isExpanded) {
                _searchFocusNode.requestFocus();
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blue.shade300),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.selectedChart?.name ?? 'Select Chart',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ],
            ),
          ),
        ),

        // Dropdown panel
        if (_isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Search input
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    decoration: InputDecoration(
                      hintText: 'Type to search...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                ),

                const Divider(height: 1),

                // Tree list
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: widget.chartTree
                          .map((item) => _buildTreeNode(item, 0))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildTreeNode(ChartConfigItem item, int depth) {
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final matchesSearch = item.displayName.toLowerCase().contains(
        _searchQuery,
      );
      final hasMatchingChildren =
          item.children?.any(
            (child) =>
                child.displayName.toLowerCase().contains(_searchQuery) ||
                (child.children?.any(
                      (c) => c.displayName.toLowerCase().contains(_searchQuery),
                    ) ??
                    false),
          ) ??
          false;

      if (!matchesSearch && !hasMatchingChildren) {
        return const SizedBox.shrink();
      }
    }

    final nodeKey = '${item.id}_$depth';
    final isExpanded = _expandedNodes[nodeKey] ?? true;
    final hasChildren = item.children != null && item.children!.isNotEmpty;
    final isSelected = widget.selectedChart?.id == item.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (item.isMenu && hasChildren) {
              setState(() {
                _expandedNodes[nodeKey] = !isExpanded;
              });
            } else if (!item.isMenu) {
              widget.onChartSelected?.call(item);
              setState(() {
                _isExpanded = false;
                _searchQuery = '';
                _searchController.clear();
              });
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 16 + (depth * 16),
              right: 16,
              top: 10,
              bottom: 10,
            ),
            color: isSelected ? Colors.blue.shade50 : null,
            child: Row(
              children: [
                if (item.isMenu && hasChildren)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 18,
                    color: Colors.grey.shade600,
                  )
                else if (!item.isMenu)
                  Container(
                    width: 4,
                    height: 16,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue : Colors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                if (item.isMenu) const SizedBox(width: 4),

                Expanded(
                  child: Text(
                    item.displayName,
                    style: TextStyle(
                      fontSize: item.isMenu ? 13 : 14,
                      fontWeight: item.isMenu
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? Colors.blue.shade700
                          : item.isMenu
                          ? Colors.grey.shade700
                          : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (hasChildren && isExpanded)
          ...item.children!.map((child) => _buildTreeNode(child, depth + 1)),
      ],
    );
  }
}

/// Empty state widget for dashboard
class DashboardEmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onRefresh;

  const DashboardEmptyState({
    super.key,
    this.message = 'No charts available',
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          if (onRefresh != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ],
      ),
    );
  }
}
