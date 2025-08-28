import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/providers/core_list_provider.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/utils/core_constants.dart';
import 'package:truebpm/utils/session_handler.dart';
import 'package:truebpm/widgets/core/core_app_bar.dart';
import 'package:truebpm/widgets/core/core_empty_state.dart';
import 'package:truebpm/widgets/core/core_list_item_card.dart';
import 'package:truebpm/widgets/global_widgets.dart';
import 'package:truebpm/widgets/common/floating_add_button.dart';

class ListCoreScreen extends StatefulWidget {
  final String moduleCode;
  final String? moduleName;
  final String? tabModuleCode;
  final List<TabConfig>? availableTabs;
  final Widget? Function(BuildContext context, Map<String, dynamic> listItem)? detailScreenBuilder;
  final List<PrintReportOption>? printReports;

  const ListCoreScreen({
    super.key,
    required this.moduleCode,
    this.moduleName,
    this.tabModuleCode,
    this.availableTabs,
    this.detailScreenBuilder,
    this.printReports,
  });

  @override
  State<ListCoreScreen> createState() => _ListCoreScreenState();
}

class _ListCoreScreenState extends State<ListCoreScreen> with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late CoreListProvider _provider;
  AnimationController? _fabAnimationController;
  Animation<double>? _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _provider = CoreListProvider();
    _provider.initialize(
      widget.moduleCode,
      widget.moduleName,
      onSessionExpired: _handleSessionExpired,
    );
    _scrollController.addListener(_onScroll);

    // Initialize FAB animation
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _provider.dispose();
    _fabAnimationController?.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - CoreConstants.scrollThreshold) {
      _provider.loadMoreData(widget.moduleCode, widget.tabModuleCode);
    }
  }

  Future<void> _handleSessionExpired() async {
    // Show session expired dialog and handle re-login
    final success = await SessionHandler.handleSessionExpired(context);
    if (success && mounted) {
      // If auto-login successful, retry fetching data
      await _provider.fetchData(widget.moduleCode);
    }
  }

  Future<void> _refreshListKeepingScroll(CoreListProvider provider) async {
    final double savedOffset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    await provider.refreshData(widget.moduleCode, widget.tabModuleCode);
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final max = _scrollController.position.maxScrollExtent;
      final target = savedOffset.clamp(0.0, max);
      try {
        _scrollController.jumpTo(target);
      } catch (_) {}
    });
  }

  void _navigateToNewRecord(CoreListProvider provider) {
    // Create a new item structure for the NEW action
    final Map<String, dynamic> newItem = {
      'id': null, // No ID for new records
      'code': null, // Will be auto-generated
      'action': 'NEW', // Special flag to indicate this is a new record
    };

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          // Use custom detail screen if provided, otherwise use default
          final customScreen = widget.detailScreenBuilder?.call(context, newItem);
          if (customScreen != null) {
            return customScreen;
          }

          return GenericDetailCoreScreen(
            moduleCode: widget.moduleCode,
            moduleName: provider.displayModuleName,
            listItem: newItem,
            initialTabCode: 'DTLS', // Always default to DTLS for new records
            dataSpy: provider.dataSpy,
            availableTabs: widget.availableTabs ?? _getDefaultTabs(),
            printReports: widget.printReports ?? _getExamplePrintReports(),
            onOperationSuccess: () async {
              // Refresh data spy and keep scroll position after successful save
              await _refreshListKeepingScroll(provider);
            },
          );
        },
      ),
    ).then((_) async {
      // Refresh the list when returning from detail screen, keep scroll
      await _refreshListKeepingScroll(provider);
    });
  }

  Future<void> _handleSwipeDelete(CoreListProvider provider, Map<String, dynamic> item, int index) async {
    // Show confirmation dialog
    final confirmed = await CustomConfirmDialog.showDelete(
      context,
      title: 'Confirm Delete',
      message: 'Are you sure you want to delete this item? This action cannot be undone.',
      onConfirm: () {},
    );

    if (confirmed == true) {
      try {
        // Note: We'll use existing loading mechanism instead of setLoadingOverlay

        // Get required data for payload
        final userData = await _getUserData();
        final dataSpy = provider.dataSpy ?? {};

        // Call API through CoreService - deleteItemFromList uses listItem directly
        final response = await CoreService.instance.deleteItemFromList(
          widget.moduleCode,
          userData,
          item, // Direct list item
          dataSpy,
        );

        if (mounted && response != null) {
          if (response['success'] == true) {
            // Force refresh and keep scroll to ensure item is removed but position stays
            await _refreshListKeepingScroll(provider);

            if (mounted) {
              CoreActionDialog.showResponseDialog(
                context,
                response: {
                  'success': true,
                  'messageType': 'success',
                  'message': 'Item deleted successfully',
                },
                title: 'Delete Operation',
              );
            }
          } else {
            CoreActionDialog.showResponseDialog(
              context,
              response: response,
              title: 'Delete Operation',
            );
          }
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
      }
    }
  }

  /// Helper method to get user data from session
  Future<Map<String, dynamic>> _getUserData() async {
    final authService = AuthService();
    final userInfo = await authService.getSavedUserInfo();
    return userInfo?.toJson() ?? {};
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
        onSuccess: () {},
      );
      // Pop after a tiny delay to ensure dialog shows first
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
    });
  }

  // Map status code to style
  ListItemStatusStyle? _buildStatusStyle(Map<String, dynamic> item) {
    try {
      final status = (item['status'] ?? {}) as Map<String, dynamic>;
      final statusType = (status['statusType'] ?? {}) as Map<String, dynamic>;
      final code = (statusType['code']?.toString() ?? '').toLowerCase();
      if (code.isEmpty) return null;

      Color color;
      String label;
      switch (code) {
        case 'pending':
          color = Colors.blue;
          label = 'Pending';
          break;
        case 'completed':
          color = Colors.green;
          label = 'Completed';
          break;
        case 'rejected':
          color = Colors.red;
          label = 'Rejected';
          break;
        case 'canceled':
        case 'cancelled':
          color = Colors.blueGrey.shade800;
          label = 'Canceled';
          break;
        case 'progress':
        case 'inprogress':
        case 'in-progress':
          color = Colors.orange;
          label = 'In Progress';
          break;
        default:
          // Fallback: use status name if available
          color = Colors.indigo;
          label = (status['name']?.toString().trim().isNotEmpty == true)
              ? status['name'].toString()
              : code[0].toUpperCase() + code.substring(1);
      }
      return ListItemStatusStyle(
        color: color,
        backgroundColor: color.withOpacity(0.10),
        borderColor: color.withOpacity(0.35),
        label: label,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CoreListProvider>.value(
      value: _provider,
      child: Consumer<CoreListProvider>(
        builder: (context, provider, child) {
          // Handle generic server/network error: show message and go back
          if (provider.lastErrorStatusCode != null && (provider.lastErrorStatusCode! >= 500 || provider.lastErrorStatusCode == 0)) {
            final msg = provider.lastErrorMessage ?? 'Connection error. Please try again later.';
            // Clear to avoid repeat
            provider.clearLastError();
            _showGenericErrorAndBack(msg);
          }

          return Stack(
            children: [
              Scaffold(
                appBar: CoreAppBar(
                  title: provider.displayModuleName ?? 'List Core Menu',
                  isSearchVisible: provider.isSearchVisible,
                  onSearchToggle: () {
                    provider.toggleSearch();
                    if (!provider.isSearchVisible) {
                      _searchController.clear();
                      if (provider.currentFilterInput.isNotEmpty) {
                        provider.performSearch(widget.moduleCode, widget.tabModuleCode, "");
                      }
                    }
                  },
                  dataSpies: provider.dataSpies,
                  selectedDataSpyId: provider.selectedId,
                  onDataSpyChanged: (val) {
                    provider.selectDataSpy(val, widget.moduleCode, widget.tabModuleCode);
                  },
                  searchController: _searchController,
                  onSearch: () {
                    provider.performSearch(
                      widget.moduleCode,
                      widget.tabModuleCode,
                      _searchController.text
                    );
                  },
                  moduleCode: widget.moduleCode,
                ),
                body: _buildBody(provider),
                floatingActionButton: provider.shouldShowNewButton
                    ? AnimatedBuilder(
                        animation: _fabScaleAnimation ?? Listenable.merge([]),
                        builder: (context, child) {
                          final isEnabled = provider.isNewButtonEnabled;
                          return Transform.scale(
                            scale: _fabScaleAnimation?.value ?? 1.0,
                            child: FloatingAddButton(
                              onPressed: isEnabled
                                  ? () {
                                      _fabAnimationController?.forward().then((_) => _fabAnimationController?.reverse());
                                      _navigateToNewRecord(provider);
                                    }
                                  : () {},
                            ),
                          );
                        },
                      )
                    : null,
                floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
              ),

              // Loading Overlay (unified with detail screen)
              if (provider.showLoadingOverlay)
                const LoadingOverlayWidget(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(CoreListProvider provider) {
    // Removed in-list loading indicator; rely on loading overlay instead.
    if (provider.dataSpies == null) {
      return const Center(child: Text('No data available'));
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
      child: _buildDataList(provider),
    );
  }

  Widget _buildDataList(CoreListProvider provider) {
    if (provider.listData.isEmpty) {
      return CoreEmptyState(
        onRefresh: () => provider.refreshData(widget.moduleCode, widget.tabModuleCode),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: RefreshIndicator(
        onRefresh: () => _refreshListKeepingScroll(provider),
        color: Colors.blue,
        backgroundColor: Colors.white,
        displacement: 40,
        strokeWidth: 3,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: provider.listData.length,
          itemBuilder: (context, index) {
            final item = provider.listData[index] as Map<String, dynamic>;
            final statusStyle = _buildStatusStyle(item);
            return Dismissible(
              key: Key('item_${item['id'] ?? index}'),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.red.shade400.withOpacity(0.1),
                      Colors.red.shade500.withOpacity(0.8),
                      Colors.red.shade600,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              confirmDismiss: (direction) async {
                // Show confirmation and handle delete
                await _handleSwipeDelete(provider, item, index);
                return false; // Don't auto-dismiss, we handle it manually
              },
              child: CoreListItemCard(
                item: item,
                index: index + 1,
                headers: provider.headers,
                contents: provider.contents,
                statusStyle: statusStyle,
                onTap: () {
                  // Navigate to detail screen
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        // Use custom detail screen if provided, otherwise use default
                        final customScreen = widget.detailScreenBuilder?.call(context, item);
                        if (customScreen != null) {
                          return customScreen;
                        }

                        return GenericDetailCoreScreen(
                          moduleCode: widget.moduleCode,
                          moduleName: provider.displayModuleName,
                          listItem: item,
                          initialTabCode: widget.tabModuleCode ?? 'DTLS',
                          dataSpy: provider.dataSpy,
                          availableTabs: widget.availableTabs ?? _getDefaultTabs(),
                          printReports: widget.printReports ?? _getExamplePrintReports(),
                          onOperationSuccess: () async {
                            // Refresh list and keep scroll for copy/delete, etc.
                            await _refreshListKeepingScroll(provider);
                          },
                        );
                      },
                    ),
                  ).then((_) async {
                    await _refreshListKeepingScroll(provider);
                  });
                },
              ),
            );
          },
        ),
      ),
    );
  }

  List<TabConfig> _getDefaultTabs() {
    return [
      TabConfig(code: 'DTLS', name: 'Details', isDefault: true),
      TabConfig(code: 'CMT', name: 'Comments'),
      TabConfig(code: 'DOC', name: 'Documents'),
    ];
  }

  List<PrintReportOption> _getExamplePrintReports() {
    return [
      const PrintReportOption(
        reportName: 'Báo cáo tổng hợp',
        reportUrl: 'https://example.com/report/summary',
      ),
      const PrintReportOption(
        reportName: 'Báo cáo chi tiết',
        reportUrl: 'https://example.com/report/detail',
      ),
    ];
  }
}
