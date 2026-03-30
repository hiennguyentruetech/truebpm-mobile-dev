part of 'dashboard_widgets.dart';

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
