import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/models/tab_doc_config.dart';
import 'package:truebpm/providers/core_detail_provider.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/utils/session_handler.dart';
import 'package:truebpm/utils/keyboard_utils.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

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
       _availableTabs = availableTabs;  @override
  String get moduleCode => _moduleCode;

  @override
  String get moduleName => _moduleName ?? '$_moduleCode Management';

  @override
  List<TabConfig> get availableTabs => _availableTabs ?? [];
}

class _DetailCoreScreenState extends State<DetailCoreScreen> with TickerProviderStateMixin {
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
        initialIndex: widget.availableTabs.indexWhere((tab) => tab.code == _currentTabCode).clamp(0, widget.availableTabs.length - 1),
      );
    } else {
      _tabController = null;
    }
    
    _provider = CoreDetailProvider();
    
    // Use post frame callback to ensure widget is fully built before initializing provider
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // If starting on DOC tab, determine the default sub-tab first
      String? initialDocSubTabCode;
      if (_currentTabCode.toUpperCase() == 'DOC' && widget.docSubTabs != null && widget.docSubTabs!.isNotEmpty) {
        _currentDocSubTabCode = widget.docSubTabs!.firstWhere(
          (t) => t.isDefault,
          orElse: () => widget.docSubTabs!.first,
        ).code;
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
        debugPrint('[DirtyTrack] Baseline initialized. Keys=${_originalEditableSnapshot.keys.length}');
      }
    }
  }

  /// Check if there are unsaved changes by comparing current data with original data
  bool _checkForUnsavedChanges() {
    if (_provider.rawResponse == null) return false;

    // Suppression windows (initial load or shortly after tab switch)
    final now = DateTime.now();
    if (_screenInitTime != null && now.difference(_screenInitTime!) < _initialSuppression) {
      if (_debugDirtyTracking) debugPrint('[DirtyTrack] Suppressed (initial load window)');
      return false;
    }
    if (_lastTabChangeTime != null && now.difference(_lastTabChangeTime!) < _tabSwitchSuppression) {
      if (_debugDirtyTracking) debugPrint('[DirtyTrack] Suppressed (tab switch window)');
      return false;
    }

    final currentSnapshot = _buildEditableSnapshot(_provider);
    final changed = _deepCompareData(_originalEditableSnapshot, currentSnapshot);
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
  void _handleDataChanged(CoreDetailProvider provider, Map<String, dynamic> updatedData) {
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
          final currentIndex = widget.availableTabs.indexWhere((tab) => tab.code == _currentTabCode);
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
    if (tabCode.toUpperCase() == 'DOC' && widget.docSubTabs != null && widget.docSubTabs!.isNotEmpty) {
      // Only set if not already set
      _currentDocSubTabCode ??= widget.docSubTabs!.firstWhere(
        (t) => t.isDefault,
        orElse: () => widget.docSubTabs!.first,
      ).code;
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
      if (itemDetail.containsKey('value') && itemDetail['value'] is Map<String, dynamic>) {
        itemDetail = itemDetail['value'];
      } else if (itemDetail.containsKey('itemDetail') && itemDetail['itemDetail'] is Map<String, dynamic>) {
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
      'lastModifiedDate', 'lastModified', 'lastUpdate', 'updatedAt', 'updatedTime',
      'status', 'statusHistory', 'logs', 'attachments', 'comments', '_timestamp'
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
          if (provider.lastErrorStatusCode != null && (provider.lastErrorStatusCode! >= 500 || provider.lastErrorStatusCode == 0)) {
            final msg = provider.lastErrorMessage ?? 'Connection error. Please try again later.';
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
                    if (provider.showLoadingOverlay) const LoadingOverlayWidget(),
                  ],
                ),
                bottomNavigationBar: widget.fromTaskScreen ? _buildTaskFooter(provider) : null,
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(CoreDetailProvider provider) {
    // Get item code from detail data or listItem
    String? itemCode = provider.itemDetail?.value['code'] ?? widget.listItem['code'];
    String displayTitle;
    
    // Show code if available, otherwise show module name
    if (itemCode != null && itemCode.isNotEmpty) {
      displayTitle = itemCode;
    } else {
      displayTitle = provider.title ?? widget.moduleName;
    }
    
    final hasDocSubTabs = widget.docSubTabs != null && (widget.docSubTabs!.isNotEmpty);
    final showDocSubTabs = hasDocSubTabs && _currentTabCode.toUpperCase() == 'DOC';
    final double appBarHeight = widget.availableTabs.isNotEmpty
        ? (showDocSubTabs ? 140.0 : 95.0)
        : kToolbarHeight;

    return PreferredSize(
      preferredSize: Size.fromHeight(appBarHeight),
      child: AppBar(
        title: Text(
          displayTitle,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: _buildAppBarActions(provider),
        bottom: widget.availableTabs.isNotEmpty ? _buildTabsAreaInAppBar() : null,
      ),
    );
  }

  List<Widget> _buildAppBarActions(CoreDetailProvider provider) {
    List<Widget> actions = [];
    final isNewRecord = _isNewRecord(provider);
    
    // Quick Save Action - check if save is hidden or disabled
    if (provider.isToolbarVisible(ToolbarAction.save)) {
      final isSaveDisabled = !provider.isToolbarEnabled(ToolbarAction.save) || provider.showLoadingOverlay;
      actions.add(
        IconButton(
          onPressed: isSaveDisabled ? null : () => _handleTabSave(provider),
          icon: Icon(
            Icons.save_outlined, 
            size: 22, 
            color: isSaveDisabled ? Colors.white.withOpacity(0.5) : Colors.white,
          ),
          tooltip: 'Save',
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
        ),
      );
    }

    // Build popup menu items based on toolbar states
    List<PopupMenuEntry<String>> menuItems = [];
    
    // Submit action - follow toolbar visibility; do not hard-hide for new records
    if (provider.isToolbarVisible(ToolbarAction.submit) && !widget.fromTaskScreen) {
      final isSubmitDisabled = !provider.isToolbarEnabled(ToolbarAction.submit);
      menuItems.add(
        _buildToolbarPopupItem(
          value: 'submit',
          label: 'Submit',
          icon: Icons.send_outlined,
          color: Colors.green,
          enabled: !isSubmitDisabled,
        ),
      );
    }
    
    // Refresh action (không có trong toolbar config, luôn hiển thị)
    menuItems.add(
      _buildToolbarPopupItem(
        value: 'refresh',
        label: 'Refresh',
        icon: Icons.refresh_outlined,
        color: Colors.blue,
        enabled: true,
      ),
    );
    
    // Copy action - disabled for new records and hidden when from task screen
    if (provider.isToolbarVisible(ToolbarAction.copy) && !isNewRecord && !widget.fromTaskScreen) {
      final isCopyDisabled = !provider.isToolbarEnabled(ToolbarAction.copy);
      menuItems.add(
        _buildToolbarPopupItem(
          value: 'copy',
          label: 'Copy',
          icon: Icons.copy_outlined,
          color: Colors.purple,
          enabled: !isCopyDisabled,
        ),
      );
    }
    
    // Print action - disabled for new records
    if (provider.isToolbarVisible(ToolbarAction.print) && !isNewRecord) {
      final isPrintDisabled = !provider.isToolbarEnabled(ToolbarAction.print);
      menuItems.add(
        _buildToolbarPopupItem(
          value: 'print',
          label: 'Print',
          icon: Icons.print_outlined,
          color: Colors.teal,
          enabled: !isPrintDisabled,
        ),
      );
    }
    
    // Cancel action - disabled for new records and hidden when from task screen
    if (provider.isToolbarVisible(ToolbarAction.cancel) && !isNewRecord && !widget.fromTaskScreen) {
      final isCancelDisabled = !provider.isToolbarEnabled(ToolbarAction.cancel);
      menuItems.add(
        _buildToolbarPopupItem(
          value: 'cancel',
          label: 'Cancel',
          icon: Icons.cancel_outlined,
          color: Colors.orange,
          enabled: !isCancelDisabled,
        ),
      );
    }
    
    // Add divider if we have delete action
    if (provider.isToolbarVisible(ToolbarAction.delete) && !isNewRecord && !widget.fromTaskScreen && menuItems.isNotEmpty) {
      menuItems.add(const PopupMenuDivider(height: 10));
    }
    
    // Delete action - disabled for new records and hidden when from task screen
    if (provider.isToolbarVisible(ToolbarAction.delete) && !isNewRecord && !widget.fromTaskScreen) {
      final isDeleteDisabled = !provider.isToolbarEnabled(ToolbarAction.delete);
      menuItems.add(
        _buildToolbarPopupItem(
          value: 'delete',
          label: 'Delete',
          icon: Icons.delete_outline,
          color: Colors.red,
          enabled: !isDeleteDisabled,
          isDestructive: true,
        ),
      );
    }

    // Only show popup menu if there are menu items
    if (menuItems.isNotEmpty) {
      actions.add(
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, provider),
          enabled: !provider.showLoadingOverlay,
          icon: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withOpacity(0),
                width: 1,
              ),
            ),
            child: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: Colors.white.withOpacity(provider.showLoadingOverlay ? 0.55 : 1),
            ),
          ),
          padding: const EdgeInsets.only(left: 4, right: 6),
          tooltip: 'More actions',
          color: Colors.white,
          elevation: 14,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(
              color: Colors.blueGrey.withOpacity(0.12),
            ),
          ),
          offset: const Offset(0, 44),
          itemBuilder: (context) => menuItems,
        ),
      );
    }
    
    return actions;
  }

  PopupMenuItem<String> _buildToolbarPopupItem({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
    required bool enabled,
    bool isDestructive = false,
  }) {
    final iconColor = enabled
        ? (isDestructive ? Colors.red.shade600 : color)
        : Colors.grey.shade400;
    final textColor = enabled
        ? (isDestructive ? Colors.red.shade700 : Colors.grey.shade900)
        : Colors.grey.shade400;

    return PopupMenuItem<String>(
      value: value,
      enabled: enabled,
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(enabled ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: iconColor.withOpacity(enabled ? 0.2 : 0.12),
              ),
            ),
            child: Icon(
              icon,
              size: 17,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  void _handleMenuAction(String action, CoreDetailProvider provider) {
    switch (action) {
      case 'submit':
        _handleTabSubmit(provider);
        break;
      case 'refresh':
        _handleTabRefresh(provider);
        break;
      case 'copy':
        _handleCopy(provider);
        break;
      case 'print':
        _handlePrint(provider);
        break;
      case 'cancel':
        _handleCancel(provider);
        break;
      case 'delete':
        _handleDelete(provider);
        break;
    }
  }

  Future<void> _handleCopy(CoreDetailProvider provider) async {
    try {
      provider.setLoadingOverlay(true);

      // 1) Force switch to default tab BEFORE calling COPY API to avoid RangeError
      // Determine default tab: explicit isDefault -> DTLS -> first
      String defaultTabCode = 'DTLS';
      final tabs = widget.availableTabs;
      final explicitDefault = tabs.firstWhere(
        (t) => t.isDefault == true,
        orElse: () => TabConfig(code: '', name: ''),
      );
      if (explicitDefault.code.isNotEmpty) {
        defaultTabCode = explicitDefault.code;
      } else if (tabs.any((t) => t.code.toUpperCase() == 'DTLS')) {
        defaultTabCode = tabs.firstWhere((t) => t.code.toUpperCase() == 'DTLS').code;
      } else if (tabs.isNotEmpty) {
        defaultTabCode = tabs.first.code;
      }

      if (_currentTabCode != defaultTabCode) {
        // Update local state and TabController index to match default tab
        final newIndex = tabs.indexWhere((t) => t.code == defaultTabCode);
        if (newIndex >= 0 && _tabController != null && newIndex < _tabController!.length) {
          _tabController!.index = newIndex;
        }
        setState(() {
          _currentTabCode = defaultTabCode;
        });
        await _provider.switchTab(defaultTabCode, onSessionExpired: _handleSessionExpired);
      }
      
      // 2) Prepare payloads after tab is stable
      final userData = await _getUserData();
      final itemDetail = _getItemDetail(provider);
      final dataSpy = _getDataSpy();

      // 3) Call COPY API
      final response = await CoreService.instance.copyData(
        widget.moduleCode,
        _currentTabCode,
        userData,
        itemDetail,
        dataSpy,
      );

      if (mounted && response != null) {
        if (response['success'] == true) {
          // Update provider state from response
          provider.updateDataAfterCopy(response);
          // Reset change tracking after successful copy
          _resetChangeTracking();
          // Do NOT mutate widget.listItem here. We keep list screen data intact.
        }

        CoreActionDialog.showResponseDialog(
          context,
          response: response,
          title: 'Copy Operation',
          onSuccess: () {
            // Already on default tab; nothing else to do here
          },
        );
      } else if (mounted) {
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': 'Copy operation failed or session expired',
          },
          title: 'Copy Operation',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        try {
          errorMessage = 'Copy failed: ${e.toString()}';
        } catch (_) {
          errorMessage = 'Copy operation failed due to an unexpected error';
        }
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': errorMessage,
          },
          title: 'Copy Operation',
        );
      }
    } finally {
      provider.setLoadingOverlay(false);
    }
  }

  Future<void> _handlePrint(CoreDetailProvider provider) async {
    final reports = widget.printReports;
    if (reports == null || reports.isEmpty) {
      CoreActionDialog.showResponseDialog(
        context,
        response: {
          'success': false,
          'messageType': 'warning',
          'message': 'No print reports available for this module',
        },
        title: 'Print Reports',
      );
      return;
    }

    CoreActionDialog.showPrintDialog(
      context,
      reports: reports,
      itemDetail: _getItemDetail(provider),
      onReportSelected: (url) async {
        try {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            if (mounted) {
              CoreActionDialog.showResponseDialog(
                context,
                response: {
                  'success': false,
                  'messageType': 'error',
                  'message': 'Could not open the report URL',
                },
                title: 'Print Report',
              );
            }
          }
        } catch (e) {
          if (mounted) {
            CoreActionDialog.showResponseDialog(
              context,
              response: {
                'success': false,
                'messageType': 'error',
                'message': 'Error opening report: $e',
              },
              title: 'Print Report',
            );
          }
        }
      },
    );
  }

  Future<void> _handleCancel(CoreDetailProvider provider) async {
    // Show confirmation dialog using custom dialog
    final confirmed = await CustomConfirmDialog.showCancelChanges(
      context,
      onConfirm: () {
        // Will be handled after dialog returns true
      },
    );

    if (confirmed == true) {
      try {
        provider.setLoadingOverlay(true);
        
        // Get required data for payload
        final userData = await _getUserData();
        final itemDetail = _getItemDetail(provider);
        final dataSpy = _getDataSpy();
        
        // Call API through CoreService
        final response = await CoreService.instance.cancelData(
          widget.moduleCode,
          _currentTabCode,
          userData,
          itemDetail,
          dataSpy,
        );
        
        if (mounted && response != null) {
          // Update data directly from cancel response without additional API call
          if (response['success'] == true) {
            provider.updateDataAfterSave(response);
            // Reset change tracking after successful cancel
            _resetChangeTracking();
          }
          
          CoreActionDialog.showResponseDialog(
            context,
            response: response,
            title: 'Cancel Operation',
            onSuccess: () {
              // Navigate back after successful cancel
              Navigator.of(context).pop();
            },
          );
        } else if (mounted) {
          CoreActionDialog.showResponseDialog(
            context,
            response: {
              'success': false,
              'messageType': 'error',
              'message': 'Cancel operation failed or session expired',
            },
            title: 'Cancel Operation',
          );
        }
      } catch (e) {
        if (mounted) {
          // Safely handle error message to avoid type casting issues
          String errorMessage;
          try {
            errorMessage = 'Cancel failed: ${e.toString()}';
          } catch (stringError) {
            errorMessage = 'Cancel operation failed due to an unexpected error';
          }
          
          CoreActionDialog.showResponseDialog(
            context,
            response: {
              'success': false,
              'messageType': 'error',
              'message': errorMessage,
            },
            title: 'Cancel Operation',
          );
        }
      } finally {
        provider.setLoadingOverlay(false);
      }
    }
  }

  Future<void> _handleDelete(CoreDetailProvider provider) async {
    // Show confirmation dialog using custom dialog
    final confirmed = await CustomConfirmDialog.showDelete(
      context,
      title: 'Confirm Delete',
      message: 'Are you sure you want to delete this item? This action cannot be undone.',
      onConfirm: () {
        // Will be handled after dialog returns true
      },
    );

    if (confirmed == true) {
      try {
        provider.setLoadingOverlay(true);
        
        // Get required data for payload
        final userData = await _getUserData();
        final itemDetail = _getItemDetail(provider);
        final dataSpy = _getDataSpy();
        
        // Call API through CoreService
        final response = await CoreService.instance.deleteData(
          widget.moduleCode,
          _currentTabCode,
          userData,
          itemDetail,
          dataSpy,
        );
        
        if (mounted && response != null) {
          // Update data directly from delete response without additional API call
          if (response['success'] == true) {
            provider.updateDataAfterSave(response);
            // Reset change tracking after successful delete
            _resetChangeTracking();
          }
          
          CoreActionDialog.showResponseDialog(
            context,
            response: response,
            title: 'Delete Operation',
            onSuccess: () {
              // Call callback for successful delete operation
              if (widget.onOperationSuccess != null) {
                widget.onOperationSuccess!();
              }
              // Navigate back after successful delete
              Navigator.of(context).pop();
            },
          );
        } else if (mounted) {
          CoreActionDialog.showResponseDialog(
            context,
            response: {
              'success': false,
              'messageType': 'error',
              'message': 'Delete operation failed or session expired',
            },
            title: 'Delete Operation',
          );
        }
      } catch (e) {
        if (mounted) {
          // Safely handle error message to avoid type casting issues
          String errorMessage;
          try {
            errorMessage = 'Delete failed: ${e.toString()}';
          } catch (stringError) {
            errorMessage = 'Delete operation failed due to an unexpected error';
          }
          
          CoreActionDialog.showResponseDialog(
            context,
            response: {
              'success': false,
              'messageType': 'error',
              'message': errorMessage,
            },
            title: 'Delete Operation',
          );
        }
      } finally {
        provider.setLoadingOverlay(false);
      }
    }
  }

  PreferredSizeWidget? _buildTabsAreaInAppBar() {
    final tabs = widget.availableTabs;
    if (tabs.isEmpty || _tabController == null) return null;

    final hasDocSubTabs = widget.docSubTabs != null && (widget.docSubTabs!.isNotEmpty);

    return PreferredSize(
      preferredSize: Size.fromHeight(hasDocSubTabs && _currentTabCode.toUpperCase() == 'DOC' ? 105.0 : 60.0),
      child: Consumer<CoreDetailProvider>(
        builder: (context, provider, child) {
          final isNewRecord = _isNewRecord(provider);
          
          // Filter out hidden tabs and for new records, only show default tab (DTLS)
          List<TabConfig> visibleTabs;
          if (isNewRecord) {
            visibleTabs = tabs.where((tab) => 
              !provider.isTabHidden(tab.code) && 
              (tab.code.toUpperCase() == 'DTLS' || tab.isDefault == true)
            ).toList();
          } else {
            visibleTabs = tabs.where((tab) => !provider.isTabHidden(tab.code)).toList();
          }
          
          // Ensure TabController length matches the number of tabs we render
          if (_tabController != null && _tabController!.length != visibleTabs.length) {
            final int currentVisibleIndex = visibleTabs.indexWhere((t) => t.code == _currentTabCode);
            final int newIndex = currentVisibleIndex >= 0 ? currentVisibleIndex : 0;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _tabController!.dispose();
              setState(() {
                _tabController = TabController(
                  length: visibleTabs.length,
                  vsync: this,
                  initialIndex: newIndex.clamp(0, (visibleTabs.length - 1).clamp(0, visibleTabs.length - 1)),
                );
                _currentTabCode = visibleTabs.isNotEmpty ? visibleTabs.first.code : _currentTabCode;
              });
            });
            return const SizedBox.shrink();
          }
          
          if (visibleTabs.isEmpty) {
            return Container();
          }

          final bool shouldShowMoreTabs = _shouldShowTabMoreButton(visibleTabs);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white.withOpacity(0.78),
                        dividerColor: Colors.transparent,
                        labelStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.25,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                        labelPadding: const EdgeInsets.symmetric(horizontal: 2),
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.09),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicatorPadding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                        splashFactory: NoSplash.splashFactory,
                        overlayColor: MaterialStateProperty.all(Colors.transparent),
                        onTap: (index) async {
                          final selectedTab = visibleTabs[index];
                          final isTabDisabled = provider.isTabDisabled(selectedTab.code);
                          if (!isTabDisabled) {
                            await _changeTab(selectedTab.code);
                          }
                        },
                        tabs: visibleTabs.asMap().entries.map((entry) {
                          final index = entry.key;
                          final tab = entry.value;
                          final isTabDisabled = provider.isTabDisabled(tab.code);

                          return AnimatedBuilder(
                            animation: _tabController!,
                            builder: (context, child) {
                              final isSelected = _tabController!.index == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 170),
                                curve: Curves.easeOutCubic,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getTabIcon(tab.code),
                                      size: isSelected ? 17 : 16,
                                      color: isTabDisabled
                                          ? Colors.white.withOpacity(0.30)
                                          : isSelected
                                              ? Colors.blue.shade700
                                              : Colors.white.withOpacity(0.92),
                                    ),
                                    const SizedBox(width: 7),
                                    Text(
                                      tab.name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                        color: isTabDisabled
                                            ? Colors.white.withOpacity(0.30)
                                            : isSelected
                                                ? Colors.blue.shade700
                                                : Colors.white.withOpacity(0.92),
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                    ),
                    if (shouldShowMoreTabs) ...[
                      const SizedBox(width: 6),
                      _buildTabMoreButton(visibleTabs, provider),
                    ],
                  ],
                ),
              ),
              if (widget.docSubTabs != null && widget.docSubTabs!.isNotEmpty && _currentTabCode.toUpperCase() == 'DOC')
                _buildDocSubTabBar(context, provider, widget.docSubTabs!),
            ],
          );
        },
      ),
    );
  }

  bool _shouldShowTabMoreButton(List<TabConfig> visibleTabs) {
    if (visibleTabs.length >= 4) return true;
    return visibleTabs.any((tab) => tab.name.length > 12);
  }

  Widget _buildTabMoreButton(List<TabConfig> visibleTabs, CoreDetailProvider provider) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showTabQuickSwitcher(visibleTabs, provider),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          child: Icon(
            Icons.more_horiz_rounded,
            size: 20,
            color: Colors.white.withOpacity(0.95),
          ),
        ),
      ),
    );
  }

  Future<void> _showTabQuickSwitcher(List<TabConfig> visibleTabs, CoreDetailProvider provider) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.of(sheetContext).size.height * 0.68;
        return SafeArea(
          top: false,
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F8FF),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 2, 12, 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade700,
                          Colors.blue.shade500,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.dashboard_customize_rounded, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        const Text(
                          'All Tabs',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${visibleTabs.length} tabs',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.95),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 18),
                    shrinkWrap: true,
                    itemCount: visibleTabs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 9),
                    itemBuilder: (context, index) {
                      final tab = visibleTabs[index];
                      final bool isActive = tab.code == _currentTabCode;
                      final bool isDisabled = provider.isTabDisabled(tab.code);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: isDisabled
                              ? null
                              : () async {
                                  Navigator.of(sheetContext).pop();
                                  if (_tabController != null && index < _tabController!.length) {
                                    _tabController!.index = index;
                                  }
                                  await _changeTab(tab.code);
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFE8F2FF) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isActive ? Colors.blue.shade300 : Colors.grey.shade200,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isActive ? Colors.blue : Colors.black).withOpacity(isActive ? 0.10 : 0.04),
                                  blurRadius: isActive ? 10 : 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    gradient: isActive
                                        ? LinearGradient(
                                            colors: [
                                              Colors.blue.shade600,
                                              Colors.blue.shade400,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isActive ? null : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _getTabIcon(tab.code),
                                    size: 18,
                                    color: isDisabled
                                        ? Colors.grey.shade400
                                        : isActive
                                            ? Colors.white
                                            : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    tab.name,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                                      color: isDisabled
                                          ? Colors.grey.shade400
                                          : isActive
                                              ? Colors.blue.shade800
                                              : Colors.grey.shade900,
                                    ),
                                  ),
                                ),
                                if (isDisabled)
                                  Icon(Icons.lock_outline_rounded, size: 16, color: Colors.grey.shade400)
                                else
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.blue.shade600 : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Icon(
                                      isActive ? Icons.check_rounded : Icons.chevron_right_rounded,
                                      size: isActive ? 16 : 18,
                                      color: isActive ? Colors.white : Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Ensure doc sub-tab initialized (no longer needs to load data separately)

  Widget _buildDocSubTabBar(BuildContext context, CoreDetailProvider provider, List<TabDocConfig> subTabs) {
    // Ensure current selected exists
    if (_currentDocSubTabCode == null || !subTabs.any((t) => t.code == _currentDocSubTabCode)) {
      _currentDocSubTabCode = (subTabs.firstWhere(
        (t) => t.isDefault,
        orElse: () => subTabs.first,
      ).code);
    }

    final itemKeys = List.generate(subTabs.length, (_) => GlobalKey());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final selectedIndex = subTabs.indexWhere((t) => t.code == _currentDocSubTabCode);
      if (selectedIndex != -1 && itemKeys[selectedIndex].currentContext != null) {
        Scrollable.ensureVisible(
          itemKeys[selectedIndex].currentContext!,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutExpo,
          alignment: 0.5,
        );
      }
    });
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView.separated(
        controller: _docSubTabScrollController,
        scrollDirection: Axis.horizontal,
        itemCount: subTabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final t = subTabs[index];
          final bool selected = t.code == _currentDocSubTabCode;
          final isDisabled = false;
          final icon = Icons.insert_drive_file_rounded;
          return GestureDetector(
            key: itemKeys[index],
            onTap: isDisabled || selected
                ? null
                : () async {
                    setState(() {
                      _currentDocSubTabCode = t.code;
                    });
                    await provider.switchDocSubTab(t.code);
                    // Scroll to show selected (TabBar-like)
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (itemKeys[index].currentContext != null) {
                        Scrollable.ensureVisible(
                          itemKeys[index].currentContext!,
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutExpo,
                          alignment: 0.5,
                        );
                      }
                    });
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutExpo,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                        colors: [
                          Color(0xFF1E88E5), // blue 600
                          Color.fromARGB(255, 62, 149, 220), // blue 300
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.08),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: Color(0xFF1E88E5).withOpacity(0.13), // blue shadow
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
                border: Border.all(
                  color: selected ? Colors.white : Colors.white.withOpacity(0.22),
                  width: selected ? 2.2 : 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: selected ? 18 : 15,
                    color: selected ? Colors.white : Colors.white.withOpacity(0.8),
                  ),
                  const SizedBox(width: 3),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutExpo,
                    style: TextStyle(
                      fontSize: selected ? 14 : 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? Colors.white : Colors.white.withOpacity(0.85),
                      letterSpacing: 0.5,
                    ),
                    child: Text(t.name),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  // Helper method để lấy icon cho mỗi tab
  IconData _getTabIcon(String tabCode) {
    switch (tabCode.toUpperCase()) {
      case 'DTLS':
        return Icons.info_outline_rounded;
      case 'DETAIL':
        return Icons.insert_chart_outlined_rounded;
      case 'DOC':
        return Icons.insert_drive_file_rounded;
      case 'CMT':
        return Icons.comment_rounded;
      case 'QUERY':
        return Icons.search_rounded;
      case 'CONFIG':
        return Icons.settings_outlined;
      case 'TBPMS':
        return Icons.table_chart_outlined;
      case 'ATPMS':
        return Icons.security_rounded;
      case 'TABPMS':
        return Icons.admin_panel_settings_outlined;
      default:
        return Icons.tab_rounded;
    }
  }

  Widget _buildBody(CoreDetailProvider provider) {
    if (provider.loading) {
      // Avoid double loaders; rely on provider.showLoadingOverlay with unified overlay
      return const SizedBox.shrink();
    }

    return KeyboardUtils.withKeyboardDismissal(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: _createTabBody(
          _currentTabCode,
          moduleCode: widget.moduleCode,
          currentTabCode: _currentTabCode,
          itemId: provider.itemDetail?.value['id']?.toString(),
          initialData: provider.rawResponse, // Truyền toàn bộ raw response động
          onDataChanged: (updatedData) => _handleDataChanged(provider, updatedData),
        ),
      ),
    );
  }

  /// Create tab body using TabConfig.tabBodyBuilder or fallback to TabBodyRegistry
  Widget _createTabBody(String tabCode, {
    required String moduleCode,
    required String currentTabCode,
    String? itemId,
    Map<String, dynamic>? initialData,
    Function(Map<String, dynamic>)? onDataChanged,
  }) {
    // Find tab config with tabBodyBuilder
    final tabConfig = widget.availableTabs.firstWhere(
      (tab) => tab.code == currentTabCode,
      orElse: () => TabConfig(code: currentTabCode, name: currentTabCode),
    );

    // Use tabBodyBuilder if available
    if (tabConfig.tabBodyBuilder != null) {
      return tabConfig.tabBodyBuilder!(
        moduleCode: moduleCode,
        tabCode: currentTabCode,
        itemId: itemId,
        initialData: initialData,
        onDataChanged: onDataChanged,
      );
    }

    // Fallback to TabBodyRegistry if no tabBodyBuilder
    return TabBodyRegistry.createTabBody(
      moduleCode: moduleCode,
      tabCode: currentTabCode,
      itemId: itemId,
      initialData: initialData,
      onDataChanged: onDataChanged,
    ) ?? Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.extension_off,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Tab Not Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tab "$currentTabCode" is not implemented yet.',
              style: TextStyle(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Handle tab save action
  Future<void> _handleTabSave(CoreDetailProvider provider) async {
    try {
      provider.setLoadingOverlay(true);
      final userData = await _getUserData();
      final itemDetail = _getItemDetail(provider);
      final dataSpy = _getDataSpy();

      final response = await CoreService.instance.saveData(
        widget.moduleCode,
        _currentTabCode,
        userData,
        itemDetail,
        dataSpy,
      );

      if (mounted && response != null) {
        if (response['success'] == true) {
          provider.updateDataAfterSave(response);

          // Reset change tracking after successful save
          _resetChangeTracking();

          if (_isFromNewAction()) {
            try {
              final newItemDetail = response['itemDetail'];
              if (newItemDetail != null && newItemDetail is Map<String, dynamic>) {
                Map<String, dynamic>? valueData;
                if (newItemDetail.containsKey('value') && newItemDetail['value'] is Map<String, dynamic>) {
                  valueData = newItemDetail['value'] as Map<String, dynamic>;
                }
                if (valueData != null) {
                  widget.listItem.clear();
                  widget.listItem.addAll(valueData);
                  provider.updateListItem(widget.listItem);
                  widget.listItem.remove('action');
                }
              }
            } catch (_) {}
          }
        }

        CoreActionDialog.showResponseDialog(
          context,
          response: response,
          title: 'Save Operation',
          onSuccess: () {
            if (_shouldRefreshListOnSave() && widget.onOperationSuccess != null) {
              widget.onOperationSuccess!();
              provider.clearCachedAction();
            }
          },
        );
      } else if (mounted) {
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': 'Save operation failed or session expired',
          },
          title: 'Save Operation',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        try {
          errorMessage = 'Save failed: ${e.toString()}';
        } catch (_) {
          errorMessage = 'Save operation failed due to an unexpected error';
        }
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': errorMessage,
          },
          title: 'Save Operation',
        );
      }
    } finally {
      provider.setLoadingOverlay(false);
    }
  }

  /// Handle tab submit action
  Future<void> _handleTabSubmit(CoreDetailProvider provider) async {
    try {
      provider.setLoadingOverlay(true);
      
      // Get required data for payload
      final userData = await _getUserData();
      final itemDetail = _getItemDetail(provider);
      final dataSpy = _getDataSpy();
      
      // Call API through CoreService
      final response = await CoreService.instance.submitData(
        widget.moduleCode,
        _currentTabCode,
        userData,
        itemDetail,
        dataSpy,
      );
      
      if (mounted && response != null) {
        // Update data directly from submit response without additional API call
        if (response['success'] == true) {
          provider.updateDataAfterSave(response);
          // Reset change tracking after successful submit
          _resetChangeTracking();
        }
        
        CoreActionDialog.showResponseDialog(
          context,
          response: response,
          title: 'Submit Operation',
        );
      } else if (mounted) {
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': 'Submit operation failed or session expired',
          },
          title: 'Submit Operation',
        );
      }
    } catch (e) {
      if (mounted) {
        // Safely handle error message to avoid type casting issues
        String errorMessage;
        try {
          errorMessage = 'Submit failed: ${e.toString()}';
        } catch (_) {
          errorMessage = 'Submit operation failed due to an unexpected error';
        }
        
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': errorMessage,
          },
          title: 'Submit Operation',
        );
      }
    } finally {
      provider.setLoadingOverlay(false);
    }
  }

  /// Handle tab refresh action
  Future<void> _handleTabRefresh(CoreDetailProvider provider) async {
    try {
      provider.setLoadingOverlay(true);
      
      // Re-fetch data for current tab
      await provider.fetchDetailData(onSessionExpired: _handleSessionExpired, forceRefresh: false);
      
      // Reset change tracking after refresh
      _resetChangeTracking();
      
      if (mounted) {
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': true,
            'messageType': 'success',
            'message': 'Data refreshed successfully',
          },
          title: 'Refresh',
        );
      }
    } catch (e) {
      if (mounted) {
        // Safely handle error message to avoid type casting issues
        String errorMessage;
        try {
          errorMessage = 'Refresh failed: ${e.toString()}';
        } catch (_) {
          errorMessage = 'Refresh operation failed due to an unexpected error';
        }
        
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': errorMessage,
          },
          title: 'Refresh',
        );
      }
    } finally {
      provider.setLoadingOverlay(false);
    }
  }

  /// Helper method to get user data from session
  Future<Map<String, dynamic>> _getUserData() async {
    final authService = AuthService();
    final userInfo = await authService.getSavedUserInfo();
    return userInfo?.toJson() ?? {};
  }

  /// Helper method to get dataSpy (passed from list screen or default)
  Map<String, dynamic> _getDataSpy() {
    return widget.dataSpy ?? {};
  }

  /// Helper method to get itemDetail with proper structure
  Map<String, dynamic> _getItemDetail(CoreDetailProvider provider) {
    final rawResponse = provider.rawResponse ?? {};
    if (rawResponse.containsKey('itemDetail')) {
      final itemDetail = rawResponse['itemDetail'];
      if (itemDetail is Map<String, dynamic>) {
        if (itemDetail.containsKey('itemDetail')) {
          final nested = itemDetail['itemDetail'] as Map<String, dynamic>? ?? {};
          return nested;
        }
      }
      return itemDetail as Map<String, dynamic>? ?? {};
    }
    return rawResponse;
  }

  /// Build task approval footer for screens opened from task list
  Widget? _buildTaskFooter(CoreDetailProvider provider) {
    // Get button labels and visibility from API response
    final response = provider.rawResponse ?? {};
    final itemDetail = response['itemDetail'] ?? {};
    final itemValue = itemDetail['value'] ?? {};
    final statusData = itemValue['status'] ?? {};
    
    final rejectLabel = statusData['rejectButtonLabel']?.toString() ?? 'Reject';
    final approveLabel = statusData['approveButtonLabel']?.toString() ?? 'Approve';
    final isRejectHidden = statusData['isRejectHidden'] == true;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 7),
          child: Row(
            children: [
              // Reject Button (conditionally visible)
              if (!isRejectHidden) ...[
                Expanded(
                  child: _buildTaskButton(
                    label: rejectLabel,
                    onPressed: () => _handleRejectTask(provider),
                    backgroundColor: const Color(0xFFE53E3E),
                    foregroundColor: Colors.white,
                    icon: Icons.close_rounded,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              // Approve Button
              Expanded(
                child: _buildTaskButton(
                  label: approveLabel,
                  onPressed: () => _handleApproveTask(provider),
                  backgroundColor: const Color(0xFF38A169),
                  foregroundColor: Colors.white,
                  icon: Icons.check_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual task action button with professional design and touch animation
  Widget _buildTaskButton({
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    required IconData icon,
  }) {
    return TouchableOpacity(
      onTap: onPressed,
      opacity: 0.4, // Touch animation opacity
      duration: const Duration(milliseconds: 100),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(7),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: foregroundColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: foregroundColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle reject task action
  Future<void> _handleRejectTask(CoreDetailProvider provider) async {
    // Ensure we have a task ID
    if (widget.taskId == null || widget.taskId!.isEmpty) {
      CoreActionDialog.showResponseDialog(
        context,
        response: {
          'success': false,
          'messageType': 'error',
          'message': 'Task ID is not available for this operation',
        },
        title: 'Reject Task',
      );
      return;
    }

    try {
      provider.setLoadingOverlay(true);
      
      // Get required data for payload
      final userData = await _getUserData();
      final itemDetail = _getItemDetail(provider);
      final dataSpy = _getDataSpy();
      
      // Call API with reject action (always use DTLS tab for task actions)
      final response = await CoreService.instance.performTaskAction(
        widget.moduleCode,
        'DTLS', // Always use DTLS tab for task actions
        userData,
        itemDetail,
        dataSpy,
        widget.taskId!,
        false, // isApproved = false for reject
      );
      
      if (mounted && response != null) {
        // Update data directly from response if successful
        if (response['success'] == true) {
          provider.updateDataAfterSave(response);
        }
        
        CoreActionDialog.showResponseDialog(
          context,
          response: response,
          title: 'Reject Task',
          onSuccess: () {
            // Navigate back to task list after successful rejection
            Navigator.of(context).pop();
          },
        );
      } else if (mounted) {
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': 'Reject operation failed or session expired',
          },
          title: 'Reject Task',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        try {
          errorMessage = 'Reject failed: ${e.toString()}';
        } catch (_) {
          errorMessage = 'Reject operation failed due to an unexpected error';
        }
        
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': errorMessage,
          },
          title: 'Reject Task',
        );
      }
    } finally {
      provider.setLoadingOverlay(false);
    }
  }

  /// Handle approve task action  
  Future<void> _handleApproveTask(CoreDetailProvider provider) async {
    // Ensure we have a task ID
    if (widget.taskId == null || widget.taskId!.isEmpty) {
      CoreActionDialog.showResponseDialog(
        context,
        response: {
          'success': false,
          'messageType': 'error',
          'message': 'Task ID is not available for this operation',
        },
        title: 'Approve Task',
      );
      return;
    }

    try {
      provider.setLoadingOverlay(true);
      
      // Get required data for payload
      final userData = await _getUserData();
      final itemDetail = _getItemDetail(provider);
      final dataSpy = _getDataSpy();
      
      // Call API with approve action (always use DTLS tab for task actions)
      final response = await CoreService.instance.performTaskAction(
        widget.moduleCode,
        'DTLS', // Always use DTLS tab for task actions
        userData,
        itemDetail,
        dataSpy,
        widget.taskId!,
        true, // isApproved = true for approve
      );
      
      if (mounted && response != null) {
        // Update data directly from response if successful
        if (response['success'] == true) {
          provider.updateDataAfterSave(response);
        }
        
        CoreActionDialog.showResponseDialog(
          context,
          response: response,
          title: 'Approve Task',
          onSuccess: () {
            // Navigate back to task list after successful approval
            Navigator.of(context).pop();
          },
        );
      } else if (mounted) {
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': 'Approve operation failed or session expired',
          },
          title: 'Approve Task',
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage;
        try {
          errorMessage = 'Approve failed: ${e.toString()}';
        } catch (_) {
          errorMessage = 'Approve operation failed due to an unexpected error';
        }
        
        CoreActionDialog.showResponseDialog(
          context,
          response: {
            'success': false,
            'messageType': 'error',
            'message': errorMessage,
          },
          title: 'Approve Task',
        );
      }
    } finally {
      provider.setLoadingOverlay(false);
    }
  }
}

/// Custom discard changes dialog widget with beautiful design
class _DiscardChangesDialog extends StatefulWidget {
  const _DiscardChangesDialog();

  @override
  State<_DiscardChangesDialog> createState() => _DiscardChangesDialogState();
}

class _DiscardChangesDialogState extends State<_DiscardChangesDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Colors.orange.shade600;
    final backgroundColor = Colors.orange.shade50;
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with gradient background
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            backgroundColor,
                            backgroundColor.withOpacity(0.5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                      ),
                      child: Column(
                        children: [
                          // Icon with animation
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Title
                          const Text(
                            'Discard Changes?',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxHeight: MediaQuery.of(context).size.height * 0.6,
                            ),
                            child: const SingleChildScrollView(
                              child: Text(
                                'You have unsaved changes. Are you sure you want to discard them? This action cannot be undone.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Action buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.grey.shade600,
                                    side: BorderSide(color: Colors.grey.shade400),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    'Discard',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom swipe back handler widget
class _SwipeBackHandler extends StatefulWidget {
  final Widget child;
  final Future<bool> Function() onSwipeBack;

  const _SwipeBackHandler({
    required this.child,
    required this.onSwipeBack,
  });

  @override
  State<_SwipeBackHandler> createState() => _SwipeBackHandlerState();
}

class _SwipeBackHandlerState extends State<_SwipeBackHandler> {
  double _startX = 0.0;
  double _currentX = 0.0;
  bool _isSwiping = false;
  static const double _swipeThreshold = 100.0; // Minimum distance to trigger swipe back

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (details) {
        _startX = details.globalPosition.dx;
        _currentX = _startX;
        _isSwiping = false;
      },
      onHorizontalDragUpdate: (details) {
        _currentX = details.globalPosition.dx;
        final deltaX = _currentX - _startX;
        
        // Only detect right-to-left swipe (swipe back gesture)
        if (deltaX > 0 && deltaX > _swipeThreshold && !_isSwiping) {
          _isSwiping = true;
          _handleSwipeBack();
        }
      },
      onHorizontalDragEnd: (details) {
        _isSwiping = false;
      },
      child: widget.child,
    );
  }

  Future<void> _handleSwipeBack() async {
    final shouldAllow = await widget.onSwipeBack();
    if (shouldAllow && mounted) {
      // Allow swipe back by calling Navigator.pop
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    }
    // If not allowing, stay on current screen
  }
}
