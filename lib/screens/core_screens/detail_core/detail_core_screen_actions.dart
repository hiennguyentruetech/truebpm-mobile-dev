part of 'detail_core_screen.dart';

extension _DetailCoreScreenActionsExt on _DetailCoreScreenState {
  List<Widget> _buildAppBarActions(CoreDetailProvider provider) {
    List<Widget> actions = [];
    final isNew = isNewRecord(provider);

    // Quick Save Action - check if save is hidden or disabled
    if (provider.isToolbarVisible(ToolbarAction.save)) {
      final isSaveDisabled =
          !provider.isToolbarEnabled(ToolbarAction.save) ||
          provider.showLoadingOverlay;
      actions.add(
        IconButton(
          onPressed: isSaveDisabled ? null : () => _handleTabSave(provider),
          icon: Icon(
            Icons.save_outlined,
            size: 22,
            color: isSaveDisabled
                ? Colors.white.withOpacity(0.5)
                : Colors.white,
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
    if (provider.isToolbarVisible(ToolbarAction.submit) &&
        !widget.fromTaskScreen) {
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
    if (provider.isToolbarVisible(ToolbarAction.copy) &&
        !isNew &&
        !widget.fromTaskScreen) {
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
    if (provider.isToolbarVisible(ToolbarAction.print) && !isNew) {
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
    if (provider.isToolbarVisible(ToolbarAction.cancel) &&
        !isNew &&
        !widget.fromTaskScreen) {
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
    if (provider.isToolbarVisible(ToolbarAction.delete) &&
        !isNew &&
        !widget.fromTaskScreen &&
        menuItems.isNotEmpty) {
      menuItems.add(const PopupMenuDivider(height: 10));
    }

    // Delete action - disabled for new records and hidden when from task screen
    if (provider.isToolbarVisible(ToolbarAction.delete) &&
        !isNew &&
        !widget.fromTaskScreen) {
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
              border: Border.all(color: Colors.white.withOpacity(0), width: 1),
            ),
            child: Icon(
              Icons.more_vert_rounded,
              size: 20,
              color: Colors.white.withOpacity(
                provider.showLoadingOverlay ? 0.55 : 1,
              ),
            ),
          ),
          padding: const EdgeInsets.only(left: 4, right: 6),
          tooltip: 'More actions',
          color: Colors.white,
          elevation: 14,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
            side: BorderSide(color: Colors.blueGrey.withOpacity(0.12)),
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
            child: Icon(icon, size: 17, color: iconColor),
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
        defaultTabCode = tabs
            .firstWhere((t) => t.code.toUpperCase() == 'DTLS')
            .code;
      } else if (tabs.isNotEmpty) {
        defaultTabCode = tabs.first.code;
      }

      if (_currentTabCode != defaultTabCode) {
        // Update local state and TabController index to match default tab
        final newIndex = tabs.indexWhere((t) => t.code == defaultTabCode);
        if (newIndex >= 0 &&
            _tabController != null &&
            newIndex < _tabController!.length) {
          _tabController!.index = newIndex;
        }
        _safeSetState(() {
          _currentTabCode = defaultTabCode;
        });
        await _provider.switchTab(
          defaultTabCode,
          onSessionExpired: handleSessionExpired,
        );
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
          resetChangeTracking();
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
            resetChangeTracking();
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
      message:
          'Are you sure you want to delete this item? This action cannot be undone.',
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
            resetChangeTracking();
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
          resetChangeTracking();

          if (isFromNewAction()) {
            try {
              final newItemDetail = response['itemDetail'];
              if (newItemDetail != null &&
                  newItemDetail is Map<String, dynamic>) {
                Map<String, dynamic>? valueData;
                if (newItemDetail.containsKey('value') &&
                    newItemDetail['value'] is Map<String, dynamic>) {
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
            if (shouldRefreshListOnSave() &&
                widget.onOperationSuccess != null) {
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
          resetChangeTracking();
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
      await provider.fetchDetailData(
        onSessionExpired: handleSessionExpired,
        forceRefresh: false,
      );

      // Reset change tracking after refresh
      resetChangeTracking();

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
          final nested =
              itemDetail['itemDetail'] as Map<String, dynamic>? ?? {};
          return nested;
        }
      }
      return itemDetail as Map<String, dynamic>? ?? {};
    }
    return rawResponse;
  }
}
