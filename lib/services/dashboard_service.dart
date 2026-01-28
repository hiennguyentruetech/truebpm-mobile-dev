import 'package:truebpm/models/dashboard_model.dart';
import 'package:truebpm/models/user_model.dart';
import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/utils/global_store.dart';

/// Service for Dashboard API calls
class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  static DashboardService get instance => _instance;
  
  DashboardService._internal();
  
  final CoreService _coreService = CoreService.instance;
  final AuthService _authService = AuthService();

  /// Fetch DASHBOARD.PAGEDATA - get chart configs and tree structure
  Future<DashboardPageDataResponse?> fetchPageData() async {
    try {
      final user = await _authService.getSavedUserInfo();
      if (user == null) {
        logger.w('No user info found for dashboard');
        return null;
      }

      final payload = {
        'user': user.toJson(),
        'moduleCode': 'DASHBOARD',
      };

      final response = await _coreService.fetchPagedData('DASHBOARD', payload);
      if (response == null) {
        logger.w('Dashboard PAGEDATA response is null');
        return null;
      }

      logger.i('Dashboard PAGEDATA loaded successfully');
      return DashboardPageDataResponse.fromJson(response);
    } catch (e, stack) {
      logger.e('Error fetching dashboard page data: $e\n$stack');
      return null;
    }
  }

  /// Fetch DASHBOARD.LST - get inbox data items
  Future<DashboardListResponse?> fetchListData({int? year}) async {
    try {
      final user = await _authService.getSavedUserInfo();
      if (user == null) {
        logger.w('No user info found for dashboard list');
        return null;
      }

      final payload = {
        'user': user.toJson(),
        'moduleCode': 'DASHBOARD',
        'tabModuleCode': 'DTLS',
        'dataSpy': [],
        'filterInput': '',
        'pagination': 1,
        if (year != null) 'year': year,
      };

      final response = await _coreService.fetchListData('DASHBOARD', payload);
      if (response == null) {
        logger.w('Dashboard LST response is null');
        return null;
      }

      logger.i('Dashboard LST loaded successfully');
      return DashboardListResponse.fromJson(response);
    } catch (e, stack) {
      logger.e('Error fetching dashboard list data: $e\n$stack');
      return null;
    }
  }

  /// Fetch DASHBOARD.DTLS - get default charts configuration
  Future<DashboardConfig?> fetchDashboardConfig() async {
    try {
      final user = await _authService.getSavedUserInfo();
      if (user == null) {
        logger.w('No user info found for dashboard config');
        return null;
      }

      final payload = {
        'user': user.toJson(),
        'moduleCode': 'DASHBOARD',
        'tabModuleCode': 'DTLS',
      };

      final response = await _coreService.fetchDetailData('DASHBOARD', 'DTLS', payload);
      if (response == null) {
        logger.w('Dashboard DTLS response is null');
        return null;
      }

      logger.i('Dashboard DTLS loaded successfully');
      return DashboardConfig.fromJson(response);
    } catch (e, stack) {
      logger.e('Error fetching dashboard config: $e\n$stack');
      return null;
    }
  }

  /// Fetch DASHBOARD.CHARTDTLS - get chart detail data
  Future<ChartDetailData?> fetchChartDetail({
    required String chartId,
    Map<String, String>? filterValues,
  }) async {
    try {
      final user = await _authService.getSavedUserInfo();
      if (user == null) {
        logger.w('No user info found for chart detail');
        return null;
      }

      final payload = {
        'id': chartId,
        'user': user.toJson(),
        if (filterValues != null && filterValues.isNotEmpty) 
          'filterValues': filterValues,
      };

      final response = await _coreService.fetchDetailData('DASHBOARD', 'CHARTDTLS', payload);
      if (response == null) {
        logger.w('Dashboard CHARTDTLS response is null');
        return null;
      }

      logger.i('Dashboard CHARTDTLS loaded successfully for chart: $chartId');
      return ChartDetailData.fromJson(response);
    } catch (e, stack) {
      logger.e('Error fetching chart detail: $e\n$stack');
      return null;
    }
  }

  /// Get current user info
  Future<UserModel?> getCurrentUser() async {
    return await _authService.getSavedUserInfo();
  }
}
