import 'package:flutter/material.dart';
import 'package:truebpm/models/dashboard_model.dart';

/// Inbox Card Widget for Dashboard
class DashboardInboxCard extends StatelessWidget {
  final InboxDataItem item;
  final VoidCallback? onTap;

  const DashboardInboxCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),

                const SizedBox(height: 12),

                // Value
                Text(
                  item.formattedValue,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: item.color,
                  ),
                ),

                // Unit
                if (item.unit != null)
                  Text(
                    item.unit!,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),

                const SizedBox(height: 8),

                // Title
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal scrolling inbox list
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with year selector
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overview',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              // Year dropdown
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedYear,
                    isDense: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.blue.shade600,
                      size: 20,
                    ),
                    items: availableYears.map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.w500,
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

        const SizedBox(height: 12),

        // Inbox cards
        SizedBox(
          height: 180,
          child: isLoading
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
              ? Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return DashboardInboxCard(item: items[index]);
                  },
                ),
        ),
      ],
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
