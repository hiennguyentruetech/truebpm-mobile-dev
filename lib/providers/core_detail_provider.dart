import 'package:flutter/foundation.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/models/user_model.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/services/core_service.dart';

class CoreDetailProvider extends ChangeNotifier {
  // Core Data
  CoreDetailResponse? _detailResponse;
  Map<String, dynamic>? _rawResponse; // Raw response from API
  String? _moduleCode;
  String? _currentTabCode;
  Map<String, dynamic>? _listItem;
  List<TabConfig>? _availableTabs;
  Map<String, dynamic>? _tabAttributes;

  // Cache for NEW/COPY responses to avoid re-fetching on refresh
  Map<String, dynamic>? _cachedNewResponse;
  Map<String, dynamic>? _cachedCopyResponse;
  String? _currentCachedAction; // 'NEW' or 'COPY'
  String? _cachedResponseTabCode; // Tab code where the cache was created

  // Loading States
  bool _loading = true;
  bool _showLoadingOverlay = false;

  // Form Data
  Map<String, dynamic> _formData = {};

  // NEW: Error state for generic server/network errors
  int? _lastErrorStatusCode;
  String? _lastErrorMessage;

  // Services
  final CoreService _coreService = CoreService.instance;
  final AuthService _authService = AuthService();

  // Getters
  CoreDetailResponse? get detailResponse => _detailResponse;
  Map<String, dynamic>? get rawResponse => _rawResponse; // Raw API response
  ItemDetail? get itemDetail => _detailResponse?.itemDetail;
  ToolbarConfig? get toolbar => _detailResponse?.toolbar;
  String? get title => _detailResponse?.title;
  List<TabConfig>? get tabs => _availableTabs ?? _detailResponse?.tabs;
  String? get moduleCode => _moduleCode;
  String? get currentTabCode => _currentTabCode;
  String? get effectiveCurrentTabCode =>
      _currentTabCode == null ? null : _resolveApiTabCode(_currentTabCode!);
  Map<String, dynamic>? get listItem => _listItem;
  bool get loading => _loading;
  bool get showLoadingOverlay => _showLoadingOverlay;
  Map<String, dynamic> get formData => _formData;
  Map<String, dynamic>? get tabAttributes => _tabAttributes;
  String? get currentCachedAction =>
      _currentCachedAction; // For checking if this was a COPY operation
  int? get lastErrorStatusCode => _lastErrorStatusCode;
  String? get lastErrorMessage => _lastErrorMessage;

  // DOC sub-tab state
  String? _currentDocSubTabCode;
  bool _docSubTabLoadedOnce = false;

  String? get currentDocSubTabCode => _currentDocSubTabCode;
  bool get hasLoadedDocSubTabOnce => _docSubTabLoadedOnce;

  void clearLastError() {
    _lastErrorStatusCode = null;
    _lastErrorMessage = null;
  }

  String _resolveApiTabCode(String tabCode) {
    final tabs = _availableTabs ?? const <TabConfig>[];
    for (final tab in tabs) {
      if (tab.code == tabCode) {
        final apiCode = tab.apiCode;
        if (apiCode != null && apiCode.isNotEmpty) {
          return apiCode;
        }
        break;
      }
    }
    return tabCode;
  }

  /// Update listItem data - used after save operations to sync with widget.listItem
  void updateListItem(Map<String, dynamic> newListItem) {
    _listItem = Map<String, dynamic>.from(newListItem);
    notifyListeners();
  }

  /// Clear cached action after save to prevent multiple list refreshes
  void clearCachedAction() {
    _currentCachedAction = null;
    _cachedNewResponse = null;
    _cachedCopyResponse = null;
    _cachedResponseTabCode = null;
  }

  /// Clear cached responses when switching tabs to ensure fresh data
  void _clearCachedResponses() {
    _cachedNewResponse = null;
    _cachedCopyResponse = null;
    _cachedResponseTabCode = null;
    // Note: Don't clear _currentCachedAction as it's needed for list refresh logic
  }

  /// Update data after successful COPY operation
  void updateDataAfterCopy(Map<String, dynamic> copyResponse) {
    if (copyResponse['success'] == true) {
      // Store the complete copy response as raw response
      _rawResponse = Map<String, dynamic>.from(copyResponse);

      // Cache the copy response for future refresh operations
      _currentCachedAction = 'COPY';
      _cachedCopyResponse = Map<String, dynamic>.from(copyResponse);
      _cachedResponseTabCode = _currentTabCode;

      // Update detailResponse from copy response
      try {
        _detailResponse = CoreDetailResponse.fromJson(copyResponse);
      } catch (_) {}

      // Update form data with the latest values from copy response
      if (_detailResponse?.itemDetail?.value != null) {
        _formData
          ..clear()
          ..addAll(
            Map<String, dynamic>.from(_detailResponse!.itemDetail!.value),
          );
      } else if (copyResponse['itemDetail']?['value'] != null) {
        _formData
          ..clear()
          ..addAll(
            Map<String, dynamic>.from(copyResponse['itemDetail']['value']),
          );
      }

      notifyListeners();
    }
  }

  /// Update data after successful save operation without fetching again
  void updateDataAfterSave(Map<String, dynamic> saveResponse) {
    if (saveResponse['success'] == true) {
      // Store the complete save response as raw response
      _rawResponse = Map<String, dynamic>.from(saveResponse);

      // Determine if this was NEW or COPY flow and update internal listItem accordingly
      final wasNewAction = _listItem?['action'] == 'NEW';
      final wasCopyFlow = _currentCachedAction == 'COPY';

      // Try to extract the saved item data
      Map<String, dynamic>? newItemData;
      if (saveResponse['itemDetail'] != null &&
          saveResponse['itemDetail'] is Map<String, dynamic>) {
        newItemData = Map<String, dynamic>.from(
          saveResponse['itemDetail'] as Map<String, dynamic>,
        );
      } else if (saveResponse['itemDetail']?['value'] != null &&
          saveResponse['itemDetail']['value'] is Map<String, dynamic>) {
        newItemData = Map<String, dynamic>.from(
          saveResponse['itemDetail']['value'] as Map<String, dynamic>,
        );
      } else if (saveResponse['itemDetail'] != null) {
        try {
          final itemDetail = saveResponse['itemDetail'];
          if (itemDetail is Map) {
            newItemData = Map<String, dynamic>.from(
              itemDetail.cast<String, dynamic>(),
            );
          }
        } catch (_) {}
      }

      if (newItemData != null && newItemData.isNotEmpty) {
        // For NEW flow: replace listItem with saved record and remove action flag
        if (wasNewAction) {
          if (newItemData.containsKey('value') &&
              newItemData['value'] is Map<String, dynamic>) {
            _listItem = Map<String, dynamic>.from(
              newItemData['value'] as Map<String, dynamic>,
            );
          } else {
            _listItem = Map<String, dynamic>.from(newItemData);
          }
          _listItem?.remove('action');
          _currentCachedAction = 'NEW';
          _cachedNewResponse = Map<String, dynamic>.from(saveResponse);
          _cachedResponseTabCode = _currentTabCode;
        }
        // For COPY->SAVE flow: update provider._listItem to the saved record (do NOT touch caller's list tile)
        else if (wasCopyFlow) {
          if (newItemData.containsKey('value') &&
              newItemData['value'] is Map<String, dynamic>) {
            _listItem = Map<String, dynamic>.from(
              newItemData['value'] as Map<String, dynamic>,
            );
          } else {
            _listItem = Map<String, dynamic>.from(newItemData);
          }
          // Keep cached action as COPY to allow list refresh decision by caller
          _currentCachedAction = 'COPY';
          _cachedCopyResponse = Map<String, dynamic>.from(saveResponse);
          _cachedResponseTabCode = _currentTabCode;
        }
      }

      // Update detailResponse from save response
      try {
        _detailResponse = CoreDetailResponse.fromJson(saveResponse);
      } catch (_) {
        // Fallback: Keep existing detailResponse but update the value directly if possible
        if (_detailResponse?.itemDetail != null &&
            saveResponse['itemDetail']?['value'] != null) {
          _detailResponse!.itemDetail!.value
            ..clear()
            ..addAll(
              Map<String, dynamic>.from(saveResponse['itemDetail']['value']),
            );
        }
      }

      // Update form data with the latest values from save response
      if (_detailResponse?.itemDetail?.value != null) {
        _formData
          ..clear()
          ..addAll(
            Map<String, dynamic>.from(_detailResponse!.itemDetail!.value),
          );
      } else if (saveResponse['itemDetail']?['value'] != null) {
        _formData
          ..clear()
          ..addAll(
            Map<String, dynamic>.from(saveResponse['itemDetail']['value']),
          );
      }

      notifyListeners();
    }
  }

  // Field utility methods
  bool isFieldDisabled(String key) =>
      _detailResponse?.itemDetail?.attribute?.isDisabled(key) ?? false;

  bool isFieldHidden(String key) =>
      _detailResponse?.itemDetail?.attribute?.isHidden(key) ?? false;

  bool isFieldRequired(String key) =>
      _detailResponse?.itemDetail?.attribute?.isRequired(key) ?? false;

  /// Update rawResponse with new data from tab body
  void updateRawResponse(Map<String, dynamic> updatedData) {
    _rawResponse = Map<String, dynamic>.from(updatedData);

    // Also update formData if itemDetail.value exists
    if (updatedData['itemDetail']?['value'] != null) {
      _formData = Map<String, dynamic>.from(updatedData['itemDetail']['value']);
    }

    // Update detailResponse to ensure status and other fields are updated
    try {
      _detailResponse = CoreDetailResponse.fromJson(updatedData);
    } catch (_) {
      // Fallback: Update only the value part if parsing fails
      if (_detailResponse?.itemDetail != null &&
          updatedData['itemDetail']?['value'] != null) {
        _detailResponse!.itemDetail!.value
          ..clear()
          ..addAll(
            Map<String, dynamic>.from(updatedData['itemDetail']['value']),
          );
      }
    }

    // Trigger rebuild
    notifyListeners();
  }

  // Tab utility methods
  bool isTabDisabled(String tabCode) =>
      (_tabAttributes?['disabled']?[tabCode] == true);

  bool isTabHidden(String tabCode) =>
      (_tabAttributes?['hidden']?[tabCode] == true);

  // Toolbar utility methods
  bool isToolbarVisible(ToolbarAction action) {
    // Check itemDetail.toolbar first, then fallback to detailResponse.toolbar
    final itemToolbar = _detailResponse?.itemDetail?.toolbar;
    if (itemToolbar != null) {
      return itemToolbar.isVisible(action.value);
    }
    return _detailResponse?.toolbar?.isVisible(action.value) ?? true;
  }

  bool isToolbarEnabled(ToolbarAction action) {
    // Check itemDetail.toolbar first, then fallback to detailResponse.toolbar
    final itemToolbar = _detailResponse?.itemDetail?.toolbar;
    if (itemToolbar != null) {
      return itemToolbar.isEnabled(action.value);
    }
    return _detailResponse?.toolbar?.isEnabled(action.value) ?? true;
  }

  // Initialize
  Future<void> initialize(
    String moduleCode,
    Map<String, dynamic> listItem, {
    String? tabModuleCode,
    List<TabConfig>? availableTabs,
    Function? onSessionExpired,
    String? initialDocSubTabCode,
  }) async {
    _moduleCode = moduleCode;
    _listItem = listItem;
    _currentTabCode = tabModuleCode ?? 'DTLS';
    _availableTabs = availableTabs;

    // If initializing with DOC tab and sub-tab code provided, set it
    if (_currentTabCode?.toUpperCase() == 'DOC' &&
        initialDocSubTabCode != null) {
      _currentDocSubTabCode = initialDocSubTabCode;
      _docSubTabLoadedOnce = true; // Mark as loaded to prevent duplicate call
    }

    // Load page data first to get tab attributes
    await _loadPageData(onSessionExpired: onSessionExpired);

    // Fetch detail data with sub-tab if applicable
    if (_currentTabCode?.toUpperCase() == 'DOC' &&
        _currentDocSubTabCode != null) {
      await fetchDetailDataWithTabDocModule(
        tabDocModuleCode: _currentDocSubTabCode,
        onSessionExpired: onSessionExpired,
      );
    } else {
      await fetchDetailData(onSessionExpired: onSessionExpired);
    }
  }

  // Load page data to get tab attributes
  Future<void> _loadPageData({Function? onSessionExpired}) async {
    if (_moduleCode == null) return;

    try {
      UserModel? user = await _authService.getSavedUserInfo();
      final payload = {
        "user": user?.toJson() ?? {},
        "moduleCode": _moduleCode!,
      };

      final response = await _coreService.fetchPagedData(_moduleCode!, payload);

      if (response != null && response['tabAttributes'] != null) {
        _tabAttributes = response['tabAttributes'];
      }
    } catch (e) {
      if (onSessionExpired != null && e.toString().contains('session')) {
        onSessionExpired();
      }
    }
  }

  // Fetch detail data
  Future<void> fetchDetailData({
    Function? onSessionExpired,
    bool forceRefresh = false,
  }) async {
    if (_moduleCode == null || _listItem == null || _currentTabCode == null) {
      return;
    }

    _setLoading(true);
    _setLoadingOverlay(true);
    clearLastError();

    try {
      // Only use cached data when on the same tab where the cache was created
      if (!forceRefresh &&
          _currentCachedAction != null &&
          _cachedResponseTabCode == _currentTabCode) {
        Map<String, dynamic>? cachedResponse;
        if (_currentCachedAction == 'NEW' && _cachedNewResponse != null) {
          cachedResponse = _cachedNewResponse;
        } else if (_currentCachedAction == 'COPY' &&
            _cachedCopyResponse != null) {
          cachedResponse = _cachedCopyResponse;
        }

        if (cachedResponse != null) {
          _rawResponse = Map<String, dynamic>.from(cachedResponse);
          _detailResponse = CoreDetailResponse.fromJson(cachedResponse);

          if (_detailResponse?.itemDetail?.value != null) {
            _formData = Map<String, dynamic>.from(
              _detailResponse!.itemDetail!.value,
            );
          }

          notifyListeners();
          _setLoading(false);
          _setLoadingOverlay(false);
          return;
        }
      }

      UserModel? user = await _authService.getSavedUserInfo();

      // Check if this is a NEW action - simplified payload for new records
      final isNewAction = _listItem?['action'] == 'NEW';

      final apiTabCode = _resolveApiTabCode(_currentTabCode!);

      Map<String, dynamic> payload;
      if (isNewAction) {
        payload = {
          "user": user?.toJson() ?? {},
          "moduleCode": _moduleCode!,
          "tabModuleCode": apiTabCode,
        };
      } else {
        payload = {
          "user": user?.toJson() ?? {},
          "moduleCode": _moduleCode!,
          "tabModuleCode": apiTabCode,
          "listItem": _listItem!,
        };
      }

      Map<String, dynamic>? response;
      if (isNewAction) {
        response = await _coreService.fetchNewRecordData(
          _moduleCode!,
          apiTabCode,
          payload,
        );
      } else {
        response = await _coreService.fetchDetailData(
          _moduleCode!,
          apiTabCode,
          payload,
        );
      }

      if (response == null) {
        // Only null means 401/session expired
        onSessionExpired?.call();
      } else if (response.isNotEmpty) {
        // Server/network error map may come here; detect by success=false and 5xx or missing itemDetail
        final isErrorMap =
            response['success'] == false &&
            (response['statusCode'] == null ||
                (response['statusCode'] is int &&
                    response['statusCode'] >= 500));
        final hasItemDetail = response['itemDetail'] != null;
        if (isErrorMap || !hasItemDetail) {
          _lastErrorStatusCode = (response['statusCode'] as int?) ?? 500;
          _lastErrorMessage =
              response['message']?.toString() ??
              'Connection error. Please try again later.';
          notifyListeners();
        } else {
          // Store raw response for dynamic access
          _rawResponse = Map<String, dynamic>.from(response);

          try {
            _detailResponse = CoreDetailResponse.fromJson(response);
          } catch (_) {}

          // Initialize form data with current values
          if (_detailResponse?.itemDetail?.value != null) {
            _formData = Map<String, dynamic>.from(
              _detailResponse!.itemDetail!.value,
            );
          }

          notifyListeners();
        }
      }
    } catch (e) {
      // Generic error
      _lastErrorStatusCode = 500;
      _lastErrorMessage = 'Connection error. Please try again later.';
      notifyListeners();
    } finally {
      _setLoading(false);
      _setLoadingOverlay(false);
    }
  }

  // Ensure first load for DOC sub-tab default, guarded across rebuilds
  Future<void> ensureDocSubTabFirstLoad(
    String tabDocModuleCode, {
    Function? onSessionExpired,
  }) async {
    if (_docSubTabLoadedOnce) return;
    _currentDocSubTabCode = tabDocModuleCode;
    _docSubTabLoadedOnce = true;
    await fetchDetailDataWithTabDocModule(
      tabDocModuleCode: tabDocModuleCode,
      onSessionExpired: onSessionExpired,
    );
  }

  // Switch DOC sub-tab and fetch data only when changed
  Future<void> switchDocSubTab(
    String tabDocModuleCode, {
    Function? onSessionExpired,
    bool forceReload = false,
  }) async {
    // Skip if same sub-tab and data exists (unless forced)
    if (!forceReload &&
        _currentDocSubTabCode == tabDocModuleCode &&
        _rawResponse != null &&
        _rawResponse?['itemDetail']?['tabDocModuleCode'] == tabDocModuleCode) {
      return;
    }

    _currentDocSubTabCode = tabDocModuleCode;
    await fetchDetailDataWithTabDocModule(
      tabDocModuleCode: tabDocModuleCode,
      onSessionExpired: onSessionExpired,
    );
  }

  // Fetch detail data with tabDocModuleCode for sub-tabs
  Future<void> fetchDetailDataWithTabDocModule({
    String? tabDocModuleCode,
    Function? onSessionExpired,
  }) async {
    if (_moduleCode == null || _listItem == null || _currentTabCode == null) {
      return;
    }

    // Don't show overlay loading for sub-tab switches, only show inline loading
    _setLoading(true);
    clearLastError();

    try {
      UserModel? user = await _authService.getSavedUserInfo();

      // Check if this is a NEW action
      final isNewAction = _listItem?['action'] == 'NEW';

      final apiTabCode = _resolveApiTabCode(_currentTabCode!);

      Map<String, dynamic> payload;
      if (isNewAction) {
        payload = {
          "user": user?.toJson() ?? {},
          "moduleCode": _moduleCode!,
          "tabModuleCode": apiTabCode,
        };
      } else {
        payload = {
          "user": user?.toJson() ?? {},
          "moduleCode": _moduleCode!,
          "tabModuleCode": apiTabCode,
          "listItem": _listItem!,
        };
      }

      // Add tabDocModuleCode if provided (for sub-tabs in Documents)
      if (tabDocModuleCode != null) {
        payload["tabDocModuleCode"] = tabDocModuleCode;
      }

      Map<String, dynamic>? response;
      if (isNewAction) {
        response = await _coreService.fetchNewRecordData(
          _moduleCode!,
          apiTabCode,
          payload,
        );
      } else {
        response = await _coreService.fetchDetailData(
          _moduleCode!,
          apiTabCode,
          payload,
        );
      }

      // Track current DOC sub-tab code if provided
      if (tabDocModuleCode != null && tabDocModuleCode.isNotEmpty) {
        _currentDocSubTabCode = tabDocModuleCode;
      }

      if (response == null) {
        onSessionExpired?.call();
      } else if (response.isNotEmpty) {
        // Check for errors
        final isErrorMap =
            response['success'] == false &&
            (response['statusCode'] == null ||
                (response['statusCode'] is int &&
                    response['statusCode'] >= 500));
        final hasItemDetail = response['itemDetail'] != null;
        if (isErrorMap || !hasItemDetail) {
          _lastErrorStatusCode = (response['statusCode'] as int?) ?? 500;
          _lastErrorMessage =
              response['message']?.toString() ??
              'Connection error. Please try again later.';
          notifyListeners();
        } else {
          // Store raw response for dynamic access
          _rawResponse = Map<String, dynamic>.from(response);

          try {
            _detailResponse = CoreDetailResponse.fromJson(response);
          } catch (_) {}

          // Initialize form data with current values
          if (_detailResponse?.itemDetail?.value != null) {
            _formData = Map<String, dynamic>.from(
              _detailResponse!.itemDetail!.value,
            );
          }

          notifyListeners();
        }
      }
    } catch (e) {
      _lastErrorStatusCode = 500;
      _lastErrorMessage = 'Connection error. Please try again later.';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Switch tab
  Future<void> switchTab(
    String tabCode, {
    Function? onSessionExpired,
    String? docSubTabCode,
  }) async {
    if (_currentTabCode == tabCode &&
        (tabCode.toUpperCase() != 'DOC' ||
            _currentDocSubTabCode == docSubTabCode)) {
      return;
    }

    _currentTabCode = tabCode;

    // Clear cached responses when switching tabs to ensure fresh data
    // This prevents using stale cached data (e.g., SAVE response when status has changed via SUBMIT)
    _clearCachedResponses();

    // If switching to DOC tab with sub-tab code, fetch with sub-tab
    if (tabCode.toUpperCase() == 'DOC' && docSubTabCode != null) {
      _currentDocSubTabCode = docSubTabCode;
      _docSubTabLoadedOnce = true;
      await fetchDetailDataWithTabDocModule(
        tabDocModuleCode: docSubTabCode,
        onSessionExpired: onSessionExpired,
      );
    } else {
      // Reset DOC sub-tab state when switching away from DOC
      if (tabCode.toUpperCase() != 'DOC') {
        _currentDocSubTabCode = null;
        _docSubTabLoadedOnce = false;
      }
      await fetchDetailData(onSessionExpired: onSessionExpired);
    }
  }

  /// Switch to default tab (DTLS) after COPY operation
  Future<void> switchToDefaultTab({Function? onSessionExpired}) async {
    if (_availableTabs == null || _availableTabs!.isEmpty) {
      return;
    }

    // Find default tab with better error handling
    TabConfig? defaultTab;

    try {
      // First try to find explicit default tab
      defaultTab = _availableTabs!.firstWhere(
        (tab) => tab.isDefault == true,
        orElse: () => throw StateError('No default tab'),
      );
    } catch (e) {
      // Then try to find DTLS tab
      try {
        defaultTab = _availableTabs!.firstWhere(
          (tab) => tab.code.toUpperCase() == 'DTLS',
          orElse: () => throw StateError('No DTLS tab'),
        );
      } catch (e) {
        // Finally use first available tab
        if (_availableTabs!.isNotEmpty) {
          defaultTab = _availableTabs!.first;
        }
      }
    }

    if (defaultTab != null && defaultTab.code != _currentTabCode) {
      await switchTab(defaultTab.code, onSessionExpired: onSessionExpired);
    }
  }

  // Update form field
  void updateFormField(String key, dynamic value) {
    _formData[key] = value;
    notifyListeners();
  }

  // Get form field value
  dynamic getFormFieldValue(String key) {
    return _formData[key];
  }

  // Toolbar actions
  Future<void> performToolbarAction(ToolbarAction action) async {
    switch (action) {
      case ToolbarAction.save:
        await _handleSave();
        break;
      case ToolbarAction.submit:
        await _handleSubmit();
        break;
      case ToolbarAction.copy:
        await _handleCopy();
        break;
      case ToolbarAction.cancel:
        _handleCancel();
        break;
      case ToolbarAction.delete:
        await _handleDelete();
        break;
      case ToolbarAction.print:
        await _handlePrint();
        break;
      case ToolbarAction.refresh:
        await _handleRefresh();
        break;
    }
  }

  // Private action handlers (placeholders)
  Future<void> _handleSave() async {}
  Future<void> _handleSubmit() async {}
  Future<void> _handleCopy() async {}
  void _handleCancel() {}
  Future<void> _handleDelete() async {}
  Future<void> _handlePrint() async {}
  Future<void> _handleRefresh() async {}

  // Private helper methods
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setLoadingOverlay(bool value) {
    _showLoadingOverlay = value;
    notifyListeners();
  }

  // Public method to control loading overlay
  void setLoadingOverlay(bool value) {
    _setLoadingOverlay(value);
  }

  // Reset state
  void reset() {
    _detailResponse = null;
    _rawResponse = null;
    _moduleCode = null;
    _currentTabCode = null;
    _listItem = null;
    _availableTabs = null;
    _tabAttributes = null;
    _cachedNewResponse = null;
    _cachedCopyResponse = null;
    _currentCachedAction = null;
    _cachedResponseTabCode = null;
    _loading = true;
    _showLoadingOverlay = false;
    _formData = {};
    _currentDocSubTabCode = null;
    _docSubTabLoadedOnce = false;
    notifyListeners();
  }

  @override
  void dispose() {
    reset();
    super.dispose();
  }
}
