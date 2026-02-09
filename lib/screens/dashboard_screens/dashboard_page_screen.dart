import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truebpm/models/dashboard_model.dart';
import 'package:truebpm/providers/dashboard_provider.dart';
import 'package:truebpm/utils/session_handler.dart';
import 'package:truebpm/widgets/common/floating_add_button.dart';
import 'package:truebpm/widgets/core/core_toast.dart';
import 'package:truebpm/widgets/dashboard/dashboard_charts.dart';
import 'package:truebpm/widgets/dashboard/dashboard_widgets.dart';
import 'package:truebpm/widgets/dialogs/custom_confirm_dialog.dart';

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
    // Explicit listener để đảm bảo UI rebuild trong release mode
    _provider.addListener(_onProviderChanged);
    _initializeDashboard();
  }

  void _onProviderChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChanged);
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
        floatingActionButton: Consumer<DashboardProvider>(
          builder: (context, provider, _) {
            if (provider.allCharts.isEmpty) return const SizedBox.shrink();
            return FloatingAddButton(
              onPressed: () => _showAddChartDialog(provider),
              size: 52,
            );
          },
        ),
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
                    // Inbox cards (horizontal scroll) - no gap from app bar
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

                    const SizedBox(height: 10),

                    // // Section header for charts
                    // const Padding(
                    //   padding: EdgeInsets.symmetric(horizontal: 16),
                    //   child: Text(
                    //     'Charts',
                    //     style: TextStyle(
                    //       fontSize: 18,
                    //       fontWeight: FontWeight.bold,
                    //     ),
                    //   ),
                    // ),

                    // const SizedBox(height: 8),

                    // Default charts
                    if (provider.displayedCharts.isEmpty &&
                        !provider.isLoadingCharts)
                      Padding(
                        padding: const EdgeInsets.all(7),
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
    if (!mounted) return;
    final parentContext = context;
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddChartBottomSheet(
        chartTree: provider.chartConfigTree,
        isChartDisplayed: (chartId) => provider.isChartDisplayed(chartId),
        onChartSelected: (chart) {
          Navigator.pop(sheetContext);

          // Check if chart already displayed
          if (provider.isChartDisplayed(chart.id)) {
            if (mounted) {
              CoreToast.warning(
                parentContext,
                '"${chart.name}" is already displayed',
              );
            }
            return;
          }

          // Add chart to dashboard
          provider.addChart(chart);
          if (mounted) {
            CoreToast.success(parentContext, 'Added "${chart.name}" to dashboard');
          }
          
          // Auto scroll to bottom after adding chart
          _scrollToBottom();
        },
      ),
    );
  }

  /// Scroll to bottom of the list to show newly added chart
  void _scrollToBottom() {
    // Wait for the new chart to be rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _confirmRemoveChart(
    DisplayedChartItem chart,
    DashboardProvider provider,
  ) {
    CustomConfirmDialog.showDelete(
      context,
      title: 'Remove Chart',
      message:
          'Are you sure you want to remove "${chart.name}" from dashboard?',
      confirmText: 'Remove',
      cancelText: 'Cancel',
      onConfirm: () {
        provider.removeChart(chart.id);
        CoreToast.info(this.context, 'Removed "${chart.name}" from dashboard');
      },
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
    // Reload if chart changed (e.g., after replaceChart)
    if (oldWidget.chartId != widget.chartId ||
        oldWidget.chartName != widget.chartName) {
      _currentChartId = widget.chartId;
      _filterValues = {};
      _chartData = null;
      _loadChartData(forceReload: true);
    }
  }

  Future<void> _loadChartData({bool forceReload = false}) async {
    setState(() => _isLoading = true);

    final data = await widget.provider.loadChartDetail(
      _currentChartId,
      filterValues: _filterValues.isNotEmpty ? _filterValues : null,
      forceReload: forceReload,
    );

    if (mounted && data != null) {
      // Validate filter values against available options
      final validatedFilters = _validateFilterValues(data);
      
      // Check if any filter values were corrected
      final needsReload = !_areFilterValuesEqual(data.filterValues, validatedFilters);
      
      if (needsReload) {
        // Filter values were corrected, reload with valid values
        setState(() {
          _filterValues = validatedFilters;
        });
        // Reload data with corrected filter values
        _onFilterChanged(validatedFilters);
      } else {
        setState(() {
          _chartData = data;
          _isLoading = false;
          _filterValues = Map.from(data.filterValues);
        });
      }
    } else if (mounted) {
      setState(() {
        _chartData = data;
        _isLoading = false;
      });
    }
  }

  /// Validate filter values against available filter options
  /// Returns corrected filter values where invalid values are replaced with first option
  Map<String, String> _validateFilterValues(ChartDetailData data) {
    final Map<String, String> validatedFilters = {};
    
    for (final filter in data.filters) {
      final currentValue = data.filterValues[filter.field] ?? '';
      
      // Check if current value exists in filter options
      final isValidValue = filter.options.any((opt) => opt.value == currentValue);
      
      if (isValidValue) {
        // Value is valid, keep it
        validatedFilters[filter.field] = currentValue;
      } else if (filter.options.isNotEmpty) {
        // Value is not in options, use first option as default
        validatedFilters[filter.field] = filter.options.first.value;
      } else {
        // No options available, keep original value
        validatedFilters[filter.field] = currentValue;
      }
    }
    
    return validatedFilters;
  }

  /// Compare two filter value maps for equality
  bool _areFilterValuesEqual(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
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
    if (!mounted) return;
    final currentContext = context;
    showModalBottomSheet(
      context: currentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _AddChartBottomSheet(
        chartTree: widget.chartTree,
        isChartDisplayed: (chartId) =>
            widget.provider.isChartDisplayed(chartId) &&
            chartId != _currentChartId,
        onChartSelected: (chart) {
          Navigator.pop(sheetContext);
          if (mounted) {
            widget.onReplaceChart?.call(chart);
          }
        },
        title: 'Change Chart',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DashboardChartCard(
      title: _chartData?.label ?? widget.chartName,
      chartType: _chartData?.type, // Pass chart type for dynamic icon
      isLoading: _isLoading,
      filters: _chartData?.filters,
      currentFilterValues: _filterValues,
      onFilterChanged: _onFilterChanged,
      onRemove: widget.onRemove,
      onRefresh: () => _loadChartData(forceReload: true),
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

/// Bottom sheet for adding new chart or changing chart - Styled like CoreSelect DropdownDialog
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
  final FocusNode _searchFocusNode = FocusNode();
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
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Count total selectable charts (non-menu items)
  int _countSelectableCharts(List<ChartConfigItem> items) {
    int count = 0;
    for (var item in items) {
      if (!item.isMenu) {
        count++;
      }
      if (item.children != null) {
        count += _countSelectableCharts(item.children!);
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final totalCharts = _countSelectableCharts(widget.chartTree);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          _searchFocusNode.unfocus();
        },
        child: Column(
          children: [
            // Beautiful header with gradient - same as CoreSelect DropdownDialog
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
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
                      Icons.dashboard_customize_rounded,
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
                          widget.title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$totalCharts charts available',
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
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: TextFormField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: false,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search charts...',
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
                                setState(() {
                                  _searchQuery = '';
                                });
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

            // Chart tree with styled cards
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(10),
                children: widget.chartTree
                    .map((item) => _buildTreeNode(item, 0))
                    .toList(),
              ),
            ),
          ],
        ),
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

    // Menu node (folder)
    if (item.isMenu) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Menu header with gradient
          Container(
            margin: EdgeInsets.only(
              left: depth * 12.0,
              top: depth == 0 ? 0 : 8,
              bottom: 4,
            ),
            child: InkWell(
              onTap: hasChildren
                  ? () {
                      setState(() {
                        _expandedNodes[nodeKey] = !isExpanded;
                      });
                    }
                  : null,
              splashFactory: InkRipple.splashFactory,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey.shade100, Colors.grey.shade50],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_right_rounded,
                      size: 20,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.folder_rounded,
                      size: 18,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                    if (hasChildren)
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: Colors.blue.shade400,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Children
          if (hasChildren && isExpanded)
            ...item.children!.map((child) => _buildTreeNode(child, depth + 1)),
        ],
      );
    }

    // Chart item card - styled like CoreSelect option
    return Container(
      margin: EdgeInsets.only(left: depth * 12.0, bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAlreadyDisplayed
              ? null
              : () {
                  FocusScope.of(context).unfocus();
                  // Delay để đảm bảo keyboard dismiss xong trước khi navigate
                  Future.microtask(() {
                    if (mounted) {
                      widget.onChartSelected(item);
                    }
                  });
                },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isAlreadyDisplayed ? Colors.grey.shade100 : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isAlreadyDisplayed
                    ? Colors.grey.shade300
                    : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                if (!isAlreadyDisplayed)
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              children: [
                // Chart icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isAlreadyDisplayed
                        ? Colors.grey.shade200
                        : Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _getChartIcon(item.chartType?.type),
                    size: 18,
                    color: isAlreadyDisplayed
                        ? Colors.grey.shade500
                        : Colors.blue.shade600,
                  ),
                ),
                const SizedBox(width: 12),

                // Chart name
                Expanded(
                  child: Text(
                    item.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isAlreadyDisplayed
                          ? Colors.grey.shade500
                          : const Color(0xFF374151),
                    ),
                  ),
                ),

                // Status indicator
                if (isAlreadyDisplayed)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Displayed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_rounded,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
