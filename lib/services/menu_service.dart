import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:truebpm/utils/global_store.dart';
import 'package:truebpm/utils/exceptions.dart';
import 'package:truebpm/models/menu_model.dart';
import 'package:truebpm/models/user_model.dart';

class MenuService {
  final Dio _dio = Dio();
  static const String _keyMenuData = 'menu_data';

  /// Fetch menu data from API with session cookies
  Future<List<MenuModel>> fetchMenuData() async {
    try {
      // Get user info to extract userId
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString('user_info');
      if (userJsonStr == null) {
        // logger.e('No user info found');
        return [];
      }

      final user = UserModel.fromJson(jsonDecode(userJsonStr));
      final url = '${hosts.coreUrl}MENU.SHOW?userId=${user.id}&applicationId=304';

      // Get cookies from saved login (if any) - compatible with how AuthService saves cookies
      List<String> cookies = [];
      final cookiesStr = prefs.getString('session_cookies');
      if (cookiesStr != null && cookiesStr.isNotEmpty) {
        try {
          final dynamic parsed = jsonDecode(cookiesStr);
          if (parsed is List) {
            cookies = parsed.map((e) => e.toString()).toList();
          }
        } catch (_) {
          // fallback: single cookie string
          cookies = [cookiesStr];
        }
      }
      Map<String, String> headers = {};
      if (cookies.isNotEmpty) {
        headers['cookie'] = cookies.join('; ');
      }

      // logger.i('Fetching menu from: $url');
      final response = await _dio.get(
        url,
        options: Options(headers: headers),
      );

      // logger.i('Menu API response status: ${response.statusCode}');

      if (response.statusCode == 401) {
        // Session expired - throw authentication exception
        // logger.w('Session expired (401) - authentication required');
        throw AuthenticationException('Session expired. Please login again.');
      }

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> menuJson = response.data;
        final menuList = menuJson.map((json) => MenuModel.fromJson(json)).toList();
        // Build menu hierarchy
        final hierarchicalMenu = _buildMenuHierarchy(menuList);
        // Save to local storage
        await _saveMenuData(hierarchicalMenu);
        // logger.i('Menu data fetched and saved successfully');
        return hierarchicalMenu;
      } else {
        // logger.w('Failed to fetch menu data: ${response.statusCode}');
        return [];
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Session expired - throw authentication exception
        // logger.w('Session expired (401) - authentication required');
        throw AuthenticationException('Session expired. Please login again.');
      }
      // logger.e('Dio error fetching menu data: ${e.message}');
      rethrow;
    } catch (e) {
      // logger.e('Error fetching menu data: $e');
      rethrow;
    }
  }

  /// Build hierarchical menu structure
  List<MenuModel> _buildMenuHierarchy(List<MenuModel> flatMenu) {
    // Create a map for quick lookup
    final Map<String, MenuModel> menuMap = {};
    for (final menu in flatMenu) {
      menuMap[menu.id] = menu;
    }

    // Build hierarchy
    final List<MenuModel> rootMenus = [];
    for (final menu in flatMenu) {
      if (menu.parentMenuId == "-1") {
        rootMenus.add(menu);
      } else {
        final parent = menuMap[menu.parentMenuId];
        if (parent != null) {
          parent.children.add(menu);
        }
      }
    }

    // Sort by menuIndex
    rootMenus.sort((a, b) => int.parse(a.menuIndex).compareTo(int.parse(b.menuIndex)));
    for (final menu in rootMenus) {
      menu.children.sort((a, b) => int.parse(a.menuIndex).compareTo(int.parse(b.menuIndex)));
    }

    return rootMenus;
  }

  /// Save menu data to local storage
  Future<void> _saveMenuData(List<MenuModel> menuData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = menuData.map((menu) => menu.toJson()).toList();
      await prefs.setString(_keyMenuData, jsonEncode(jsonData));
    } catch (e) {
      // logger.e('Error saving menu data: $e');
    }
  }

  /// Get saved menu data from local storage
  Future<List<MenuModel>> getSavedMenuData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_keyMenuData);
      if (jsonStr != null) {
        final List<dynamic> jsonData = jsonDecode(jsonStr);
        return jsonData.map((json) => MenuModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // logger.e('Error getting saved menu data: $e');
      return [];
    }
  }

  /// Clear saved menu data
  Future<void> clearMenuData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyMenuData);
      // logger.i('Menu data cleared');
    } catch (e) {
      // logger.e('Error clearing menu data: $e');
    }
  }
}
