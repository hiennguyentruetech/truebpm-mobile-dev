part of 'detail_core_screen.dart';

/// Extension for navigation and back button handling
extension _DetailCoreScreenNavigationExt on _DetailCoreScreenState {
  /// Show discard changes confirmation dialog
  Future<bool> showDiscardChangesDialog() async {
    if (!_hasUnsavedChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DiscardChangesDialog(),
    );

    return result ?? false;
  }

  /// Override back button behavior to check for unsaved changes
  Future<bool> onWillPop() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await showDiscardChangesDialog();
      if (shouldDiscard) {
        return true; // Allow back navigation
      } else {
        return false; // Prevent back navigation
      }
    }
    return true; // Allow back navigation if no changes
  }

  /// Handle swipe back gesture with custom behavior
  Future<bool> onSwipeBack() async {
    if (_hasUnsavedChanges) {
      final shouldDiscard = await showDiscardChangesDialog();
      if (shouldDiscard) {
        return true; // Allow swipe back
      } else {
        return false; // Prevent swipe back
      }
    }
    return true; // Allow swipe back if no changes
  }

  void handleSessionExpired() {
    SessionHandler.handleSessionExpired(context);
  }

  Future<void> changeTab(String tabCode) async {
    // Check for unsaved changes before switching tabs
    if (_hasUnsavedChanges) {
      final shouldDiscard = await showDiscardChangesDialog();
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
      resetChangeTracking();
    }

    _safeSetState(() {
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
      onSessionExpired: handleSessionExpired,
      docSubTabCode: docSubTabCode,
    );

    // Re-initialize change tracking for new tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeChangeTracking();
    });
  }

  void showGenericErrorAndBack(String message) {
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
}
