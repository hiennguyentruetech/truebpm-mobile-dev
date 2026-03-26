import 'package:flutter/material.dart';
import 'package:truebpm/models/menu_model.dart';
import 'package:truebpm/utils/menu_constants.dart';

class MenuUtils {
  static bool shouldHideMenu(MenuModel menu) {
    final token = menu.applicationPageId?.token.trim().toLowerCase() ?? '';
    return token == 'dashboard-page' || token == 'task-list';
  }

  static IconData getMenuIcon(MenuModel menu) {
    if (menu.hasChildren) {
      return Icons.folder;
    }

    final token = menu.applicationPageId?.token.trim().toLowerCase() ?? '';
    switch (token) {
      case 'menu-page':
        return Icons.list_alt;
      case 'module-page':
        return Icons.extension;
      case 'tab-module':
        return Icons.view_module;
      case 'status-page':
        return Icons.info_outline;
      case 'dataspy-page':
        return Icons.search;
      case 'organization-page':
        return Icons.account_tree;
      case 'department-page':
        return Icons.apartment;
      case 'role-page':
        return Icons.security;
      case 'user-page':
        return Icons.badge;
      case 'user-permission-page':
        return Icons.lock;
      case 'opportunities-page':
        return Icons.trending_up;
      case 'quotation-page':
        return Icons.description;
      case 'customer-page':
        return Icons.people;
      case 'product-page':
        return Icons.inventory_2;
      case 'travel-request-page':
        return Icons.flight_takeoff;
      case 'travel-claim-page':
        return Icons.receipt_long;
      case 'e-leave-page':
        return Icons.event_busy;
      case 'ot-page':
        return Icons.schedule;
      case 'car-booking-page':
        return Icons.directions_car;
      case 'weekly-report-page':
        return Icons.bar_chart;
      case 'project-management':
        return Icons.assignment;
      case 'project-cmdr':
        return Icons.work_outline;
      case 'chart-config-page':
        return Icons.pie_chart;
      case 'inbox-config-page':
        return Icons.inbox;
      case 'dashboard-config-page':
        return Icons.dashboard_customize;
      case 'annotation-config-page':
        return Icons.edit_note;
      case 'widget-definition-page':
        return Icons.widgets;
      case 'email-template-page':
        return Icons.email;
      case 'notification-config-page':
        return Icons.notifications_active;
      case 'firebase-config-page':
        return Icons.cloud_done;
      case 'audit-history-page':
        return Icons.history;
      case 'revenue-forecast-page':
        return Icons.show_chart;
    }

    if (token.contains('config')) return Icons.settings;
    if (token.contains('dashboard')) return Icons.dashboard;
    if (token.contains('report')) return Icons.analytics;
    if (token.contains('travel')) return Icons.flight;
    if (token.contains('project')) return Icons.work_outline;

    return Icons.description_outlined;
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
