part of 'list_core_screen.dart';

extension _ListCoreScreenActionsExt on _ListCoreScreenState {
  void _navigateToNewRecord(CoreListProvider provider) {
    // Dismiss keyboard before navigation
    _dismissKeyboard();

    // Create a new item structure for the NEW action
    final Map<String, dynamic> newItem = {
      'id': null, // No ID for new records
      'code': null, // Will be auto-generated
      'action': 'NEW', // Special flag to indicate this is a new record
    };

    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) {
              // Use custom detail screen if provided, otherwise use default
              final customScreen = widget.detailScreenBuilder?.call(
                context,
                newItem,
              );
              if (customScreen != null) {
                return customScreen;
              }

              return GenericDetailCoreScreen(
                moduleCode: widget.moduleCode,
                moduleName: provider.displayModuleName,
                listItem: newItem,
                initialTabCode:
                    'DTLS', // Always default to DTLS for new records
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
        )
        .then((_) async {
          // Refresh the list when returning from detail screen, keep scroll
          await _refreshListKeepingScroll(provider);
        });
  }

  Future<void> _handleSwipeDelete(
    CoreListProvider provider,
    Map<String, dynamic> item,
    int index,
  ) async {
    // Show confirmation dialog
    final confirmed = await CustomConfirmDialog.showDelete(
      context,
      title: 'Confirm Delete',
      message:
          'Are you sure you want to delete this item? This action cannot be undone.',
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
