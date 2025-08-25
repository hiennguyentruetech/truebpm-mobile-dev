import 'package:flutter/foundation.dart';
import 'package:truebpm/models/menu_model.dart';
import 'package:truebpm/models/user_model.dart';
import 'package:truebpm/services/menu_service.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/di/service_locator.dart';
// import 'package:truebpm/utils/global_store.dart';

class MenuProvider with ChangeNotifier {
  final MenuService _menuService = MenuService();
  late final AuthService _authService;
  
  List<MenuModel> _menuData = [];
  UserModel? _currentUser;
  bool _isLoading = true;
  String? _error;

  // Getters
  List<MenuModel> get menuData => _menuData;
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMenuData => _menuData.isNotEmpty;

  MenuProvider() {
    _authService = get<AuthService>();
    loadData();
  }

  Future<void> loadData() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Load user info
      _currentUser = await _authService.getSavedUserInfo();

      // Always fetch menu from API (no cache)
      _menuData = await _menuService.fetchMenuData();

      _setLoading(false);
    } catch (e) {
      // logger.e('Error loading menu data: $e');
      _setError('Lỗi khi tải dữ liệu menu: $e');
      _setLoading(false);
    }
  }

  Future<void> refreshData() async {
    await loadData();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  void updateMenuExpansion() {
    // Trigger rebuild when menu expansion changes
    notifyListeners();
  }
}
