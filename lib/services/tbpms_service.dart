import 'package:truebpm/services/core_service.dart';
import 'package:truebpm/utils/global_store.dart';

/// Service chuyên biệt cho TBPMS (Table Permissions) module
/// Tái sử dụng logic từ CoreService với dataSelect trong listItem
class TbpmsService {
  static final TbpmsService _instance = TbpmsService._internal();
  static TbpmsService get instance => _instance;
  
  TbpmsService._internal();

  /// Load data với dataSelect để filter và refresh tree
  /// Tái sử dụng fetchDetailData từ CoreService
  Future<Map<String, dynamic>?> loadDataWithDataSelect({
    required String moduleCode,
    required String tabModuleCode,
    required Map<String, dynamic> user,
    required Map<String, dynamic> listItem,
    Map<String, dynamic>? dataSelect,
  }) async {
    try {
      // Tạo payload với dataSelect trong listItem
      final payload = {
        'user': user,
        'listItem': {
          ...listItem,
          if (dataSelect != null) 'dataSelect': dataSelect,
        },
        'moduleCode': moduleCode,
        'tabModuleCode': tabModuleCode,
      };

      // Sử dụng fetchDetailData từ CoreService
      final result = await CoreService.instance.fetchDetailData(
        moduleCode,
        tabModuleCode,
        payload,
      );

      return result;
    } catch (e) {
      // Log error và return null
      print('❌ TbpmsService.loadDataWithDataSelect error: $e');
      return null;
    }
  }

  /// Save data với cấu trúc grantPermission đã được xử lý
  Future<Map<String, dynamic>?> saveData({
    required String moduleCode,
    required String tabModuleCode,
    required Map<String, dynamic> user,
    required Map<String, dynamic> itemDetail,
    required Map<String, dynamic> dataSpy,
  }) async {
    try {
      // Sử dụng saveData từ CoreService
      final result = await CoreService.instance.saveData(
        moduleCode,
        tabModuleCode,
        user,
        itemDetail,
        dataSpy,
      );

      return result;
    } catch (e) {
      print('❌ TbpmsService.saveData error: $e');
      return null;
    }
  }

  /// Submit data với cấu trúc grantPermission đã được xử lý
  Future<Map<String, dynamic>?> submitData({
    required String moduleCode,
    required String tabModuleCode,
    required Map<String, dynamic> user,
    required Map<String, dynamic> itemDetail,
    required Map<String, dynamic> dataSpy,
  }) async {
    try {
      // Sử dụng submitData từ CoreService
      final result = await CoreService.instance.submitData(
        moduleCode,
        tabModuleCode,
        user,
        itemDetail,
        dataSpy,
      );

      return result;
    } catch (e) {
      print('❌ TbpmsService.submitData error: $e');
      return null;
    }
  }

  /// Validate cấu trúc grantPermission trước khi save/submit
  bool validateGrantPermissionStructure(Map<String, dynamic> treeData) {
    if (treeData['data'] is List) {
      final List<dynamic> treeItems = treeData['data'];
      
      for (final item in treeItems) {
        if (item is Map<String, dynamic> && item['grantPermission'] != null) {
          if (item['grantPermission'] is List) {
            final List<dynamic> permissions = item['grantPermission'];
            
            for (final permission in permissions) {
              if (permission is Map<String, dynamic>) {
                // Kiểm tra cấu trúc userPermission
                if (permission['userPermission'] == null ||
                    permission['userPermission']['id'] == null ||
                    permission['userPermission']['name'] == null) {
                  return false;
                }
              } else {
                return false;
              }
            }
          } else {
            return false;
          }
        }
      }
    }
    
    return true;
  }

  /// Normalize cấu trúc grantPermission để đảm bảo format đúng
  Map<String, dynamic> normalizeGrantPermissionStructure(Map<String, dynamic> treeData) {
    if (treeData['data'] is List) {
      final List<dynamic> treeItems = List.from(treeData['data']);
      
      for (int i = 0; i < treeItems.length; i++) {
        final item = treeItems[i];
        if (item is Map<String, dynamic> && item['grantPermission'] != null) {
          if (item['grantPermission'] is List) {
            final List<dynamic> permissions = List.from(item['grantPermission']);
            
            for (int j = 0; j < permissions.length; j++) {
              final permission = permissions[j];
              if (permission is Map<String, dynamic>) {
                // Đảm bảo có userPermission object với cấu trúc đúng
                if (permission['userPermission'] == null) {
                  permissions[j] = {
                    'userPermission': {
                      'id': permission['id'] ?? permission['userPermissionId'] ?? '',
                      'name': permission['name'] ?? permission['permissionName'] ?? '',
                    }
                  };
                } else if (permission['userPermission'] is Map<String, dynamic>) {
                  // Đảm bảo các field bắt buộc có giá trị
                  final userPermission = permission['userPermission'];
                  if (userPermission['id'] == null) {
                    userPermission['id'] = userPermission['userPermissionId'] ?? '';
                  }
                  if (userPermission['name'] == null) {
                    userPermission['name'] = userPermission['permissionName'] ?? '';
                  }
                }
              }
            }
            
            // Cập nhật lại item với permissions đã được normalize
            treeItems[i] = {
              ...item,
              'grantPermission': permissions,
            };
          }
        }
      }
      
      // Cập nhật lại treeData
      treeData['data'] = treeItems;
    }
    
    return treeData;
  }

  /// Format đặc biệt cho grantPermission: wrap selected items vào userPermission object
  /// Sử dụng cho trường hợp đặc biệt khi cần format: userPermission: {id, name, ...}
  static List<Map<String, dynamic>> formatGrantPermissionWithUserPermissionWrapper(List<dynamic> selectedItems) {
    final List<Map<String, dynamic>> formattedPermissions = [];
    
    for (final item in selectedItems) {
      if (item is Map<String, dynamic>) {
        // Wrap item vào userPermission object
        formattedPermissions.add({
          'userPermission': {
            'id': item['id'] ?? item['userPermissionId'] ?? '',
            'name': item['name'] ?? item['permissionName'] ?? '',
            // Copy tất cả các field khác nếu có
            ...item.map((key, value) {
              if (key != 'id' && key != 'name' && key != 'userPermissionId' && key != 'permissionName') {
                return MapEntry(key, value);
              }
              return MapEntry('', null);
            }).entries.where((entry) => entry.value != null).fold<Map<String, dynamic>>({}, (map, entry) {
              map[entry.key] = entry.value;
              return map;
            }),
          }
        });
      } else if (item is String) {
        // Nếu item là string (ID), tạo userPermission object với ID
        formattedPermissions.add({
          'userPermission': {
            'id': item,
            'name': item, // Fallback name
          }
        });
      }
    }
    
    return formattedPermissions;
  }

  /// Parse grantPermission từ format userPermission wrapper về format gốc
  /// Sử dụng để hiển thị trong dropdown
  static List<Map<String, dynamic>> parseGrantPermissionFromUserPermissionWrapper(List<dynamic> permissions) {
    final List<Map<String, dynamic>> parsedPermissions = [];
    
    for (final permission in permissions) {
      if (permission is Map<String, dynamic> && permission['userPermission'] != null) {
        final userPermission = permission['userPermission'];
        // Extract từ userPermission wrapper
        parsedPermissions.add({
          'id': userPermission['id'] ?? '',
          'name': userPermission['name'] ?? '',
          // Copy tất cả các field khác
          ...userPermission.map((key, value) {
            if (key != 'id' && key != 'name') {
              return MapEntry(key, value);
            }
            return MapEntry('', null);
          }).entries.where((entry) => entry.value != null).fold<Map<String, dynamic>>({}, (map, entry) {
            map[entry.key] = entry.value;
            return map;
          }),
        });
      } else if (permission is Map<String, dynamic>) {
        // Nếu không có userPermission wrapper, giữ nguyên
        parsedPermissions.add(Map<String, dynamic>.from(permission));
      }
    }
    
    return parsedPermissions;
  }
}
