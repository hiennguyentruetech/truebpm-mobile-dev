import 'package:flutter/foundation.dart';
import 'package:truebpm/models/core_data_model.dart';
import 'package:truebpm/models/user_model.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/utils/core_constants.dart';

class CoreListProvider extends ChangeNotifier {
  // Core Data
  DataSpies? _dataSpies;
  String? _selectedId;
  String? _displayModuleName;
  List<dynamic> _listData = [];
  ConfigListItem? _configListItem;
  Map<String, dynamic>? _toolbar;

  // Loading States
  bool _loading = true;
  bool _showLoadingOverlay = false;
  bool _isLoadingMore = false;

  // Search State
  String _currentFilterInput = "";
  bool _isSearchVisible = false;

  // Pagination State
  int _currentPagination = CoreConstants.initialPagination;
  bool _hasMoreRecords = false;

  // NEW: Error state for generic server/network errors
  int? _lastErrorStatusCode;
  String? _lastErrorMessage;

  // Services
  final CoreService _coreService = CoreService.instance;
  final AuthService _authService = AuthService();

  // Getters
  DataSpies? get dataSpies => _dataSpies;
  Map<String, dynamic>? get dataSpy => _dataSpies?.value.toJson();
  String? get selectedId => _selectedId;
  String? get displayModuleName => _displayModuleName;
  List<dynamic> get listData => _listData;
  ConfigListItem? get configListItem => _configListItem;
  Map<String, dynamic>? get toolbar => _toolbar;
  bool get loading => _loading;
  bool get showLoadingOverlay => _showLoadingOverlay;
  bool get isLoadingMore => _isLoadingMore;
  String get currentFilterInput => _currentFilterInput;
  bool get isSearchVisible => _isSearchVisible;
  int get currentPagination => _currentPagination;
  bool get hasMoreRecords => _hasMoreRecords;
  int? get lastErrorStatusCode => _lastErrorStatusCode;
  String? get lastErrorMessage => _lastErrorMessage;

  List<String> get headers =>
      _configListItem?.headersList ?? CoreConstants.defaultHeaders;
  List<String> get contents =>
      _configListItem?.contentsList ?? CoreConstants.defaultContents;

  // Toolbar helper methods
  bool get isNewButtonHidden => _toolbar?['hidden']?['new'] == true;
  bool get isNewButtonDisabled => _toolbar?['disabled']?['new'] == true;
  bool get shouldShowNewButton => !isNewButtonHidden;
  bool get isNewButtonEnabled => !isNewButtonDisabled;

  void clearLastError() {
    _lastErrorStatusCode = null;
    _lastErrorMessage = null;
  }

  // Private session expired callback store
  Function? _onSessionExpired;

  // Initialize
  Future<void> initialize(
    String moduleCode,
    String? moduleName, {
    Function? onSessionExpired,
  }) async {
    _displayModuleName = moduleName ?? moduleCode;
    _onSessionExpired = onSessionExpired; // Store callback for later use
    await fetchData(moduleCode, onSessionExpired: onSessionExpired);
  }

  // Fetch initial data
  Future<void> fetchData(
    String moduleCode, {
    Function? onSessionExpired,
  }) async {
    final sessionExpiredCallback = onSessionExpired ?? _onSessionExpired;
    _setLoadingOverlay(true);
    clearLastError();

    try {
      UserModel? user = await _authService.getSavedUserInfo();
      final payload = {"user": user?.toJson() ?? {}, "moduleCode": moduleCode};

      final response = await _coreService.fetchPagedData(moduleCode, payload);
      if (response == null) {
        // Only null means 401/session expired per CoreService
        _setLoadingOverlay(false);
        sessionExpiredCallback?.call();
        return;
      }

      // If server/network error map returned, capture error and let UI decide
      if (response['success'] == false &&
          (response['statusCode'] == null || response['statusCode'] >= 500)) {
        _lastErrorStatusCode = (response['statusCode'] as int?) ?? 500;
        _lastErrorMessage =
            response['message']?.toString() ??
            'Connection error. Please try again later.';
        notifyListeners();
        _setLoadingOverlay(false);
        return;
      }

      if (response["dataSpies"] != null) {
        _dataSpies = DataSpies.fromJson(response["dataSpies"]);
        _selectedId = _dataSpies!.value.id;
        _displayModuleName =
            response["moduleName"]?.toString() ??
            _displayModuleName ??
            moduleCode;

        if (response["configListItem"] != null) {
          _configListItem = ConfigListItem.fromJson(response["configListItem"]);
        }

        // Store toolbar configuration
        if (response["toolbar"] != null) {
          _toolbar = response["toolbar"];
        }

        notifyListeners();
        await fetchListData(
          moduleCode,
          null,
          onSessionExpired: sessionExpiredCallback,
        );
      } else {
        // Missing expected data but not a 401: stop loader but stay on screen
        _setLoadingOverlay(false);
      }
    } catch (e) {
      // Do not treat as session expired here; capture as generic error
      _lastErrorStatusCode = 500;
      _lastErrorMessage = 'Connection error. Please try again later.';
      notifyListeners();
      _setLoadingOverlay(false);
    }
  }

  // Fetch list data
  Future<void> fetchListData(
    String moduleCode,
    String? tabModuleCode, {
    bool isLoadMore = false,
    String? filterInput,
    Function? onSessionExpired,
  }) async {
    final sessionExpiredCallback = onSessionExpired ?? _onSessionExpired;
    if (_dataSpies == null) return;

    if (!isLoadMore) {
      _setLoading(true);
      _setLoadingOverlay(true);
      _currentPagination = CoreConstants.initialPagination;
    } else {
      _setLoadingMore(true);
    }

    // Update current filter input
    if (filterInput != null) {
      _currentFilterInput = filterInput;
    }

    try {
      UserModel? user = await _authService.getSavedUserInfo();
      final payload = {
        "user": user?.toJson() ?? {},
        "moduleCode": moduleCode,
        "tabModuleCode": tabModuleCode ?? "DTLS",
        "dataSpy": _dataSpies!.value.toJson(),
        "pagination": isLoadMore ? _currentPagination + 1 : _currentPagination,
        if (_currentFilterInput.isNotEmpty) "filterInput": _currentFilterInput,
      };

      final response = await _coreService.fetchListData(moduleCode, payload);
      if (response == null) {
        // Only null means 401/session expired
        if (!isLoadMore) {
          _setLoading(false);
          _setLoadingOverlay(false);
        } else {
          _setLoadingMore(false);
        }
        sessionExpiredCallback?.call();
      } else if (response["data"] != null) {
        if (isLoadMore) {
          _listData.addAll(response["data"] as List);
          _currentPagination++;
          _setLoadingMore(false);
        } else {
          _listData = response["data"] as List;
          _setLoading(false);
          _setLoadingOverlay(false);
        }

        _hasMoreRecords = response["value"]?["moreRecords"] == true;
        notifyListeners();
      } else {
        // Error map: capture and keep current list, just stop loaders
        _lastErrorStatusCode = (response['statusCode'] as int?) ?? 500;
        _lastErrorMessage =
            response['message']?.toString() ??
            'Connection error. Please try again later.';
        notifyListeners();
        if (!isLoadMore) {
          _setLoading(false);
          _setLoadingOverlay(false);
        } else {
          _setLoadingMore(false);
        }
      }
    } catch (e) {
      // Stop loaders; capture generic error; do not call session expired here
      _lastErrorStatusCode = 500;
      _lastErrorMessage = 'Connection error. Please try again later.';
      notifyListeners();
      if (!isLoadMore) {
        _setLoading(false);
        _setLoadingOverlay(false);
      } else {
        _setLoadingMore(false);
      }
    }
  }

  // Load more data
  Future<void> loadMoreData(String moduleCode, String? tabModuleCode) async {
    if (!_hasMoreRecords || _isLoadingMore || _loading) return;

    _setLoadingOverlay(true);
    await fetchListData(
      moduleCode,
      tabModuleCode,
      isLoadMore: true,
      onSessionExpired: _onSessionExpired,
    );
    _setLoadingOverlay(false);
  }

  // Refresh data
  Future<void> refreshData(String moduleCode, String? tabModuleCode) async {
    _setLoadingOverlay(true);
    await fetchListData(
      moduleCode,
      tabModuleCode,
      filterInput: _currentFilterInput,
      onSessionExpired: _onSessionExpired,
    );
    _setLoadingOverlay(false);
  }

  // Search functionality
  void performSearch(
    String moduleCode,
    String? tabModuleCode,
    String searchQuery,
  ) {
    _setLoadingOverlay(true);
    fetchListData(
      moduleCode,
      tabModuleCode,
      filterInput: searchQuery.trim(),
      onSessionExpired: _onSessionExpired,
    );
  }

  void toggleSearch() {
    _isSearchVisible = !_isSearchVisible;
    if (!_isSearchVisible && _currentFilterInput.isNotEmpty) {
      _currentFilterInput = "";
      // Clear search will be handled by screen
    }
    notifyListeners();
  }

  // DataSpy selection
  void selectDataSpy(
    String? dataSpyId,
    String moduleCode,
    String? tabModuleCode,
  ) {
    if (dataSpyId == null || _dataSpies == null) return;

    _selectedId = dataSpyId;
    final selected = _dataSpies!.data.firstWhere((e) => e.id == dataSpyId);
    _dataSpies = DataSpies(data: _dataSpies!.data, value: selected);

    _setLoadingOverlay(true);
    notifyListeners();
    fetchListData(
      moduleCode,
      tabModuleCode,
      onSessionExpired: _onSessionExpired,
    );
  }

  // Private helper methods
  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }

  void _setLoadingOverlay(bool value) {
    _showLoadingOverlay = value;
    notifyListeners();
  }

  void _setLoadingMore(bool value) {
    _isLoadingMore = value;
    notifyListeners();
  }

  // Reset state
  void reset() {
    _dataSpies = null;
    _selectedId = null;
    _displayModuleName = null;
    _listData = [];
    _configListItem = null;
    _loading = true;
    _showLoadingOverlay = false;
    _isLoadingMore = false;
    _currentFilterInput = "";
    _isSearchVisible = false;
    _currentPagination = CoreConstants.initialPagination;
    _hasMoreRecords = false;
    _onSessionExpired = null; // Clear session expired callback
    notifyListeners();
  }
}
