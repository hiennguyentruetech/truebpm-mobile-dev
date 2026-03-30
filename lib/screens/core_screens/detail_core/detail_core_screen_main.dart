part of 'detail_core_screen.dart';

/// Base detail screen that can be extended by module-specific detail screens
/// Provides common structure and functionality for all detail screens
abstract class DetailCoreScreen extends StatefulWidget {
  final Map<String, dynamic> listItem;
  final String? initialTabCode;
  final Map<String, dynamic>? dataSpy;
  final List<PrintReportOption>? printReports;
  final VoidCallback? onOperationSuccess; // Callback for successful operations
  final bool fromTaskScreen; // Flag to indicate if opened from task screen
  final String? taskId; // Task ID for approval/rejection actions

  const DetailCoreScreen({
    super.key,
    required this.listItem,
    this.initialTabCode,
    this.dataSpy,
    this.printReports,
    this.onOperationSuccess,
    this.fromTaskScreen = false,
    this.taskId,
  });

  /// Module code (e.g., 'MODULE', 'USER', 'ROLE')
  String get moduleCode;

  /// Display name for the module
  String get moduleName;

  /// List of available tabs for this module
  List<TabConfig> get availableTabs;

  /// Optional DOC sub-tabs (e.g., CORR, PIM). Override in module screens if needed.
  List<TabDocConfig>? get docSubTabs => null;

  @override
  State<DetailCoreScreen> createState() => _DetailCoreScreenState();
}

/// Generic detail screen that uses TabBodyFactory for backward compatibility
class GenericDetailCoreScreen extends DetailCoreScreen {
  final String _moduleCode;
  final String? _moduleName;
  final List<TabConfig>? _availableTabs;

  const GenericDetailCoreScreen({
    super.key,
    required String moduleCode,
    required super.listItem,
    String? moduleName,
    super.initialTabCode,
    super.dataSpy,
    List<TabConfig>? availableTabs,
    super.printReports,
    super.onOperationSuccess, // Add callback support
    super.fromTaskScreen = false, // Add task screen flag
    super.taskId, // Add task ID support
  }) : _moduleCode = moduleCode,
       _moduleName = moduleName,
       _availableTabs = availableTabs;
  @override
  String get moduleCode => _moduleCode;

  @override
  String get moduleName => _moduleName ?? '$_moduleCode Management';

  @override
  List<TabConfig> get availableTabs => _availableTabs ?? [];
}

class _DetailCoreScreenState extends State<DetailCoreScreen>
    with TickerProviderStateMixin {
  final ScrollController _docSubTabScrollController = ScrollController();
  late CoreDetailProvider _provider;
  late TabController? _tabController;
  String _currentTabCode = 'DTLS';

  // DOC sub-tab state managed at screen level so body rebuilds won't reset it
  String? _currentDocSubTabCode;

  // Track changes for unsaved changes warning
  bool _hasUnsavedChanges = false;
  // Legacy raw snapshots kept (might still be referenced by older tab bodies); suppress unused warnings
  // ignore: unused_field
  Map<String, dynamic> _originalData = {};
  // ignore: unused_field
  Map<String, dynamic> _currentData = {};
  // Enhanced dirty tracking (sanitized snapshot + suppression windows)
  Map<String, dynamic> _originalEditableSnapshot = {};
  DateTime? _screenInitTime;
  DateTime? _lastTabChangeTime;
  final Duration _initialSuppression = const Duration(milliseconds: 1200);
  final Duration _tabSwitchSuppression = const Duration(milliseconds: 800);
  bool _debugDirtyTracking = false; // set true for debug prints

  @override
  void initState() {
    super.initState();
    _currentTabCode = widget.initialTabCode ?? 'DTLS';

    // Initialize tab controller if tabs are available
    if (widget.availableTabs.isNotEmpty) {
      _tabController = TabController(
        length: widget.availableTabs.length,
        vsync: this,
        initialIndex: widget.availableTabs
            .indexWhere((tab) => tab.code == _currentTabCode)
            .clamp(0, widget.availableTabs.length - 1),
      );
    } else {
      _tabController = null;
    }

    _provider = CoreDetailProvider();

    // Use post frame callback to ensure widget is fully built before initializing provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // If starting on DOC tab, determine the default sub-tab first
      String? initialDocSubTabCode;
      if (_currentTabCode.toUpperCase() == 'DOC' &&
          widget.docSubTabs != null &&
          widget.docSubTabs!.isNotEmpty) {
        _currentDocSubTabCode = widget.docSubTabs!
            .firstWhere(
              (t) => t.isDefault,
              orElse: () => widget.docSubTabs!.first,
            )
            .code;
        initialDocSubTabCode = _currentDocSubTabCode;
      }

      await _provider.initialize(
        widget.moduleCode,
        widget.listItem,
        tabModuleCode: _currentTabCode,
        availableTabs: widget.availableTabs,
        onSessionExpired: _handleSessionExpired,
        initialDocSubTabCode: initialDocSubTabCode,
      );

      // Initialize original data for change tracking
      _initializeChangeTracking();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _provider.dispose();
    super.dispose();
  }

  /// Initialize change tracking with current data
  void _initializeChangeTracking() {
    if (_provider.rawResponse != null) {
      // Legacy fallback snapshots (kept for compatibility)
      _originalData = Map<String, dynamic>.from(_provider.rawResponse!);
      _currentData = Map<String, dynamic>.from(_provider.rawResponse!);

      // New sanitized editable snapshot
      _originalEditableSnapshot = _buildEditableSnapshot(_provider);
      _screenInitTime ??= DateTime.now(); // set only first time
      _hasUnsavedChanges = false;
      if (_debugDirtyTracking) {
        debugPrint(
          '[DirtyTrack] Baseline initialized. Keys=${_originalEditableSnapshot.keys.length}',
        );
      }
    }
  }

  /// Check if there are unsaved changes by comparing current data with original data
  bool _checkForUnsavedChanges() {
    if (_provider.rawResponse == null) return false;

    // Suppression windows (initial load or shortly after tab switch)
    final now = DateTime.now();
    if (_screenInitTime != null &&
        now.difference(_screenInitTime!) < _initialSuppression) {
      if (_debugDirtyTracking)
        debugPrint('[DirtyTrack] Suppressed (initial load window)');
      return false;
    }
    if (_lastTabChangeTime != null &&
        now.difference(_lastTabChangeTime!) < _tabSwitchSuppression) {
      if (_debugDirtyTracking)
        debugPrint('[DirtyTrack] Suppressed (tab switch window)');
      return false;
    }

    final currentSnapshot = _buildEditableSnapshot(_provider);
    final changed = _deepCompareData(
      _originalEditableSnapshot,
      currentSnapshot,
    );
    if (_debugDirtyTracking && changed) {
      debugPrint('[DirtyTrack] Detected change.');
    }
    return changed;
  }

  /// Deep comparison of two data maps
  bool _deepCompareData(dynamic data1, dynamic data2) {
    if (data1.runtimeType != data2.runtimeType) return true;

    if (data1 is Map) {
      if (data2 is! Map) return true;
      if (data1.length != data2.length) return true;

      for (final key in data1.keys) {
        if (!data2.containsKey(key)) return true;
        if (_deepCompareData(data1[key], data2[key])) return true;
      }
      return false;
    } else if (data1 is List) {
      if (data2 is! List) return true;
      if (data1.length != data2.length) return true;

      for (int i = 0; i < data1.length; i++) {
        if (_deepCompareData(data1[i], data2[i])) return true;
      }
      return false;
    } else {
      return data1 != data2;
    }
  }

  /// Show discard changes confirmation dialog
  Future<bool> _showDiscardChangesDialog() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DiscardChangesDialog(),
    );

    return result ?? false;
  }

  /// Handle data changes from widgets
  void _handleDataChanged(
    CoreDetailProvider provider,
    Map<String, dynamic> updatedData,
  ) {
    provider.updateRawResponse(updatedData);

    // Check for unsaved changes
    _hasUnsavedChanges = _checkForUnsavedChanges();
  }

  /// Reset change tracking after successful save
  void _resetChangeTracking() {
    if (_provider.rawResponse != null) {
      _originalData = Map<String, dynamic>.from(_provider.rawResponse!);
      _currentData = Map<String, dynamic>.from(_provider.rawResponse!);
      _originalEditableSnapshot = _buildEditableSnapshot(_provider);
      _hasUnsavedChanges = false;
      if (_debugDirtyTracking) debugPrint('[DirtyTrack] Baseline reset.');
    }
  }

  // Allow extracted part methods to trigger state updates safely.
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  /// Override back button behavior to check for unsaved changes
  Future<bool> _onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardChangesDialog();
      if (shouldDiscard) {
        return true; // Allow back navigation
      } else {
        return false; // Prevent back navigation
      }
    }
    return true; // Allow back navigation if no changes
  }

  /// Handle swipe back gesture with custom behavior
  Future<bool> _onSwipeBack() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardChangesDialog();
      if (shouldDiscard) {
        return true; // Allow swipe back
      } else {
        return false; // Prevent swipe back
      }
    }
    return true; // Allow swipe back if no changes
  }

  void _handleSessionExpired() {
    SessionHandler.handleSessionExpired(context);
  }

  Future<void> _changeTab(String tabCode) async {
    // Check for unsaved changes before switching tabs
    if (_hasUnsavedChanges) {
      final shouldDiscard = await _showDiscardChangesDialog();
      if (!shouldDiscard) {
        // User chose Cancel - revert tab selection to current tab
        if (_tabController != null) {
          final currentIndex = widget.availableTabs.indexWhere(
            (tab) => tab.code == _currentTabCode,
          );
          if (currentIndex >= 0) {
            _tabController!.index = currentIndex;
          }
        }
        return; // Stay on current tab
      }
      // Reset change tracking if discarding
      _resetChangeTracking();
    }

    setState(() {
      _currentTabCode = tabCode;
    });
    // Mark tab switch time for suppression window
    _lastTabChangeTime = DateTime.now();

    // If switching to DOC, determine the default sub-tab
    String? docSubTabCode;
    if (tabCode.toUpperCase() == 'DOC' &&
        widget.docSubTabs != null &&
        widget.docSubTabs!.isNotEmpty) {
      // Only set if not already set
      _currentDocSubTabCode ??= widget.docSubTabs!
          .firstWhere(
            (t) => t.isDefault,
            orElse: () => widget.docSubTabs!.first,
          )
          .code;
      docSubTabCode = _currentDocSubTabCode;
    }

    // Call provider to switch tab and fetch new data with sub-tab if applicable
    _provider.switchTab(
      tabCode,
      onSessionExpired: _handleSessionExpired,
      docSubTabCode: docSubTabCode,
    );

    // Re-initialize change tracking for new tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChangeTracking();
    });
  }

  // Build a sanitized snapshot focusing on editable content only
  Map<String, dynamic> _buildEditableSnapshot(CoreDetailProvider provider) {
    final raw = provider.rawResponse;
    if (raw == null) return {};

    // Prefer nested itemDetail.value if present
    dynamic itemDetail = raw['itemDetail'];
    if (itemDetail is Map<String, dynamic>) {
      if (itemDetail.containsKey('value') &&
          itemDetail['value'] is Map<String, dynamic>) {
        itemDetail = itemDetail['value'];
      } else if (itemDetail.containsKey('itemDetail') &&
          itemDetail['itemDetail'] is Map<String, dynamic>) {
        // Some responses nest deeper
        final nested = itemDetail['itemDetail'];
        if (nested is Map<String, dynamic> && nested.containsKey('value')) {
          itemDetail = nested['value'];
        }
      }
    }

    if (itemDetail is! Map<String, dynamic>) {
      return {};
    }

    final volatileKeys = {
      'lastModifiedDate',
      'lastModified',
      'lastUpdate',
      'updatedAt',
      'updatedTime',
      'status',
      'statusHistory',
      'logs',
      'attachments',
      'comments',
      '_timestamp',
    };

    dynamic sanitize(dynamic input) {
      if (input is Map<String, dynamic>) {
        final result = <String, dynamic>{};
        input.forEach((k, v) {
          if (volatileKeys.contains(k)) return; // skip volatile
          result[k] = sanitize(v);
        });
        return result;
      } else if (input is List) {
        return input.map(sanitize).toList();
      } else {
        return input; // primitive
      }
    }

    final sanitized = sanitize(itemDetail);
    if (sanitized is Map<String, dynamic>) {
      return sanitized;
    }
    return {};
  }

  /// Check if the current record is new (no ID)
  bool _isNewRecord(CoreDetailProvider provider) {
    final itemDetail = provider.itemDetail?.value;
    if (itemDetail == null) return widget.listItem['action'] == 'NEW';

    final id = itemDetail['id'];
    return id == null || id.toString().isEmpty;
  }

  /// Check if the current record was created from "New" action in list
  bool _isFromNewAction() {
    return widget.listItem['action'] == 'NEW';
  }

  /// Check if this operation should trigger list refresh (NEW or COPY -> SAVE)
  bool _shouldRefreshListOnSave() {
    return _isFromNewAction() || _wasCopyOperation();
  }

  /// Check if this was originally a COPY operation that should refresh list on save
  bool _wasCopyOperation() {
    // Check if we have cached COPY response in provider, indicating this was a COPY operation
    // Use the local provider instance to avoid depending on context lookup during lifecycle transitions
    return _provider.currentCachedAction == 'COPY';
  }

  void _showGenericErrorAndBack(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CoreActionDialog.showResponseDialog(
        context,
        response: {
          'success': false,
          'messageType': 'error',
          'message': message,
        },
        title: 'Error',
      );
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Consumer<CoreDetailProvider>(
        builder: (context, provider, child) {
          // Handle generic server/network error: show message and go back
          if (provider.lastErrorStatusCode != null &&
              (provider.lastErrorStatusCode! >= 500 ||
                  provider.lastErrorStatusCode == 0)) {
            final msg =
                provider.lastErrorMessage ??
                'Connection error. Please try again later.';
            provider.clearLastError();
            _showGenericErrorAndBack(msg);
          }
          return WillPopScope(
            onWillPop: _onWillPop,
            child: _SwipeBackHandler(
              onSwipeBack: _onSwipeBack,
              child: Scaffold(
                appBar: _buildAppBar(provider),
                body: Stack(
                  children: [
                    _buildBody(provider),
                    if (provider.showLoadingOverlay)
                      const LoadingOverlayWidget(),
                  ],
                ),
                bottomNavigationBar: widget.fromTaskScreen
                    ? _buildTaskFooter(provider)
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(CoreDetailProvider provider) {
    // Get item code from detail data or listItem
    String? itemCode =
        provider.itemDetail?.value['code'] ?? widget.listItem['code'];
    String displayTitle;

    // Show code if available, otherwise show module name
    if (itemCode != null && itemCode.isNotEmpty) {
      displayTitle = itemCode;
    } else {
      displayTitle = provider.title ?? widget.moduleName;
    }

    final hasDocSubTabs =
        widget.docSubTabs != null && (widget.docSubTabs!.isNotEmpty);
    final showDocSubTabs =
        hasDocSubTabs && _currentTabCode.toUpperCase() == 'DOC';
    final double appBarHeight = widget.availableTabs.isNotEmpty
        ? (showDocSubTabs ? 140.0 : 95.0)
        : kToolbarHeight;

    return PreferredSize(
      preferredSize: Size.fromHeight(appBarHeight),
      child: AppBar(
        title: Text(
          displayTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: _buildAppBarActions(provider),
        bottom: widget.availableTabs.isNotEmpty
            ? _buildTabsAreaInAppBar()
            : null,
      ),
    );
  }
}
