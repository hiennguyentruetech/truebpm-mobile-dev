import 'package:flutter/material.dart';
import 'package:truebpm/services/menu_service.dart';
import 'package:truebpm/services/auth_service.dart';
import 'package:truebpm/navigation/app_routes.dart';
import 'package:truebpm/navigation/navigation_service.dart';
import 'package:truebpm/utils/exceptions.dart';
import 'package:truebpm/models/menu_model.dart';
import 'package:truebpm/models/user_model.dart';
import 'package:truebpm/utils/global_store.dart';
import 'package:truebpm/di/service_locator.dart';
import 'package:truebpm/widgets/menu/index.dart';
import 'package:truebpm/widgets/dialogs/custom_confirm_dialog.dart';

class ListMenuScreen extends StatefulWidget {
  const ListMenuScreen({super.key});

  @override
  State<ListMenuScreen> createState() => _ListMenuScreenState();
}

class _ListMenuScreenState extends State<ListMenuScreen> with TickerProviderStateMixin {
  final MenuService _menuService = MenuService();
  late final AuthService _authService;
  List<MenuModel> _menuData = [];
  UserModel? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _authService = get<AuthService>();
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Load user info
      _currentUser = await _authService.getSavedUserInfo();

      // Always fetch menu from API (no cache)
      _menuData = await _menuService.fetchMenuData();

      setState(() => _isLoading = false);
    } on AuthenticationException catch (e) {
      logger.e('Authentication error loading menu: ${e.message}');
      setState(() => _isLoading = false);

      // Show session expired dialog and redirect to login
      if (mounted) {
        _showSessionExpiredDialog();
      }
    } catch (e) {
      // logger.e('Error loading menu data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showSessionExpiredDialog() {
    CustomConfirmDialog.showSessionExpired(
      context,
      onConfirm: () async {
        await _authService.clearSavedCredentials();
        NavigationService.replaceAllWith(AppRoutes.login);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: Colors.teal,
        backgroundColor: Colors.white,
        strokeWidth: 3,
        displacement: 80,
        child: CustomScrollView(
          slivers: [
            MenuAppBar(currentUser: _currentUser),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: Colors.teal)),
              )
            else if (_menuData.isEmpty)
              const MenuEmptyState()
            else
              MenuList(menuData: _menuData),
          ],
        ),
      ),
    );
  }
}

