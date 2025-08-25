import 'dart:convert';
import 'dart:math' as math;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truebpm/utils/global_store.dart';
import 'package:http_parser/http_parser.dart';

class CoreService {
  static final CoreService _instance = CoreService._internal();
  static CoreService get instance => _instance;
  
  CoreService._internal();
  
  final Dio _dio = Dio();

  /// Generic method to fetch paged data for any module using POST and session cookies
  Future<Map<String, dynamic>?> fetchPagedData(String moduleCode, Map<String, dynamic> payload) async {
    return _makeApiCall('$moduleCode.PAGEDATA', payload);
  }

  /// Generic method to fetch list data for any module using POST and session cookies
  Future<Map<String, dynamic>?> fetchListData(String moduleCode, Map<String, dynamic> payload) async {
    return _makeApiCall('$moduleCode.LST', payload);
  }

  /// Generic method to fetch detail data for any module using POST and session cookies
  Future<Map<String, dynamic>?> fetchDetailData(String moduleCode, String tabModuleCode, Map<String, dynamic> payload) async {
    return _makeApiCall('$moduleCode.$tabModuleCode', payload);
  }

  /// Fetch data for creating new records with action=NEW parameter
  Future<Map<String, dynamic>?> fetchNewRecordData(String moduleCode, String tabModuleCode, Map<String, dynamic> payload) async {
    return _makeApiCall('$moduleCode.$tabModuleCode?action=NEW', payload);
  }

  /// Generic method to perform actions (SAVE, SUBMIT, COPY, CANCEL, DELETE)
  Future<Map<String, dynamic>?> performAction(
    String moduleCode, 
    String tabModuleCode, 
    String action, 
    Map<String, dynamic> payload,
  ) async {
    return _makeApiCall('$moduleCode.$tabModuleCode?action=$action', payload);
  }

  /// Fetch list of task processes from Bonita BPM API
  Future<List<Map<String, dynamic>>?> fetchListTaskProcess() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get Bonita user info to extract user_id
      final bonitaUserInfoStr = prefs.getString('bonita_user_info');
      if (bonitaUserInfoStr == null) {
        logger.e('No Bonita user info found');
        return null;
      }
      
      final bonitaUserInfo = jsonDecode(bonitaUserInfoStr);
      final userId = bonitaUserInfo['user_id']?.toString();
      if (userId == null) {
        logger.e('No user_id found in Bonita user info');
        return null;
      }

      final url = '${hosts.bpmUrl}humanTask?c=1000&d=rootContainerId&f=state%3Dready&f=user_id%3D$userId&p=0';

      // Get cookies from saved login
      List<String> cookies = [];
      final cookiesStr = prefs.getString('session_cookies');
      if (cookiesStr != null && cookiesStr.isNotEmpty) {
        try {
          final dynamic parsed = jsonDecode(cookiesStr);
          if (parsed is List) {
            cookies = parsed.map((e) => e.toString()).toList();
          }
        } catch (_) {
          cookies = [cookiesStr];
        }
      }
      
      // Extract X-Bonita-API-Token from cookies
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            logger.i('[TASK_LIST] bonitaToken extracted: $bonitaToken');
            break;
          }
        }
      }

      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };

      logger.i('[TASK_LIST] GET $url');
      logger.i('[TASK_LIST] Headers: $headers');

      final response = await _dio.get(
        url,
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      logger.i('[TASK_LIST] Response: ${response.statusCode}');
      
      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          return List<Map<String, dynamic>>.from(response.data);
        }
      }
      
      logger.w('[TASK_LIST] Failed to fetch task list: ${response.statusCode}');
      return null;
    } catch (e) {
      logger.e('[TASK_LIST] Error fetching task list: $e');
      return null;
    }
  }

  /// Take (assign) a task to current user in Bonita BPM
  Future<bool> takeTask(String taskId, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get cookies from saved login
      List<String> cookies = [];
      final cookiesStr = prefs.getString('session_cookies');
      if (cookiesStr != null && cookiesStr.isNotEmpty) {
        try {
          final dynamic parsed = jsonDecode(cookiesStr);
          if (parsed is List) {
            cookies = parsed.map((e) => e.toString()).toList();
          }
        } catch (_) {
          cookies = [cookiesStr];
        }
      }
      
      // Extract X-Bonita-API-Token from cookies
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            break;
          }
        }
      }

      final url = '${hosts.bpmUrl}humanTask/$taskId';
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };
      
      final payload = {
        'assigned_id': userId,
      };

      logger.i('[TAKE_TASK] PUT $url');
      logger.i('[TAKE_TASK] Payload: $payload');

      final response = await _dio.put(
        url,
        data: jsonEncode(payload),
        options: Options(
          headers: headers,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      logger.i('[TAKE_TASK] Response: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        logger.i('Task taken successfully');
        return true;
      } else {
        logger.w('Failed to take task: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      logger.e('Error calling take task API: $e');
      return false;
    }
  }

  /// Specialized method for uploading files with multipart/form-data
  Future<Map<String, dynamic>?> uploadFile(
    String moduleCode,
    String fileName,
    List<int> fileBytes,
    String userId,
    String userName,
    String recordId,
    String recordCode, {
    String? tabModuleCode,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        print('🔥 [UPLOAD] No user info found');
        return null;
      }

      final url = '${hosts.coreUrl}$moduleCode.DOC?action=UploadFile';

      // Get cookies from saved login (if any)
      List<String> cookies = [];
      final cookiesStr = prefs.getString('session_cookies');
      if (cookiesStr != null && cookiesStr.isNotEmpty) {
        try {
          final dynamic parsed = jsonDecode(cookiesStr);
          if (parsed is List) {
            cookies = parsed.map((e) => e.toString()).toList();
          }
        } catch (_) {
          cookies = [cookiesStr];
        }
      }
      
      // Extract X-Bonita-API-Token from cookies
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            print('🔥 [UPLOAD] bonitaToken extracted: $bonitaToken');
            break;
          }
        }
      }

      // Create FormData for multipart upload
      final Map<String, dynamic> formDataMap = {
        'file': MultipartFile.fromBytes(
          fileBytes,
          filename: fileName,
          contentType: MediaType.parse(_getMimeType(fileName)),
        ),
        'userId': userId,
        'userName': userName,
        'recordId': recordId,
        'recordCode': recordCode,
        'moduleCode': moduleCode,
        'tabModuleCode': 'DOC',
      };
      
      // Add tabModuleCode if provided (for sub-tabs in Documents)
      if (tabModuleCode != null && tabModuleCode.isNotEmpty) {
        formDataMap['tabModuleCode'] = tabModuleCode;
      }
      
      final formData = FormData.fromMap(formDataMap);

      final headers = <String, String>{
        'Content-Type': 'multipart/form-data',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };

      print('🔥 [UPLOAD] POST $url');
      print('🔥 [UPLOAD] File: $fileName (${fileBytes.length} bytes)');
      print('🔥 [UPLOAD] userId: $userId');
      print('🔥 [UPLOAD] userName: $userName');
      print('🔥 [UPLOAD] recordId: $recordId');
      print('🔥 [UPLOAD] recordCode: $recordCode');
      print('🔥 [UPLOAD] moduleCode: $moduleCode');

      final response = await _dio.post(
        url,
        data: formData,
        options: Options(
          headers: headers,
          validateStatus: (status) {
            return status != null && (status == 200 || status == 400);
          },
        ),
      );
      
      // Check if response indicates session expired (401 or specific error)
      if (response.statusCode == 401) {
        print('🔥 [UPLOAD] Session expired (401), returning null to trigger re-login');
        return null;
      }
      
      print('🔥 [UPLOAD] API response (${response.statusCode}): ${response.data}');
      
      // Handle successful responses (200) and client errors (400) that may contain valid data
      if ((response.statusCode == 200 || response.statusCode == 400) && response.data != null) {
        final responseData = response.data is Map<String, dynamic>
            ? response.data
            : jsonDecode(response.data);
            
        // For status 400, still return the data as it may contain messageType info
        if (response.statusCode == 400) {
          print('🔥 [UPLOAD] API returned 400 with data: ${responseData}');
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Unknown error occurred',
              ...responseData,
            };
          }
        }
        
        return responseData;
      }
      return null;
    } catch (e, stack) {
      // Check if error is due to session expiry
      if (e is DioException && e.response?.statusCode == 401) {
        print('🔥 [UPLOAD] Session expired (401 exception), returning null to trigger re-login');
        return null;
      }
      
      // Handle DioException with status 400 (which may contain valid response data)
      if (e is DioException && e.response?.statusCode == 400 && e.response?.data != null) {
        print('🔥 [UPLOAD] DioException 400 with response data: ${e.response?.data}');
        try {
          final responseData = e.response?.data is Map<String, dynamic>
              ? e.response?.data
              : jsonDecode(e.response?.data);
              
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Upload failed',
              ...responseData,
            };
          }
        } catch (parseError) {
          print('🔥 [UPLOAD] Error parsing 400 response data: $parseError');
        }
      }
      
      print('🔥 [UPLOAD] Error uploading file: $e');
      print('🔥 [UPLOAD] Stack trace: $stack');
      return null;
    }
  }

  /// Save action for current tab
  Future<Map<String, dynamic>?> saveData(
    String moduleCode, 
    String tabModuleCode, 
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    final payload = {
      "user": user,
      "itemDetail": itemDetail,
      "moduleCode": moduleCode,
      "tabModuleCode": tabModuleCode,
      "dataSpy": dataSpy,
    };
    
    // Debug log to verify payload structure
    print('🔥 [SAVE DEBUG] Final payload structure:');
    print('🔥 user keys: ${user.keys}');
    print('🔥 itemDetail keys: ${itemDetail.keys}'); 
    print('🔥 dataSpy keys: ${dataSpy.keys}');
    print('🔥 Full payload keys: ${payload.keys}');
    
    final result = await performAction(moduleCode, tabModuleCode, 'SAVE', payload);
    
    // Debug log response structure in detail
    if (result != null) {
      print('🔥 [SAVE RESPONSE] Response keys: ${result.keys}');
      print('🔥 [SAVE RESPONSE] Success: ${result['success']}');
      print('🔥 [SAVE RESPONSE] MessageType: ${result['messageType']}');
      print('🔥 [SAVE RESPONSE] Message: ${result['message']}');
      
      // Check if itemDetail exists and log its structure
      if (result['itemDetail'] != null) {
        print('🔥 [SAVE RESPONSE] ItemDetail exists: ${result['itemDetail'].runtimeType}');
        if (result['itemDetail'] is Map<String, dynamic>) {
          print('🔥 [SAVE RESPONSE] ItemDetail keys: ${(result['itemDetail'] as Map<String, dynamic>).keys}');
          
          // Check if itemDetail.value exists (nested structure)
          if (result['itemDetail']['value'] != null) {
            print('🔥 [SAVE RESPONSE] ItemDetail.value exists: ${result['itemDetail']['value'].runtimeType}');
            if (result['itemDetail']['value'] is Map<String, dynamic>) {
              print('🔥 [SAVE RESPONSE] ItemDetail.value keys: ${(result['itemDetail']['value'] as Map<String, dynamic>).keys}');
            }
          }
        }
      } else {
        print('🔥 [SAVE RESPONSE] ❌ ItemDetail is NULL');
      }
      
      // Check toolbar structure
      if (result['toolbar'] != null) {
        print('🔥 [SAVE RESPONSE] Toolbar exists: ${result['toolbar']}');
      }
      
      // Log the complete response structure for debugging
      print('🔥 [SAVE RESPONSE] Complete response: ${jsonEncode(result)}');
    } else {
      print('🔥 [SAVE RESPONSE] ❌ Result is NULL');
    }
    
    return result;
  }

  /// Submit action for current tab
  Future<Map<String, dynamic>?> submitData(
    String moduleCode, 
    String tabModuleCode, 
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    final payload = {
      "user": user,
      "itemDetail": itemDetail,
      "moduleCode": moduleCode,
      "tabModuleCode": tabModuleCode,
      "dataSpy": dataSpy,
    };
    
    // Debug log to verify payload structure
    print('🔥 [SUBMIT DEBUG] Final payload structure:');
    print('🔥 user keys: ${user.keys}');
    print('🔥 itemDetail keys: ${itemDetail.keys}'); 
    print('🔥 dataSpy keys: ${dataSpy.keys}');
    print('🔥 Full payload keys: ${payload.keys}');
    
    final result = await performAction(moduleCode, tabModuleCode, 'SUBMIT', payload);
    
    // Debug log response structure in detail
    if (result != null) {
      print('🔥 [SUBMIT RESPONSE] Response keys: ${result.keys}');
      print('🔥 [SUBMIT RESPONSE] Success: ${result['success']}');
      print('🔥 [SUBMIT RESPONSE] MessageType: ${result['messageType']}');
      print('🔥 [SUBMIT RESPONSE] Message: ${result['message']}');
      
      // Check if itemDetail exists and log its structure
      if (result['itemDetail'] != null) {
        print('🔥 [SUBMIT RESPONSE] ItemDetail exists: ${result['itemDetail'].runtimeType}');
        if (result['itemDetail'] is Map<String, dynamic>) {
          print('🔥 [SUBMIT RESPONSE] ItemDetail keys: ${(result['itemDetail'] as Map<String, dynamic>).keys}');
          
          // Check if itemDetail.value exists (nested structure)
          if (result['itemDetail']['value'] != null) {
            print('🔥 [SUBMIT RESPONSE] ItemDetail.value exists: ${result['itemDetail']['value'].runtimeType}');
            if (result['itemDetail']['value'] is Map<String, dynamic>) {
              print('🔥 [SUBMIT RESPONSE] ItemDetail.value keys: ${(result['itemDetail']['value'] as Map<String, dynamic>).keys}');
            }
          }
        }
      } else {
        print('🔥 [SUBMIT RESPONSE] ❌ ItemDetail is NULL');
      }
      
      // Check toolbar structure
      if (result['toolbar'] != null) {
        print('🔥 [SUBMIT RESPONSE] Toolbar exists: ${result['toolbar']}');
      }
      
      // Log the complete response structure for debugging
      print('🔥 [SUBMIT RESPONSE] Complete response: ${jsonEncode(result)}');
    } else {
      print('🔥 [SUBMIT RESPONSE] ❌ Result is NULL');
    }
    
    return result;
  }

  /// Copy action for current tab
  Future<Map<String, dynamic>?> copyData(
    String moduleCode, 
    String tabModuleCode, 
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    // Always use 'DTLS' for copyData operations
    final effectiveTabModuleCode = 'DTLS';
    
    final payload = {
      "user": user,
      "itemDetail": itemDetail,
      "moduleCode": moduleCode,
      "tabModuleCode": effectiveTabModuleCode,
      "dataSpy": dataSpy,
    };
    
    // Debug log to verify payload structure
    print('🔥 [COPY DEBUG] Final payload structure:');
    print('🔥 user keys: ${user.keys}');
    print('🔥 itemDetail keys: ${itemDetail.keys}'); 
    print('🔥 dataSpy keys: ${dataSpy.keys}');
    print('🔥 Full payload keys: ${payload.keys}');
    
    final result = await performAction(moduleCode, effectiveTabModuleCode, 'COPY', payload);
    
    // Debug log response structure in detail
    if (result != null) {
      print('🔥 [COPY RESPONSE] Response keys: ${result.keys}');
      print('🔥 [COPY RESPONSE] Success: ${result['success']}');
      print('🔥 [COPY RESPONSE] MessageType: ${result['messageType']}');
      print('🔥 [COPY RESPONSE] Message: ${result['message']}');
      
      // Check if itemDetail exists and log its structure
      if (result['itemDetail'] != null) {
        print('🔥 [COPY RESPONSE] ItemDetail exists: ${result['itemDetail'].runtimeType}');
        if (result['itemDetail'] is Map<String, dynamic>) {
          print('🔥 [COPY RESPONSE] ItemDetail keys: ${(result['itemDetail'] as Map<String, dynamic>).keys}');
          
          // Check if itemDetail.value exists (nested structure)
          if (result['itemDetail']['value'] != null) {
            print('🔥 [COPY RESPONSE] ItemDetail.value exists: ${result['itemDetail']['value'].runtimeType}');
            if (result['itemDetail']['value'] is Map<String, dynamic>) {
              print('🔥 [COPY RESPONSE] ItemDetail.value keys: ${(result['itemDetail']['value'] as Map<String, dynamic>).keys}');
            }
          }
        }
      } else {
        print('🔥 [COPY RESPONSE] ❌ ItemDetail is NULL');
      }
      
      // Check toolbar structure
      if (result['toolbar'] != null) {
        print('🔥 [COPY RESPONSE] Toolbar exists: ${result['toolbar']}');
      }
      
      // Log the complete response structure for debugging
      print('🔥 [COPY RESPONSE] Complete response: ${jsonEncode(result)}');
    } else {
      print('🔥 [COPY RESPONSE] ❌ Result is NULL');
    }
    
    return result;
  }

  /// Cancel action for current tab
  Future<Map<String, dynamic>?> cancelData(
    String moduleCode, 
    String tabModuleCode, 
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    // Always use 'DTLS' for cancelData operations
    final effectiveTabModuleCode = 'DTLS';
    
    final payload = {
      "user": user,
      "itemDetail": itemDetail,
      "moduleCode": moduleCode,
      "tabModuleCode": effectiveTabModuleCode,
      "dataSpy": dataSpy,
    };
    
    // Debug log to verify payload structure
    print('🔥 [CANCEL DEBUG] Final payload structure:');
    print('🔥 user keys: ${user.keys}');
    print('🔥 itemDetail keys: ${itemDetail.keys}'); 
    print('🔥 dataSpy keys: ${dataSpy.keys}');
    print('🔥 Full payload keys: ${payload.keys}');
    
    final result = await performAction(moduleCode, effectiveTabModuleCode, 'CANCEL', payload);
    
    // Debug log response structure in detail
    if (result != null) {
      print('🔥 [CANCEL RESPONSE] Response keys: ${result.keys}');
      print('🔥 [CANCEL RESPONSE] Success: ${result['success']}');
      print('🔥 [CANCEL RESPONSE] MessageType: ${result['messageType']}');
      print('🔥 [CANCEL RESPONSE] Message: ${result['message']}');
      
      // Check if itemDetail exists and log its structure
      if (result['itemDetail'] != null) {
        print('🔥 [CANCEL RESPONSE] ItemDetail exists: ${result['itemDetail'].runtimeType}');
        if (result['itemDetail'] is Map<String, dynamic>) {
          print('🔥 [CANCEL RESPONSE] ItemDetail keys: ${(result['itemDetail'] as Map<String, dynamic>).keys}');
          
          // Check if itemDetail.value exists (nested structure)
          if (result['itemDetail']['value'] != null) {
            print('🔥 [CANCEL RESPONSE] ItemDetail.value exists: ${result['itemDetail']['value'].runtimeType}');
            if (result['itemDetail']['value'] is Map<String, dynamic>) {
              print('🔥 [CANCEL RESPONSE] ItemDetail.value keys: ${(result['itemDetail']['value'] as Map<String, dynamic>).keys}');
            }
          }
        }
      } else {
        print('🔥 [CANCEL RESPONSE] ❌ ItemDetail is NULL');
      }
      
      // Check toolbar structure
      if (result['toolbar'] != null) {
        print('🔥 [CANCEL RESPONSE] Toolbar exists: ${result['toolbar']}');
      }
      
      // Log the complete response structure for debugging
      print('🔥 [CANCEL RESPONSE] Complete response: ${jsonEncode(result)}');
    } else {
      print('🔥 [CANCEL RESPONSE] ❌ Result is NULL');
    }
    
    return result;
  }

  /// Delete action for current tab
  Future<Map<String, dynamic>?> deleteData(
    String moduleCode, 
    String tabModuleCode, 
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
  ) async {
    // Always use 'DTLS' for deleteData operations
    final effectiveTabModuleCode = 'DTLS';
    
    final payload = {
      "user": user,
      "listItem": itemDetail['value'] ?? itemDetail, // Use itemDetail.value as listItem
      "moduleCode": moduleCode,
      "tabModuleCode": effectiveTabModuleCode,
      "dataSpy": dataSpy,
    };
    
    // Debug log to verify payload structure
    print('🔥 [DELETE DEBUG] Final payload structure:');
    print('🔥 user keys: ${user.keys}');
    print('🔥 listItem keys: ${(itemDetail['value'] ?? itemDetail).keys}'); 
    print('🔥 dataSpy keys: ${dataSpy.keys}');
    print('🔥 Full payload keys: ${payload.keys}');
    
    final result = await performAction(moduleCode, effectiveTabModuleCode, 'DELETE', payload);
    
    // Debug log response structure in detail
    if (result != null) {
      print('🔥 [DELETE RESPONSE] Response keys: ${result.keys}');
      print('🔥 [DELETE RESPONSE] Success: ${result['success']}');
      print('🔥 [DELETE RESPONSE] MessageType: ${result['messageType']}');
      print('🔥 [DELETE RESPONSE] Message: ${result['message']}');
      
      // Check if itemDetail exists and log its structure
      if (result['itemDetail'] != null) {
        print('🔥 [DELETE RESPONSE] ItemDetail exists: ${result['itemDetail'].runtimeType}');
        if (result['itemDetail'] is Map<String, dynamic>) {
          print('🔥 [DELETE RESPONSE] ItemDetail keys: ${(result['itemDetail'] as Map<String, dynamic>).keys}');
          
          // Check if itemDetail.value exists (nested structure)
          if (result['itemDetail']['value'] != null) {
            print('🔥 [DELETE RESPONSE] ItemDetail.value exists: ${result['itemDetail']['value'].runtimeType}');
            if (result['itemDetail']['value'] is Map<String, dynamic>) {
              print('🔥 [DELETE RESPONSE] ItemDetail.value keys: ${(result['itemDetail']['value'] as Map<String, dynamic>).keys}');
            }
          }
        }
      } else {
        print('🔥 [DELETE RESPONSE] ❌ ItemDetail is NULL');
      }
      
      // Check toolbar structure
      if (result['toolbar'] != null) {
        print('🔥 [DELETE RESPONSE] Toolbar exists: ${result['toolbar']}');
      }
      
      // Log the complete response structure for debugging
      print('🔥 [DELETE RESPONSE] Complete response: ${jsonEncode(result)}');
    } else {
      print('🔥 [DELETE RESPONSE] ❌ Result is NULL');
    }
    
    return result;
  }

  /// Delete item directly from list (swipe to delete)
  Future<Map<String, dynamic>?> deleteItemFromList(
    String moduleCode,
    Map<String, dynamic> user,
    Map<String, dynamic> listItem,
    Map<String, dynamic> dataSpy,
  ) async {
    // Always use 'DTLS' for deleteData operations from list
    const effectiveTabModuleCode = 'DTLS';
    
    final payload = {
      "user": user,
      "listItem": listItem, // Direct listItem value
      "moduleCode": moduleCode,
      "tabModuleCode": effectiveTabModuleCode,
      "dataSpy": dataSpy,
    };
    
    // Debug log to verify payload structure
    print('🔥 [DELETE LIST ITEM DEBUG] Final payload structure:');
    print('🔥 user keys: ${user.keys}');
    print('🔥 listItem keys: ${listItem.keys}'); 
    print('🔥 dataSpy keys: ${dataSpy.keys}');
    print('🔥 Full payload keys: ${payload.keys}');
    
    final result = await performAction(moduleCode, effectiveTabModuleCode, 'DELETE', payload);
    
    // Debug log response structure in detail
    if (result != null) {
      print('🔥 [DELETE LIST ITEM RESPONSE] Response keys: ${result.keys}');
      print('🔥 [DELETE LIST ITEM RESPONSE] Success: ${result['success']}');
      print('🔥 [DELETE LIST ITEM RESPONSE] MessageType: ${result['messageType']}');
      print('🔥 [DELETE LIST ITEM RESPONSE] Message: ${result['message']}');
      
      // Log the complete response structure for debugging
      print('🔥 [DELETE LIST ITEM RESPONSE] Complete response: ${jsonEncode(result)}');
    } else {
      print('🔥 [DELETE LIST ITEM RESPONSE] ❌ Result is NULL');
    }
    
    return result;
  }

  /// Task approval/rejection action with SUBMIT_FORM action
  Future<Map<String, dynamic>?> performTaskAction(
    String moduleCode, 
    String tabModuleCode, 
    Map<String, dynamic> user,
    Map<String, dynamic> itemDetail,
    Map<String, dynamic> dataSpy,
    String taskId,
    bool isApproved,
  ) async {
    // Create payload with special task-specific fields
    final payload = {
      "user": user,
      "itemDetail": itemDetail,
      "moduleCode": moduleCode,
      "tabModuleCode": tabModuleCode,
      "dataSpy": dataSpy,
      "isApproved": isApproved,
      "taskId": taskId,
    };
    
    // Debug log to verify payload structure
    print('🔥 [TASK ACTION DEBUG] Final payload structure:');
    print('🔥 user keys: ${user.keys}');
    print('🔥 itemDetail keys: ${itemDetail.keys}'); 
    print('🔥 dataSpy keys: ${dataSpy.keys}');
    print('🔥 isApproved: $isApproved');
    print('🔥 taskId: $taskId');
    print('🔥 Full payload keys: ${payload.keys}');
    
    final result = await performAction(moduleCode, tabModuleCode, 'SUBMIT_FORM', payload);
    
    // Debug log response structure in detail
    if (result != null) {
      print('🔥 [TASK ACTION RESPONSE] Response keys: ${result.keys}');
      print('🔥 [TASK ACTION RESPONSE] Success: ${result['success']}');
      print('🔥 [TASK ACTION RESPONSE] MessageType: ${result['messageType']}');
      print('🔥 [TASK ACTION RESPONSE] Message: ${result['message']}');
      
      // Check if itemDetail exists and log its structure
      if (result['itemDetail'] != null) {
        print('🔥 [TASK ACTION RESPONSE] ItemDetail exists: ${result['itemDetail'].runtimeType}');
        if (result['itemDetail'] is Map<String, dynamic>) {
          print('🔥 [TASK ACTION RESPONSE] ItemDetail keys: ${(result['itemDetail'] as Map<String, dynamic>).keys}');
          
          // Check if itemDetail.value exists (nested structure)
          if (result['itemDetail']['value'] != null) {
            print('🔥 [TASK ACTION RESPONSE] ItemDetail.value exists: ${result['itemDetail']['value'].runtimeType}');
            if (result['itemDetail']['value'] is Map<String, dynamic>) {
              print('🔥 [TASK ACTION RESPONSE] ItemDetail.value keys: ${(result['itemDetail']['value'] as Map<String, dynamic>).keys}');
            }
          }
        }
      } else {
        print('🔥 [TASK ACTION RESPONSE] ❌ ItemDetail is NULL');
      }
      
      // Check toolbar structure
      if (result['toolbar'] != null) {
        print('🔥 [TASK ACTION RESPONSE] Toolbar exists: ${result['toolbar']}');
      }
      
      // Log the complete response structure for debugging
      print('🔥 [TASK ACTION RESPONSE] Complete response: ${jsonEncode(result)}');
    } else {
      print('🔥 [TASK ACTION RESPONSE] ❌ Result is NULL');
    }
    
    return result;
  }

  /// Generic method to fetch dropdown data using GET request
  Future<Map<String, dynamic>> getDropdownData(String endpoint) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        logger.e('No user info found');
        return {'success': false, 'message': 'No user info found'};
      }
      
      final url = '${hosts.coreUrl}$endpoint';

      // Get cookies from saved login (if any)
      List<String> cookies = [];
      final cookiesStr = prefs.getString('session_cookies');
      if (cookiesStr != null && cookiesStr.isNotEmpty) {
        try {
          final dynamic parsed = jsonDecode(cookiesStr);
          if (parsed is List) {
            cookies = parsed.map((e) => e.toString()).toList();
          }
        } catch (_) {
          cookies = [cookiesStr];
        }
      }
      
      // Extract X-Bonita-API-Token from cookies
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            break;
          }
        }
      }
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };

      logger.i('[DEBUG] GET $url');
      logger.i('[DEBUG] Headers: $headers');

      final response = await _dio.get(
        url,
        options: Options(headers: headers),
      );
      
      if (response.statusCode == 401) {
        logger.w('Session expired (401), returning error');
        return {'success': false, 'message': 'Session expired'};
      }
      
      logger.i('CoreService Dropdown API response: ${response.data}');
      if (response.statusCode == 200 && response.data != null) {
        // Handle different response types
        dynamic data;
        if (response.data is List) {
          // API returned a List directly
          data = response.data;
        } else if (response.data is Map<String, dynamic>) {
          // API returned a Map directly
          data = response.data;
        } else if (response.data is String) {
          // API returned a JSON string that needs to be decoded
          try {
            data = jsonDecode(response.data);
          } catch (e) {
            logger.e('Error decoding JSON response: $e');
            return {'success': false, 'message': 'Invalid JSON response'};
          }
        } else {
          // Unknown response type
          data = response.data;
        }
        
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': 'No data received'};
    } catch (e, stack) {
      if (e is DioException && e.response?.statusCode == 401) {
        logger.w('Session expired (401 exception)');
        return {'success': false, 'message': 'Session expired'};
      }
      logger.e('Error making dropdown API call to $endpoint: $e', stackTrace: stack);
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Generic method to make API calls with session cookies and authentication
  Future<Map<String, dynamic>?> _makeApiCall(String endpoint, Map<String, dynamic> payload) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        logger.e('No user info found');
        return null;
      }
      final url = '${hosts.coreUrl}$endpoint';

      // Get cookies from saved login (if any)
      List<String> cookies = [];
      final cookiesStr = prefs.getString('session_cookies');
      if (cookiesStr != null && cookiesStr.isNotEmpty) {
        try {
          final dynamic parsed = jsonDecode(cookiesStr);
          if (parsed is List) {
            cookies = parsed.map((e) => e.toString()).toList();
          }
        } catch (_) {
          cookies = [cookiesStr];
        }
      }
      
      // Extract X-Bonita-API-Token from cookies
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          // Only get the part before ; if any
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            logger.i('[DEBUG] bonitaToken extracted from cookie: $bonitaToken');
            break;
          }
        }
      }
      
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };

      final bool isActionCall = endpoint.contains('?action=');


      // For action calls, log full payload + compact tree info for debugging
      if (isActionCall) {
        _logJson('[DEBUG] Payload (action)', payload);
        try {
          final Map<String, dynamic> itemDetail = (payload['itemDetail'] as Map?)?.cast<String, dynamic>() ?? {};
          final dynamic treeContainer = itemDetail['tree'] ?? ((itemDetail['value'] is Map) ? (itemDetail['value'] as Map)['tree'] : null);
          dynamic treeData;
          if (treeContainer is Map) {
            treeData = treeContainer['data'];
          } else if (treeContainer is List) {
            treeData = treeContainer;
          }
          logger.i('[ACTION PAYLOAD] itemDetail.tree.data: ${jsonEncode(treeData)}');
        } catch (e) {
          logger.w('[ACTION PAYLOAD] Unable to extract tree payload: $e');
        }
      }

      // Normalize itemDetail.tree so server always receives latest tree changes
      try {
        if (payload['itemDetail'] is Map) {
          final id = payload['itemDetail'] as Map;
          dynamic tree = id['tree'];
          if (tree == null && id['value'] is Map) {
            final v = id['value'] as Map;
            if (v['tree'] != null) tree = v['tree'];
          }
          if (tree != null) {
            if (tree is List) {
              id['tree'] = {'data': tree};
            } else if (tree is Map) {
              // Ensure data exists as list if children provided
              id['tree'] = tree;
            }
          }
        }
      } catch (_) {
        // ignore normalization errors
      }

      final response = await _dio.post(
        url,
        data: jsonEncode(payload),
        options: Options(
          headers: headers,
          validateStatus: (status) {
            // Accept 200 and 400 as before; 401/500 will be handled in catch as DioException
            return status != null && (status == 200 || status == 400);
          },
        ),
      );

      // Check if response indicates session expired (401 or specific error)
      if (response.statusCode == 401) {
        logger.w('Session expired (401), returning null to trigger re-login');
        return null;
      }

      // Only log response for non-action calls; for actions keep logs minimal (payload tree.data only)
      if (!isActionCall) {
        logger.i('CoreService API response (${response.statusCode}): ${response.data}');
        _logJson('CoreService response JSON', response.data);
      }
      
      // Handle successful responses (200) and client errors (400) that may contain valid data
      if ((response.statusCode == 200 || response.statusCode == 400) && response.data != null) {
        final responseData = response.data is Map<String, dynamic>
            ? response.data
            : jsonDecode(response.data);
            
        // For status 400, still return the data as it may contain messageType info
        if (response.statusCode == 400) {
          logger.w('API returned 400 with data: ${responseData}');
          // Ensure we have proper structure for error responses
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Unknown error occurred',
              ...responseData, // Include any additional fields
            };
          }
        }
        
        return responseData;
      }
      return null;
    } catch (e, stack) {
      // Check if error is due to session expiry
      if (e is DioException) {
        final status = e.response?.statusCode;
        if (status == 401) {
          logger.w('Session expired (401 exception), returning null to trigger re-login');
          return null;
        }
        
        // Handle DioException with status 400 (which may contain valid response data)
        if (status == 400 && e.response?.data != null) {
          logger.w('DioException 400 with response data: ${e.response?.data}');
          try {
            final responseData = e.response?.data is Map<String, dynamic>
                ? e.response?.data
                : jsonDecode(e.response?.data);
                
            if (responseData is Map<String, dynamic>) {
              return {
                'success': responseData['success'] ?? false,
                'messageType': responseData['messageType'] ?? 'error',
                'message': responseData['message'] ?? 'Request failed',
                ...responseData, // Include any additional fields
              };
            }
          } catch (parseError) {
            logger.e('Error parsing 400 response data: $parseError');
          }
        }

        // NEW: Treat 5xx as generic server error (do NOT trigger session expired)
        if (status != null && status >= 500) {
          logger.e('Server error ($status) making API call to $endpoint: ${e.message}');
          return {
            'success': false,
            'messageType': 'error',
            'message': 'Server error. Please try again later.',
            'statusCode': status,
          };
        }

        // NEW: Network or unknown Dio error (no status)
        if (status == null) {
          logger.e('Network error making API call to $endpoint: ${e.message}');
          return {
            'success': false,
            'messageType': 'error',
            'message': 'Network error. Please check your connection and try again.',
          };
        }
      }
      
      logger.e('Error making API call to $endpoint: $e', stackTrace: stack);
      // Do not treat as session expired; return a generic error map
      return {
        'success': false,
        'messageType': 'error',
        'message': 'Unexpected error. Please try again.',
      };
    }
  }

  /// Download file with proper headers and payload structure
  /// Returns response with file data
  static Future<Map<String, dynamic>?> downloadFile(
    String moduleCode,
    Map<String, dynamic> userInfo,
    Map<String, dynamic> fileData,
  ) async {
    try {
      print('🔥 [CoreService] downloadFile start');
      print('🔥 [CoreService] moduleCode: $moduleCode');
      print('🔥 [CoreService] userInfo: $userInfo');
      print('🔥 [CoreService] fileData: $fileData');
      
      // Get session data
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        print('🔥 [DOWNLOAD] No user info found');
        return null;
      }

      // Get cookies from saved login (if any)
      List<String> cookies = [];
      final cookiesStr = prefs.getString('session_cookies');
      if (cookiesStr != null && cookiesStr.isNotEmpty) {
        try {
          final dynamic parsed = jsonDecode(cookiesStr);
          if (parsed is List) {
            cookies = parsed.map((e) => e.toString()).toList();
          }
        } catch (_) {
          cookies = [cookiesStr];
        }
      }
      
      // Extract X-Bonita-API-Token from cookies
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            print('🔥 [DOWNLOAD] bonitaToken extracted: $bonitaToken');
            break;
          }
        }
      }
      
      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };
      
      // Build payload
      final payload = {
        'user': {
          'id': userInfo['id'],
          'code': userInfo['code'],
          'fullName': userInfo['fullName'],
          'phone': userInfo['phone'],
          'email': userInfo['email'],
          'personalEmail': userInfo['personalEmail'],
          'position': userInfo['position'],
          'createdDate': userInfo['createdDate'],
          'managerFullName': userInfo['managerFullName'],
          'roles': userInfo['roles'] ?? [],
        },
        'moduleCode': moduleCode,
        'tabModuleCode': 'DOC',
        'file': fileData,
      };
      
      print('🔥 [CoreService] downloadFile headers: $headers');
      print('🔥 [CoreService] downloadFile payload: $payload');
      
      // Make API call
      final url = '${hosts.coreUrl}$moduleCode.DOC?action=DownloadFile';
      print('🔥 [CoreService] downloadFile URL: $url');
      
      final response = await Dio().post(
        url,
        data: payload,
        options: Options(
          headers: headers,
          validateStatus: (status) {
            return status != null && (status == 200 || status == 400);
          },
        ),
      );
      
      // Check if response indicates session expired (401 or specific error)
      if (response.statusCode == 401) {
        print('🔥 [DOWNLOAD] Session expired (401), returning null to trigger re-login');
        return null;
      }
      
      print('🔥 [CoreService] downloadFile response status: ${response.statusCode}');
      print('🔥 [CoreService] downloadFile response data: ${response.data}');
      
      // Handle successful responses (200) and client errors (400) that may contain valid data
      if ((response.statusCode == 200 || response.statusCode == 400) && response.data != null) {
        final responseData = response.data is Map<String, dynamic>
            ? response.data
            : jsonDecode(response.data);
            
        // For status 400, still return the data as it may contain messageType info
        if (response.statusCode == 400) {
          print('🔥 [DOWNLOAD] API returned 400 with data: ${responseData}');
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Download failed',
              ...responseData,
            };
          }
        }
        
        return responseData;
      }
      return null;
    } catch (e) {
      // Check if error is due to session expiry
      if (e is DioException && e.response?.statusCode == 401) {
        print('🔥 [DOWNLOAD] Session expired (401 exception), returning null to trigger re-login');
        return null;
      }
      
      // Handle DioException with status 400 (which may contain valid response data)
      if (e is DioException && e.response?.statusCode == 400 && e.response?.data != null) {
        print('🔥 [DOWNLOAD] DioException 400 with response data: ${e.response?.data}');
        try {
          final responseData = e.response?.data is Map<String, dynamic>
              ? e.response?.data
              : jsonDecode(e.response?.data);
              
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Download failed',
              ...responseData,
            };
          }
        } catch (parseError) {
          print('🔥 [DOWNLOAD] Error parsing 400 response data: $parseError');
        }
      }
      
      print('🔥 [CoreService] downloadFile error: $e');
      throw e;
    }
  }

  /// Delete file with proper headers and payload structure
  /// Returns response similar to module tab load
  static Future<Map<String, dynamic>?> deleteFile(
    String moduleCode,
    Map<String, dynamic> userInfo,
    Map<String, dynamic> fileData,
  ) async {
    try {
      print('🔥 [CoreService] deleteFile start');
      print('🔥 [CoreService] moduleCode: $moduleCode');
      print('🔥 [CoreService] userInfo: $userInfo');
      print('🔥 [CoreService] fileData: $fileData');
      
      // Get session data
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        print('🔥 [DELETE] No user info found');
        return null;
      }

      // Get cookies from saved login (if any)
      List<String> cookies = [];
      final cookiesStr = prefs.getString('session_cookies');
      if (cookiesStr != null && cookiesStr.isNotEmpty) {
        try {
          final dynamic parsed = jsonDecode(cookiesStr);
          if (parsed is List) {
            cookies = parsed.map((e) => e.toString()).toList();
          }
        } catch (_) {
          cookies = [cookiesStr];
        }
      }
      
      // Extract X-Bonita-API-Token from cookies
      String? bonitaToken;
      if (cookies.isNotEmpty) {
        for (final c in cookies) {
          final cookiePair = c.split(';')[0];
          final parts = cookiePair.split('=');
          if (parts.length == 2 && parts[0].trim() == 'X-Bonita-API-Token') {
            bonitaToken = parts[1];
            print('🔥 [DELETE] bonitaToken extracted: $bonitaToken');
            break;
          }
        }
      }
      
      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (bonitaToken != null) 'X-Bonita-API-Token': bonitaToken,
        if (cookies.isNotEmpty) 'cookie': cookies.join('; '),
      };
      
      // Build payload
      final payload = {
        'user': {
          'id': userInfo['id'],
          'code': userInfo['code'],
          'fullName': userInfo['fullName'],
          'phone': userInfo['phone'],
          'email': userInfo['email'],
          'personalEmail': userInfo['personalEmail'],
          'position': userInfo['position'],
          'createdDate': userInfo['createdDate'],
          'managerFullName': userInfo['managerFullName'],
          'roles': userInfo['roles'] ?? [],
        },
        'moduleCode': moduleCode,
        'tabModuleCode': 'DOC',
        'file': fileData,
      };
      
      print('🔥 [CoreService] deleteFile headers: $headers');
      print('🔥 [CoreService] deleteFile payload: $payload');
      
      // Make API call
      final url = '${hosts.coreUrl}$moduleCode.DOC?action=DeleteFile';
      print('🔥 [CoreService] deleteFile URL: $url');
      
      final response = await Dio().post(
        url,
        data: payload,
        options: Options(
          headers: headers,
          validateStatus: (status) {
            return status != null && (status == 200 || status == 400);
          },
        ),
      );
      
      // Check if response indicates session expired (401 or specific error)
      if (response.statusCode == 401) {
        print('🔥 [DELETE] Session expired (401), returning null to trigger re-login');
        return null;
      }
      
      print('🔥 [CoreService] deleteFile response status: ${response.statusCode}');
      print('🔥 [CoreService] deleteFile response data: ${response.data}');
      
      // Handle successful responses (200) and client errors (400) that may contain valid data
      if ((response.statusCode == 200 || response.statusCode == 400) && response.data != null) {
        final responseData = response.data is Map<String, dynamic>
            ? response.data
            : jsonDecode(response.data);
            
        // For status 400, still return the data as it may contain messageType info
        if (response.statusCode == 400) {
          print('🔥 [DELETE] API returned 400 with data: ${responseData}');
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Delete failed',
              ...responseData,
            };
          }
        }
        
        return responseData;
      }
      return null;
    } catch (e) {
      // Check if error is due to session expiry
      if (e is DioException && e.response?.statusCode == 401) {
        print('🔥 [DELETE] Session expired (401 exception), returning null to trigger re-login');
        return null;
      }
      
      // Handle DioException with status 400 (which may contain valid response data)
      if (e is DioException && e.response?.statusCode == 400 && e.response?.data != null) {
        print('🔥 [DELETE] DioException 400 with response data: ${e.response?.data}');
        try {
          final responseData = e.response?.data is Map<String, dynamic>
              ? e.response?.data
              : jsonDecode(e.response?.data);
              
          if (responseData is Map<String, dynamic>) {
            return {
              'success': responseData['success'] ?? false,
              'messageType': responseData['messageType'] ?? 'error',
              'message': responseData['message'] ?? 'Delete failed',
              ...responseData,
            };
          }
        } catch (parseError) {
          print('🔥 [DELETE] Error parsing 400 response data: $parseError');
        }
      }
      
      print('🔥 [CoreService] deleteFile error: $e');
      throw e;
    }
  }

  /// Get MIME type based on file extension
  String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      // Documents
      case 'pdf':
        return 'application/pdf';
      case 'rtf':
        return 'application/rtf';
      case 'epub':
        return 'application/epub+zip';

      // Word
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'docm':
        return 'application/vnd.ms-word.document.macroEnabled.12';
      case 'dot':
        return 'application/msword';
      case 'dotx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.template';
      case 'dotm':
        return 'application/vnd.ms-word.template.macroEnabled.12';

      // Excel
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xlsm':
        return 'application/vnd.ms-excel.sheet.macroEnabled.12';
      case 'xltx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.template';
      case 'xltm':
        return 'application/vnd.ms-excel.template.macroEnabled.12';
      case 'xlam':
        return 'application/vnd.ms-excel.addin.macroEnabled.12';
      case 'xlsb':
        return 'application/vnd.ms-excel.sheet.binary.macroEnabled.12';
      case 'csv':
        return 'text/csv';
      case 'tsv':
        return 'text/tab-separated-values';

      // PowerPoint
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'pptm':
        return 'application/vnd.ms-powerpoint.presentation.macroEnabled.12';
      case 'potx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.template';
      case 'potm':
        return 'application/vnd.ms-powerpoint.template.macroEnabled.12';
      case 'pps':
        return 'application/vnd.ms-powerpoint';
      case 'ppsx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.slideshow';
      case 'ppsm':
        return 'application/vnd.ms-powerpoint.slideshow.macroEnabled.12';

      // OpenDocument formats
      case 'odt':
        return 'application/vnd.oasis.opendocument.text';
      case 'ott':
        return 'application/vnd.oasis.opendocument.text-template';
      case 'ods':
        return 'application/vnd.oasis.opendocument.spreadsheet';
      case 'ots':
        return 'application/vnd.oasis.opendocument.spreadsheet-template';
      case 'odp':
        return 'application/vnd.oasis.opendocument.presentation';
      case 'otp':
        return 'application/vnd.oasis.opendocument.presentation-template';

      // Images
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'bmp':
        return 'image/bmp';
      case 'tiff':
      case 'tif':
        return 'image/tiff';
      case 'webp':
        return 'image/webp';
      case 'svg':
      case 'svgz':
        return 'image/svg+xml';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'ico':
        return 'image/x-icon';

      // Text / Markup / Code
      case 'txt':
        return 'text/plain';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'html':
      case 'htm':
        return 'text/html';
      case 'md':
      case 'markdown':
        return 'text/markdown';
      case 'yaml':
      case 'yml':
        return 'application/x-yaml';
      case 'ini':
      case 'log':
        return 'text/plain';
      case 'css':
        return 'text/css';
      case 'js':
        return 'application/javascript';

      // Archives / Compressed
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/vnd.rar';
      case '7z':
        return 'application/x-7z-compressed';
      case 'tar':
        return 'application/x-tar';
      case 'gz':
        return 'application/gzip';
      case 'tgz':
        return 'application/gzip';
      case 'bz2':
        return 'application/x-bzip2';
      case 'xz':
        return 'application/x-xz';

      // Audio
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'm4a':
        return 'audio/mp4';
      case 'ogg':
        return 'audio/ogg';
      case 'flac':
        return 'audio/flac';
      case 'aac':
        return 'audio/aac';

      // Video
      case 'mp4':
        return 'video/mp4';
      case 'm4v':
        return 'video/x-m4v';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      case 'mkv':
        return 'video/x-matroska';
      case 'webm':
        return 'video/webm';

      default:
        return 'application/octet-stream';
    }
  }

  // Pretty-print large JSON and log in chunks to avoid truncation
  void _logJson(String title, dynamic data, {int chunkSize = 800}) {
    try {
      final pretty = const JsonEncoder.withIndent('  ').convert(data);
      _logInChunks(title, pretty, chunkSize: chunkSize);
    } catch (_) {
      // Fallback to raw
      final raw = data is String ? data : data.toString();
      _logInChunks(title, raw, chunkSize: chunkSize);
    }
  }

  void _logInChunks(String title, String text, {int chunkSize = 800}) {
    if (text.isEmpty) {
      logger.i('$title: <empty>');
      return;
    }
    final total = (text.length / chunkSize).ceil();
    for (int i = 0; i < total; i++) {
      final start = i * chunkSize;
      final end = math.min(start + chunkSize, text.length);
      final part = text.substring(start, end);
      final prefix = total > 1 ? '$title [${i + 1}/$total]' : title;
      logger.i('$prefix: $part');
    }
  }
}
