import 'package:flutter/material.dart';
import 'package:truebpm/models/menu_model.dart';
import 'package:truebpm/utils/menu_constants.dart';

class MenuUtils {
  static bool shouldHideMenu(MenuModel menu) {
    final token = menu.applicationPageId?.token.trim().toLowerCase() ?? '';
    final displayName = menu.displayName.trim().toLowerCase();

    if (token == 'task-list') return true;
    if (token == 'dashboard' || token == 'dashboard-page') return true;
    return displayName == 'dashboard';
  }

  static IconData getMenuIcon(MenuModel menu) {
    if (menu.hasChildren) {
      return Icons.folder;
    }
    
    final token = menu.applicationPageId?.token ?? '';
    if (token.contains('task')) return Icons.task;
    if (token.contains('user')) return Icons.people;
    if (token.contains('category')) return Icons.category;
    if (token.contains('menu')) return Icons.menu;
    if (token.contains('status')) return Icons.info;
    if (token.contains('module')) return Icons.extension;
    if (token.contains('role')) return Icons.security;
    if (token.contains('department')) return Icons.business;
    if (token.contains('permission')) return Icons.lock;
    if (token.contains('office')) return Icons.business_center;
    
    return Icons.description;
  }

  static Color getMenuColor(int level) {
    return MenuConstants.menuColors[level % MenuConstants.menuColors.length];
  }
  
  static double getIconSize(int level) {
    return level == 0 
        ? MenuConstants.parentMenuIconSize 
        : MenuConstants.childMenuIconSize;
  }
  
  static EdgeInsets getItemPadding(int level) {
    return level == 0 
        ? MenuConstants.menuItemPadding 
        : MenuConstants.childMenuItemPadding;
  }
  
  static double getMarginLeft(int level) {
    return level * MenuConstants.menuLevelIndentation;
  }
}
