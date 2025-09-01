import 'package:flutter/material.dart';
import 'package:truebpm/models/menu_model.dart';
import 'package:truebpm/navigation/app_routes.dart';
// import 'package:truebpm/utils/global_store.dart';

class MenuNavigationService {
  static void navigateToPage(BuildContext context, MenuModel menu) {
    if (menu.applicationPageId == null) return;
    
    final token = menu.applicationPageId!.token;
    // logger.i('Navigate to page: $token');
    
    try {
      String routeName;
  // token is non-null here (applicationPageId checked above)
  final tokenStr = token;

      switch (tokenStr) {
        case 'module-page':
          routeName = AppRoutes.modulePage;
          break;
        case 'tab-module':
          routeName = AppRoutes.tabModule;
          break;
        case 'weekly-report-page':
          routeName = AppRoutes.weeklyReport;
          break;
        case 'ot-page':
          routeName = AppRoutes.otRegistration;
          break;
        case 'opportunities-page':
          routeName = AppRoutes.opportunities;
          break;
        case 'car-booking-page':
          routeName = AppRoutes.carBooking;
          break;
        case 'product-page':
          routeName = AppRoutes.product;
          break;
        case 'project-management':
          routeName = AppRoutes.projectManagement;
          break;
        case 'project-cmdr':
          routeName = AppRoutes.projectCmdr;
          break;
        case 'travel-request-page':
          routeName = AppRoutes.travelRequest;
          break;
        case 'travel-claim-page':
          routeName = AppRoutes.travelClaim;
          break;
        case 'e-leave-page':
          routeName = AppRoutes.eLeave;
          break;
        case 'dataspy-page':
          routeName = AppRoutes.dataSpy;
          break;
        default:
          routeName = AppRoutes.detailMenu;
      }

      Navigator.pushNamed(context, routeName);
    } catch (e) {
      // logger.e('Error navigating to page: $e');
      // Fallback navigation
      Navigator.pushNamed(context, AppRoutes.detailMenu);
    }
  }
  
  static bool canNavigate(MenuModel menu) {
    return menu.applicationPageId != null && !menu.hasChildren;
  }
}
