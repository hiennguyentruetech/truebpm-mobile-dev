import 'package:flutter/cupertino.dart';
import 'package:truebpm/navigation/app_routes.dart';

// Import screens for all stacks
// Dashboard Screens
import 'package:truebpm/screens/dashboard_screens/dashboard_page_screen.dart';
import 'package:truebpm/screens/dashboard_config_screens/dashboard_config_page_screen.dart';

// Home Screens (ListHomeScreen kept for detailHome route references)
// import 'package:truebpm/screens/home_screens/list_home_screen.dart';
import 'package:truebpm/screens/home_screens/detail_home_screen.dart';

// E-Leave Screens
import 'package:truebpm/screens/e_leave_screens/e_leave_page_screen.dart';

// Task Screens
import 'package:truebpm/screens/task_screens/list_task_screen.dart';
import 'package:truebpm/screens/task_screens/detail_task_screen.dart';

// Travel Request Screens
import 'package:truebpm/screens/travel_request_screens/travel_request_page_screen.dart';

// Travel Claim Screens
import 'package:truebpm/screens/travel_claim_screens/travel_claim_page_screen.dart';

// Contractor Submission Screens
import 'package:truebpm/screens/contractor_submission_screens/contractor_submission_page_screen.dart';

// Safety Training Process Screens
import 'package:truebpm/screens/safety_training_process/safety_training_process_page_screen.dart';

// E-Signing Screens
import 'package:truebpm/screens/e_signing_screen/e_signing_request_page_screen.dart';

// Menu Screens
import 'package:truebpm/screens/menu_screens/list_menu_screen.dart';
import 'package:truebpm/screens/menu_screens/detail_menu_screen.dart';
// Module Management ScreensR
import 'package:truebpm/screens/menu_screens/management_screens/module_screens/module_page_screen.dart';
import 'package:truebpm/screens/menu_screens/management_screens/tab_module_screens/tab_module_screen.dart';

// OT Registration Screens
import 'package:truebpm/screens/ot_registration_screens/ot_page_screen.dart';

// Opportunities Screens
import 'package:truebpm/screens/opportunities_screens/opportunities_page_screen.dart';

// Car Booking Screens
import 'package:truebpm/screens/car_booking_screens/car_booking_page_screen.dart';

// Product Screens
import 'package:truebpm/screens/product_screens/product_page_screen.dart';
// Quotation Screens
import 'package:truebpm/screens/quotation_screens/quotation_page_screen.dart';
// Customer Screens
import 'package:truebpm/screens/customer_screens/customer_page_screen.dart';
// Project Management Screens
import 'package:truebpm/screens/project_management_screens/project_management_page_screen.dart';
// Predictions Screens
import 'package:truebpm/screens/predictions_screens/predictions_page_screen.dart';
// Weekly Report Screens
import 'package:truebpm/screens/weekly_report_screens/weekly_report_page_screen.dart';

// DataSpy Screens
import 'package:truebpm/screens/menu_screens/management_screens/dataspy_screens/dataspy_page_screen.dart';

// Notification Screens
import 'package:truebpm/screens/notification_screens/notification_screen.dart';

/// Stack Routes Configuration
class StackRoutes {
  // Tất cả routes được định nghĩa chung trong 1 Map
  static final Map<String, Widget Function()> stackRoutes = {
    // Dashboard Stack Routes
    AppRoutes.dashboard: () => const DashboardPageScreen(),
    AppRoutes.dashboardConfig: () => const DashboardConfigPageScreen(),

    // Home Stack Routes
    AppRoutes.home: () => const DashboardPageScreen(), // Changed to Dashboard
    AppRoutes.detailHome: () => const DetailHomeScreen(),

    // E-Leave Stack Routes
    AppRoutes.eLeave: () => const ELeavePageScreen(),

    // Task Stack Routes
    AppRoutes.task: () => const ListTaskScreen(),
    AppRoutes.detailTask: () => const DetailTaskScreen(),

    // Travel Claim Stack Routes
    AppRoutes.travelClaim: () => const TravelClaimPageScreen(),

    // Travel Request Stack Routes
    AppRoutes.travelRequest: () => const TravelRequestPageScreen(),

    // Contractor Submission Stack Routes
    AppRoutes.contractorSubmission: () =>
        const ContractorSubmissionPageScreen(),

    // Safety Training Process Stack Routes
    AppRoutes.safetyTrainingProcess: () =>
        const SafetyTrainingProcessPageScreen(),

    // E-Signing Stack Routes
    AppRoutes.eSigningRequest: () => const ESigningRequestPageScreen(),

    // Menu Stack Routes
    AppRoutes.menu: () => const ListMenuScreen(),
    AppRoutes.detailMenu: () => const DetailMenuScreen(),

    // Module Management Stack Routes
    AppRoutes.modulePage: () => const ModulePageScreen(),
    AppRoutes.tabModule: () => const TabModuleScreen(),

    // OT Registration Stack Routes
    AppRoutes.otRegistration: () => const OTPageScreen(),

    // Opportunities Stack Routes
    AppRoutes.opportunities: () => const OpportunitiesPageScreen(),

    // Car Booking Stack Routes
    AppRoutes.carBooking: () => const CarBookingPageScreen(),

    // Product Stack Routes
    AppRoutes.product: () => const ProductPageScreen(),

    // Quotation Stack Routes
    AppRoutes.quotation: () => const QuotationPageScreen(),

    // Customer Stack Routes
    AppRoutes.customer: () => const CustomerPageScreen(),

    // Weekly Report Stack Routes
    AppRoutes.weeklyReport: () => const WeeklyReportPageScreen(),

    // Project Management Stack Routes
    AppRoutes.projectManagement: () => const ProjectManagementPageScreen(),

    // Predictions Stack Routes
    AppRoutes.predictions: () => const PredictionsPageScreen(),

    // DataSpy Stack Routes
    AppRoutes.dataSpy: () => const DataSpyPageScreen(),

    // Notification Stack Routes
    AppRoutes.notification: () => const NotificationScreen(),
  };

  /// Enhanced page route builder with swipe back support
  static Route<T> buildPageRoute<T>(
    RouteSettings settings,
    Widget page, {
    bool fullscreenDialog = false,
  }) {
    // Use CupertinoPageRoute for better swipe back support
    return CupertinoPageRoute<T>(
      settings: settings,
      builder: (context) => page,
      fullscreenDialog: fullscreenDialog,
    );
  }

  /// Create route for specific route name with swipe back support
  static Route<T>? createRoute<T>(String routeName, {Object? arguments}) {
    final routeBuilder = stackRoutes[routeName];
    if (routeBuilder != null) {
      return buildPageRoute<T>(
        RouteSettings(name: routeName, arguments: arguments),
        routeBuilder(),
      );
    }
    return null;
  }

  /// Navigate with swipe back support - replacement for Navigator.pushNamed
  static Future<T?> navigateTo<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    final route = createRoute<T>(routeName, arguments: arguments);
    if (route != null) {
      return Navigator.push<T>(context, route);
    } else {
      // Fallback to pushNamed if route not found in stackRoutes
      return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
    }
  }

  /// Generate route - sử dụng stackRoutes chung với swipe back support
  static Route<dynamic>? generateRoute(
    RouteSettings settings,
    String defaultRoute,
  ) {
    final routeBuilder = stackRoutes[settings.name];
    if (routeBuilder != null) {
      return buildPageRoute(settings, routeBuilder());
    }

    // Only fallback to default route if the current route name is different from default
    if (settings.name != defaultRoute) {
      final defaultBuilder = stackRoutes[defaultRoute];
      if (defaultBuilder != null) {
        return buildPageRoute(
          RouteSettings(name: defaultRoute, arguments: settings.arguments),
          defaultBuilder(),
        );
      }
    }

    // Ultimate fallback
    return null;
  }
}
