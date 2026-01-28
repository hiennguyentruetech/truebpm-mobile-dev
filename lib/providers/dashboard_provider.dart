import 'package:flutter/foundation.dart';
import 'package:truebpm/models/dashboard_model.dart';
import 'package:truebpm/models/user_model.dart';
import 'package:truebpm/services/dashboard_service.dart';
import 'package:truebpm/utils/global_store.dart';

/// Displayed chart item - represents a chart shown on dashboard
class DisplayedChartItem {
  final String id;
  final String name;
  final String chartId;

  DisplayedChartItem({
    required this.id,
    required this.name,
    required this.chartId,
  });

  /// Create from DefaultChartItem (from API config)
  factory DisplayedChartItem.fromDefaultChart(DefaultChartItem chart) {
    return DisplayedChartItem(
      id: 'default_${chart.id}',
      name: chart.name,
      chartId: chart.id,
    );
  }

  /// Create from ChartConfigItem (when adding new chart)
  factory DisplayedChartItem.fromChartConfig(ChartConfigItem chart) {
    return DisplayedChartItem(
      id: 'added_${chart.id}_${DateTime.now().millisecondsSinceEpoch}',
      name: chart.name,
      chartId: chart.id,
    );
  }

  /// Create copy with new chart
  DisplayedChartItem copyWith({String? name, String? chartId}) {
    return DisplayedChartItem(
      id: id,
      name: name ?? this.name,
      chartId: chartId ?? this.chartId,
    );
  }
}

/// Provider for Dashboard state management
class DashboardProvider extends ChangeNotifier {
  final DashboardService _service = DashboardService.instance;

  // Loading states
  bool _isLoadingPageData = false;
  bool _isLoadingInbox = false;
  bool _isLoadingCharts = false;
  bool _isLoadingChartDetail = false;

  // Error states
  String? _errorMessage;

  // Data states
  DashboardPageDataResponse? _pageData;
  DashboardListResponse? _inboxData;
  DashboardConfig? _dashboardConfig;
  UserModel? _currentUser;

  // Chart details cache: chartId -> ChartDetailData
  final Map<String, ChartDetailData> _chartDetailsCache = {};

  // Displayed charts (can be modified by user)
  final List<DisplayedChartItem> _displayedCharts = [];

  // Year filter for inbox
  int _selectedYear = DateTime.now().year;

  // Selected chart for detail view
  ChartConfigItem? _selectedChartConfig;

  // Getters
  bool get isLoadingPageData => _isLoadingPageData;
  bool get isLoadingInbox => _isLoadingInbox;
  bool get isLoadingCharts => _isLoadingCharts;
  bool get isLoadingChartDetail => _isLoadingChartDetail;
  bool get isLoading =>
      _isLoadingPageData || _isLoadingInbox || _isLoadingCharts;

  String? get errorMessage => _errorMessage;

  DashboardPageDataResponse? get pageData => _pageData;
  DashboardListResponse? get inboxData => _inboxData;
  DashboardConfig? get dashboardConfig => _dashboardConfig;
  UserModel? get currentUser => _currentUser;

  int get selectedYear => _selectedYear;
  ChartConfigItem? get selectedChartConfig => _selectedChartConfig;

  // Computed getters
  List<ChartConfigItem> get chartConfigTree =>
      _pageData?.chartConfigs.data ?? [];
  List<ChartConfigItem> get allCharts =>
      _pageData?.chartConfigs.allCharts ?? [];
  ChartConfigItem? get defaultChartConfig =>
      _pageData?.chartConfigs.defaultChart;

  List<InboxDataItem> get inboxItems => _inboxData?.data ?? [];
  List<DefaultChartItem> get defaultCharts =>
      _dashboardConfig?.defaultCharts ?? [];

  // Displayed charts getter (this is what UI should use)
  List<DisplayedChartItem> get displayedCharts =>
      List.unmodifiable(_displayedCharts);

  /// Get chart detail from cache
  ChartDetailData? getChartDetail(String chartId) =>
      _chartDetailsCache[chartId];

  /// Check if chart detail is loading
  bool isChartLoading(String chartId) =>
      _isLoadingChartDetail && _selectedChartConfig?.id == chartId;

  /// Get years for dropdown (current year - 5 to current year)
  List<int> get availableYears {
    final currentYear = DateTime.now().year;
    return List.generate(6, (i) => currentYear - i);
  }

  /// Initialize dashboard - load all required data
  Future<void> initialize({Function? onSessionExpired}) async {
    logger.i('Initializing Dashboard...');

    _errorMessage = null;

    // Load user info first
    _currentUser = await _service.getCurrentUser();
    if (_currentUser == null) {
      _errorMessage = 'User not found. Please login again.';
      onSessionExpired?.call();
      notifyListeners();
      return;
    }

    // Load all data in parallel
    await Future.wait([
      _loadPageData(onSessionExpired: onSessionExpired),
      _loadInboxData(onSessionExpired: onSessionExpired),
      _loadDashboardConfig(onSessionExpired: onSessionExpired),
    ]);

    // Load default chart details after config is loaded
    if (_dashboardConfig != null &&
        _dashboardConfig!.defaultCharts.isNotEmpty) {
      // Initialize displayed charts from default config
      _initDisplayedCharts();
      await _loadDefaultChartDetails();
    }

    logger.i('Dashboard initialized successfully');
  }

  /// Initialize displayed charts from default config
  void _initDisplayedCharts() {
    _displayedCharts.clear();
    for (var chart in defaultCharts) {
      _displayedCharts.add(DisplayedChartItem.fromDefaultChart(chart));
    }
    notifyListeners();
  }

  /// Add a new chart to displayed charts
  void addChart(ChartConfigItem chart) {
    // Check if chart already exists
    final exists = _displayedCharts.any((c) => c.chartId == chart.id);
    if (exists) {
      logger.w('Chart ${chart.id} already displayed');
      return;
    }

    _displayedCharts.add(DisplayedChartItem.fromChartConfig(chart));
    logger.i('Added chart ${chart.name} to dashboard');
    notifyListeners();

    // Load chart data
    loadChartDetail(chart.id);
  }

  /// Remove a chart from displayed charts
  void removeChart(String displayedChartId) {
    final index = _displayedCharts.indexWhere((c) => c.id == displayedChartId);
    if (index >= 0) {
      final removed = _displayedCharts.removeAt(index);
      logger.i('Removed chart ${removed.name} from dashboard');
      notifyListeners();
    }
  }

  /// Replace a chart with another chart
  void replaceChart(String displayedChartId, ChartConfigItem newChart) {
    final index = _displayedCharts.indexWhere((c) => c.id == displayedChartId);
    if (index >= 0) {
      _displayedCharts[index] = DisplayedChartItem(
        id: displayedChartId,
        name: newChart.name,
        chartId: newChart.id,
      );
      logger.i('Replaced chart at index $index with ${newChart.name}');
      notifyListeners();

      // Load new chart data
      loadChartDetail(newChart.id);
    }
  }

  /// Check if a chart is already displayed
  bool isChartDisplayed(String chartId) {
    return _displayedCharts.any((c) => c.chartId == chartId);
  }

  /// Load PAGEDATA
  Future<void> _loadPageData({Function? onSessionExpired}) async {
    _isLoadingPageData = true;
    notifyListeners();

    try {
      _pageData = await _service.fetchPageData();
      if (_pageData == null) {
        onSessionExpired?.call();
      }
    } catch (e) {
      logger.e('Error loading page data: $e');
      _errorMessage = 'Failed to load chart configurations';
    } finally {
      _isLoadingPageData = false;
      notifyListeners();
    }
  }

  /// Load inbox data (LST)
  Future<void> _loadInboxData({Function? onSessionExpired}) async {
    _isLoadingInbox = true;
    notifyListeners();

    try {
      _inboxData = await _service.fetchListData(year: _selectedYear);
      if (_inboxData == null) {
        onSessionExpired?.call();
      }
    } catch (e) {
      logger.e('Error loading inbox data: $e');
      _errorMessage = 'Failed to load inbox data';
    } finally {
      _isLoadingInbox = false;
      notifyListeners();
    }
  }

  /// Load dashboard config (DTLS)
  Future<void> _loadDashboardConfig({Function? onSessionExpired}) async {
    _isLoadingCharts = true;
    notifyListeners();

    try {
      _dashboardConfig = await _service.fetchDashboardConfig();
      if (_dashboardConfig == null) {
        onSessionExpired?.call();
      }
    } catch (e) {
      logger.e('Error loading dashboard config: $e');
      _errorMessage = 'Failed to load dashboard configuration';
    } finally {
      _isLoadingCharts = false;
      notifyListeners();
    }
  }

  /// Load default chart details
  Future<void> _loadDefaultChartDetails() async {
    if (_dashboardConfig == null) return;

    for (var chart in _dashboardConfig!.defaultCharts) {
      await loadChartDetail(chart.id);
    }
  }

  /// Load chart detail data
  Future<ChartDetailData?> loadChartDetail(
    String chartId, {
    Map<String, String>? filterValues,
    bool forceReload = false,
  }) async {
    // Return cached data if available and not forcing reload
    if (!forceReload && _chartDetailsCache.containsKey(chartId)) {
      return _chartDetailsCache[chartId];
    }

    _isLoadingChartDetail = true;
    notifyListeners();

    try {
      final chartDetail = await _service.fetchChartDetail(
        chartId: chartId,
        filterValues: filterValues,
      );

      if (chartDetail != null) {
        _chartDetailsCache[chartId] = chartDetail;
      }

      return chartDetail;
    } catch (e) {
      logger.e('Error loading chart detail: $e');
      return null;
    } finally {
      _isLoadingChartDetail = false;
      notifyListeners();
    }
  }

  /// Refresh chart with new filter values
  Future<ChartDetailData?> refreshChartWithFilters(
    String chartId,
    Map<String, String> filterValues,
  ) async {
    return await loadChartDetail(
      chartId,
      filterValues: filterValues,
      forceReload: true,
    );
  }

  /// Change selected year and reload inbox
  Future<void> changeYear(int year, {Function? onSessionExpired}) async {
    if (year == _selectedYear) return;

    _selectedYear = year;
    await _loadInboxData(onSessionExpired: onSessionExpired);
  }

  /// Select a chart config for viewing
  void selectChartConfig(ChartConfigItem config) {
    _selectedChartConfig = config;
    notifyListeners();
  }

  /// Refresh all data
  Future<void> refresh({Function? onSessionExpired}) async {
    _chartDetailsCache.clear();
    _displayedCharts.clear();
    await initialize(onSessionExpired: onSessionExpired);
  }

  /// Clear chart cache
  void clearChartCache() {
    _chartDetailsCache.clear();
    notifyListeners();
  }

  /// Find chart config by ID
  ChartConfigItem? findChartConfigById(String id) {
    for (var chart in allCharts) {
      if (chart.id == id) return chart;
    }
    return null;
  }

  @override
  void dispose() {
    _chartDetailsCache.clear();
    super.dispose();
  }
}
