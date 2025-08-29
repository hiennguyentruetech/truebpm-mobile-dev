import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/models/tab_doc_config.dart';
import 'package:truebpm/providers/core_detail_provider.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/utils/session_handler.dart';
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
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _provider.dispose();
    super.dispose();
  }

  void _handleSessionExpired() {
    SessionHandler.handleSessionExpired(context);
  }

  void _changeTab(String tabCode) {
    setState(() {
      _currentTabCode = tabCode;
    });
    
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
          return Scaffold(
            appBar: _buildAppBar(provider),
            body: Stack(
              children: [
                _buildBody(provider),
                if (provider.showLoadingOverlay) const LoadingOverlayWidget(),
              ],
            ),
            bottomNavigationBar: widget.fromTaskScreen ? _buildTaskFooter(provider) : null,
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
        PopupMenuItem(
          value: 'submit',
          enabled: !isSubmitDisabled,
          child: Row(
            children: [
              Icon(
                Icons.send_outlined, 
                size: 20, 
                color: isSubmitDisabled 
                  ? Colors.grey.shade400 
                  : Colors.green.shade600,
              ),
              const SizedBox(width: 12),
              Text(
                'Submit', 
                style: TextStyle(
                  fontSize: 14,
                  color: isSubmitDisabled ? Colors.grey.shade400 : null,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Refresh action (không có trong toolbar config, luôn hiển thị)
    menuItems.add(
      PopupMenuItem(
        value: 'refresh',
        child: Row(
          children: [
            Icon(Icons.refresh_outlined, size: 20, color: Colors.blue.shade600),
            const SizedBox(width: 12),
            const Text('Refresh', style: TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
    
    // Copy action - disabled for new records and hidden when from task screen
    if (provider.isToolbarVisible(ToolbarAction.copy) && !isNewRecord && !widget.fromTaskScreen) {
      final isCopyDisabled = !provider.isToolbarEnabled(ToolbarAction.copy);
      menuItems.add(
        PopupMenuItem(
          value: 'copy',
          enabled: !isCopyDisabled,
          child: Row(
            children: [
              Icon(
                Icons.copy_outlined, 
                size: 20, 
                color: isCopyDisabled 
                  ? Colors.grey.shade400 
                  : Colors.purple.shade600,
              ),
              const SizedBox(width: 12),
              Text(
                'Copy', 
                style: TextStyle(
                  fontSize: 14,
                  color: isCopyDisabled ? Colors.grey.shade400 : null,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Print action - disabled for new records
    if (provider.isToolbarVisible(ToolbarAction.print) && !isNewRecord) {
      final isPrintDisabled = !provider.isToolbarEnabled(ToolbarAction.print);
      menuItems.add(
        PopupMenuItem(
          value: 'print',
          enabled: !isPrintDisabled,
          child: Row(
            children: [
              Icon(
                Icons.print_outlined, 
                size: 20, 
                color: isPrintDisabled 
                  ? Colors.grey.shade400 
                  : Colors.teal.shade600,
              ),
              const SizedBox(width: 12),
              Text(
                'Print', 
                style: TextStyle(
                  fontSize: 14,
                  color: isPrintDisabled ? Colors.grey.shade400 : null,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Cancel action - disabled for new records and hidden when from task screen
    if (provider.isToolbarVisible(ToolbarAction.cancel) && !isNewRecord && !widget.fromTaskScreen) {
      final isCancelDisabled = !provider.isToolbarEnabled(ToolbarAction.cancel);
      menuItems.add(
        PopupMenuItem(
          value: 'cancel',
          enabled: !isCancelDisabled,
          child: Row(
            children: [
              Icon(
                Icons.cancel_outlined, 
                size: 20, 
                color: isCancelDisabled 
                  ? Colors.grey.shade400 
                  : Colors.orange.shade600,
              ),
              const SizedBox(width: 12),
              Text(
                'Cancel', 
                style: TextStyle(
                  fontSize: 14,
                  color: isCancelDisabled ? Colors.grey.shade400 : null,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // Add divider if we have delete action
    if (provider.isToolbarVisible(ToolbarAction.delete) && !isNewRecord && !widget.fromTaskScreen && menuItems.isNotEmpty) {
      menuItems.add(const PopupMenuDivider());
    }
    
    // Delete action - disabled for new records and hidden when from task screen
    if (provider.isToolbarVisible(ToolbarAction.delete) && !isNewRecord && !widget.fromTaskScreen) {
      final isDeleteDisabled = !provider.isToolbarEnabled(ToolbarAction.delete);
      menuItems.add(
        PopupMenuItem(
          value: 'delete',
          enabled: !isDeleteDisabled,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline, 
                size: 20, 
                color: isDeleteDisabled 
                  ? Colors.grey.shade400 
                  : Colors.red.shade600,
              ),
              const SizedBox(width: 12),
              Text(
                'Delete', 
                style: TextStyle(
                  fontSize: 14,
                  color: isDeleteDisabled ? Colors.grey.shade400 : null,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Only show popup menu if there are menu items
    if (menuItems.isNotEmpty) {
      actions.add(
        PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, provider),
          enabled: !provider.showLoadingOverlay,
          icon: const Icon(Icons.more_vert, size: 22, color: Colors.white),
          color: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          offset: const Offset(0, 45),
          itemBuilder: (context) => menuItems,
        ),
      );
    }
    
    return actions;
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
            final int newIndex = 0; // Always reset to first when structure changes
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

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.7),
              dividerColor: Colors.transparent,
              labelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              splashFactory: NoSplash.splashFactory,
              overlayColor: MaterialStateProperty.all(Colors.transparent),
              onTap: (index) {
                final selectedTab = visibleTabs[index];
                final isTabDisabled = provider.isTabDisabled(selectedTab.code);
                if (!isTabDisabled) {
                  _changeTab(selectedTab.code);
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
                      duration: const Duration(milliseconds: 150),
                      curve: Curves.fastOutSlowIn,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Icon với animation
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOutCubic,
                            child: Icon(
                              _getTabIcon(tab.code),
                              size: isSelected ? 18 : 16,
                              color: isTabDisabled 
                                ? Colors.white.withOpacity(0.3)
                                : isSelected 
                                  ? Colors.blue.shade600 
                                  : Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Text
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOutCubic,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w500 : FontWeight.w600,
                              color: isTabDisabled 
                                ? Colors.white.withOpacity(0.3)
                                : isSelected 
                                  ? Colors.blue.shade600 
                                  : Colors.white.withOpacity(0.9),
                              letterSpacing: 0.5,
                            ),
                            child: Text(tab.name),
                          ),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
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


    return Container(
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

  void _handleDataChanged(CoreDetailProvider provider, Map<String, dynamic> updatedData) {
    provider.updateRawResponse(updatedData);
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
