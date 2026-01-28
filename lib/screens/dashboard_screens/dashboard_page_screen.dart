import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truebpm/models/dashboard_model.dart';
import 'package:truebpm/providers/dashboard_provider.dart';
import 'package:truebpm/utils/session_handler.dart';
import 'package:truebpm/widgets/dashboard/dashboard_charts.dart';
import 'package:truebpm/widgets/dashboard/dashboard_widgets.dart';

/// Dashboard Page Screen - Main dashboard with charts and inbox
class DashboardPageScreen extends StatefulWidget {
  const DashboardPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'DASHBOARD';
  static const String moduleName = 'Dashboard';

  @override
  State<DashboardPageScreen> createState() => _DashboardPageScreenState();
}

class _DashboardPageScreenState extends State<DashboardPageScreen> {
  late DashboardProvider _provider;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _provider = DashboardProvider();
    _initializeDashboard();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _initializeDashboard() async {
    await _provider.initialize(onSessionExpired: _handleSessionExpired);
  }

  void _handleSessionExpired() {
    SessionHandler.handleSessionExpired(context);
  }

  Future<void> _refreshDashboard() async {
    await _provider.refresh(onSessionExpired: _handleSessionExpired);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: _buildAppBar(),
        body: Consumer<DashboardProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading &&
                provider.inboxItems.isEmpty &&
                provider.defaultCharts.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.errorMessage != null && provider.inboxItems.isEmpty) {
              return _buildErrorState(provider.errorMessage!);
            }

            return RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Inbox cards (horizontal scroll)
                    DashboardInboxList(
                      items: provider.inboxItems,
                      selectedYear: provider.selectedYear,
                      availableYears: provider.availableYears,
                      isLoading: provider.isLoadingInbox,
                      onYearChanged: (year) {
                        provider.changeYear(
                          year,
                          onSessionExpired: _handleSessionExpired,
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Section header for charts
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Charts',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // Add chart button
                          if (provider.allCharts.isNotEmpty)
                            TextButton.icon(
                              onPressed: () => _showAddChartDialog(provider),
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add Chart'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Default charts
                    if (provider.displayedCharts.isEmpty &&
                        !provider.isLoadingCharts)
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: DashboardEmptyState(
                          message: 'No charts configured',
                          onRefresh: _refreshDashboard,
                        ),
                      )
                    else
                      ...provider.displayedCharts.map((chartItem) {
                        return _ChartCardWrapper(
                          key: ValueKey(chartItem.id),
                          displayedChartId: chartItem.id,
                          chartId: chartItem.chartId,
                          chartName: chartItem.name,
                          provider: provider,
                          chartTree: provider.chartConfigTree,
                          onRemove: () =>
                              _confirmRemoveChart(chartItem, provider),
                          onReplaceChart: (newChart) {
                            provider.replaceChart(chartItem.id, newChart);
                          },
                        );
                      }),

                    const SizedBox(height: 100), // Bottom padding for FAB
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Dashboard'),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      elevation: 0,
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshDashboard,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddChartDialog(DashboardProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddChartBottomSheet(
        chartTree: provider.chartConfigTree,
        isChartDisplayed: (chartId) => provider.isChartDisplayed(chartId),
        onChartSelected: (chart) {
          Navigator.pop(context);

          // Check if chart already displayed
          if (provider.isChartDisplayed(chart.id)) {
            ScaffoldMessenger.of(this.context).showSnackBar(
              SnackBar(
                content: Text('"${chart.name}" is already displayed'),
                behavior: SnackBarBehavior.floating,
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }

          // Add chart to dashboard
          provider.addChart(chart);
          ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text('Added "${chart.name}" to dashboard'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _confirmRemoveChart(
    DisplayedChartItem chart,
    DashboardProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Chart'),
        content: Text('Are you sure you want to remove "${chart.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              provider.removeChart(chart.id);
              ScaffoldMessenger.of(this.context).showSnackBar(
                SnackBar(
                  content: Text('Removed "${chart.name}" from dashboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

/// Chart card wrapper that handles loading and displaying chart
class _ChartCardWrapper extends StatefulWidget {
  final String displayedChartId;
  final String chartId;
  final String chartName;
  final DashboardProvider provider;
  final List<ChartConfigItem> chartTree;
  final VoidCallback? onRemove;
  final ValueChanged<ChartConfigItem>? onReplaceChart;

  const _ChartCardWrapper({
    super.key,
    required this.displayedChartId,
    required this.chartId,
    required this.chartName,
    required this.provider,
    required this.chartTree,
    this.onRemove,
    this.onReplaceChart,
  });

  @override
  State<_ChartCardWrapper> createState() => _ChartCardWrapperState();
}

class _ChartCardWrapperState extends State<_ChartCardWrapper> {
  ChartDetailData? _chartData;
  bool _isLoading = true;
  Map<String, String> _filterValues = {};
  late String _currentChartId;

  @override
  void initState() {
    super.initState();
    _currentChartId = widget.chartId;
    _loadChartData();
  }

  @override
  void didUpdateWidget(covariant _ChartCardWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload if chart changed
    if (oldWidget.chartId != widget.chartId) {
      _currentChartId = widget.chartId;
      _filterValues = {};
      _loadChartData();
    }
  }

  Future<void> _loadChartData() async {
    setState(() => _isLoading = true);

    final data = await widget.provider.loadChartDetail(
      _currentChartId,
      filterValues: _filterValues.isNotEmpty ? _filterValues : null,
    );

    if (mounted) {
      setState(() {
        _chartData = data;
        _isLoading = false;
        if (data != null) {
          _filterValues = Map.from(data.filterValues);
        }
      });
    }
  }

  Future<void> _onFilterChanged(Map<String, String> newFilters) async {
    setState(() {
      _filterValues = newFilters;
      _isLoading = true;
    });

    final data = await widget.provider.refreshChartWithFilters(
      _currentChartId,
      newFilters,
    );

    if (mounted) {
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    }
  }

  void _showChartSelectorDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddChartBottomSheet(
        chartTree: widget.chartTree,
        isChartDisplayed: (chartId) =>
            widget.provider.isChartDisplayed(chartId) &&
            chartId != _currentChartId,
        onChartSelected: (chart) {
          Navigator.pop(context);
          widget.onReplaceChart?.call(chart);
        },
        title: 'Change Chart',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardChartCard(
      title: _chartData?.label ?? widget.chartName,
      isLoading: _isLoading,
      filters: _chartData?.filters,
      currentFilterValues: _filterValues,
      onFilterChanged: _onFilterChanged,
      onRemove: widget.onRemove,
      onRefresh: _loadChartData,
      onChangeChart: _showChartSelectorDialog,
      chart: _chartData != null
          ? DashboardChartWidget(data: _chartData!)
          : const SizedBox(
              height: 280,
              child: Center(child: Text('Failed to load chart')),
            ),
    );
  }
}

/// Bottom sheet for adding new chart or changing chart
class _AddChartBottomSheet extends StatefulWidget {
  final List<ChartConfigItem> chartTree;
  final ValueChanged<ChartConfigItem> onChartSelected;
  final bool Function(String chartId)? isChartDisplayed;
  final String title;

  const _AddChartBottomSheet({
    required this.chartTree,
    required this.onChartSelected,
    this.isChartDisplayed,
    this.title = 'Add Chart',
  });

  @override
  State<_AddChartBottomSheet> createState() => _AddChartBottomSheetState();
}

class _AddChartBottomSheetState extends State<_AddChartBottomSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _expandedNodes = {};

  @override
  void initState() {
    super.initState();
    // Expand all nodes by default
    _expandAllNodes(widget.chartTree, 0);
  }

  void _expandAllNodes(List<ChartConfigItem> items, int depth) {
    for (var item in items) {
      final key = '${item.id}_$depth';
      _expandedNodes[key] = true;
      if (item.children != null) {
        _expandAllNodes(item.children!, depth + 1);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search charts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          const Divider(height: 1),

          // Chart tree
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: widget.chartTree
                  .map((item) => _buildTreeNode(item, 0))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeNode(ChartConfigItem item, int depth) {
    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      final matchesSearch = item.displayName.toLowerCase().contains(
        _searchQuery,
      );
      final hasMatchingChildren = _hasMatchingChildren(item);

      if (!matchesSearch && !hasMatchingChildren) {
        return const SizedBox.shrink();
      }
    }

    final nodeKey = '${item.id}_$depth';
    final isExpanded = _expandedNodes[nodeKey] ?? true;
    final hasChildren = item.children != null && item.children!.isNotEmpty;

    // Check if chart is already displayed
    final isAlreadyDisplayed =
        !item.isMenu &&
        widget.isChartDisplayed != null &&
        widget.isChartDisplayed!(item.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            if (item.isMenu && hasChildren) {
              setState(() {
                _expandedNodes[nodeKey] = !isExpanded;
              });
            } else if (!item.isMenu && !isAlreadyDisplayed) {
              widget.onChartSelected(item);
            }
          },
          child: Container(
            padding: EdgeInsets.only(
              left: 16 + (depth * 20),
              right: 16,
              top: 12,
              bottom: 12,
            ),
            decoration: isAlreadyDisplayed
                ? BoxDecoration(color: Colors.grey.shade100)
                : null,
            child: Row(
              children: [
                if (item.isMenu && hasChildren)
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_down
                        : Icons.keyboard_arrow_right,
                    size: 20,
                    color: Colors.grey.shade600,
                  )
                else if (!item.isMenu)
                  Container(
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: isAlreadyDisplayed
                          ? Colors.grey.shade300
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _getChartIcon(item.chartType?.type),
                      size: 14,
                      color: isAlreadyDisplayed
                          ? Colors.grey.shade500
                          : Colors.blue.shade600,
                    ),
                  ),

                if (item.isMenu) const SizedBox(width: 8),

                Expanded(
                  child: Text(
                    item.displayName,
                    style: TextStyle(
                      fontSize: item.isMenu ? 14 : 15,
                      fontWeight: item.isMenu
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isAlreadyDisplayed
                          ? Colors.grey.shade500
                          : (item.isMenu
                                ? Colors.grey.shade700
                                : Colors.black87),
                    ),
                  ),
                ),

                if (!item.isMenu && isAlreadyDisplayed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Displayed',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                else if (!item.isMenu)
                  Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: Colors.blue.shade600,
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

  bool _hasMatchingChildren(ChartConfigItem item) {
    if (item.children == null) return false;

    for (var child in item.children!) {
      if (child.displayName.toLowerCase().contains(_searchQuery)) {
        return true;
      }
      if (_hasMatchingChildren(child)) {
        return true;
      }
    }
    return false;
  }

  IconData _getChartIcon(DashboardChartType? type) {
    switch (type) {
      case DashboardChartType.bar:
        return Icons.bar_chart_rounded;
      case DashboardChartType.line:
        return Icons.show_chart_rounded;
      case DashboardChartType.pie:
        return Icons.pie_chart_rounded;
      case DashboardChartType.area:
        return Icons.area_chart_rounded;
      default:
        return Icons.analytics_rounded;
    }
  }
}
