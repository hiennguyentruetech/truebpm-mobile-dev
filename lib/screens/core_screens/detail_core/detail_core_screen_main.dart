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
        onSessionExpired: handleSessionExpired,
        initialDocSubTabCode: initialDocSubTabCode,
      );

      // Initialize original data for change tracking
      initializeChangeTracking();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _provider.dispose();
    super.dispose();
  }

  // Allow extracted part methods to trigger state updates safely.
  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
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
            showGenericErrorAndBack(msg);
          }
          return WillPopScope(
            onWillPop: onWillPop,
            child: _SwipeBackHandler(
              onSwipeBack: onSwipeBack,
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
