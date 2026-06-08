import 'package:flutter/material.dart';
import 'app_routes.dart';

// All pages imported below are in auth_screens stack
import 'package:truebpm/screens/auth_screens/splash_screen.dart';
import 'package:truebpm/screens/auth_screens/login_screen.dart';

// All pages imported below are in main_tab_screens stack
import 'package:truebpm/screens/main_tab_screens/main_tab_screen.dart';

// Dashboard screens
import 'package:truebpm/screens/dashboard_screens/dashboard_page_screen.dart';
import 'package:truebpm/screens/dashboard_config_screens/dashboard_config_page_screen.dart';

// All pages imported below are in home_screens stack
import 'package:truebpm/screens/home_screens/list_home_screen.dart';
import 'package:truebpm/screens/home_screens/detail_home_screen.dart';

// All pages imported below are in e_leave_screens stack

// All pages imported below are in task_screens stack
import 'package:truebpm/screens/task_screens/list_task_screen.dart';
import 'package:truebpm/screens/task_screens/detail_task_screen.dart';

// Travel Request module
import 'package:truebpm/screens/travel_request_screens/travel_request_page_screen.dart';

// Travel Claim module
import 'package:truebpm/screens/travel_claim_screens/travel_claim_page_screen.dart';

// Contractor Submission module
import 'package:truebpm/screens/contractor_submission_screens/contractor_submission_page_screen.dart';

// Safety Training Process module
import 'package:truebpm/screens/safety_training_process/safety_training_process_page_screen.dart';

// E-Signing module
import 'package:truebpm/screens/e_signing_screen/e_signing_request_page_screen.dart';

// All pages imported below are in menu_screens stack
import 'package:truebpm/screens/menu_screens/list_menu_screen.dart';
import 'package:truebpm/screens/menu_screens/detail_menu_screen.dart';
import 'package:truebpm/screens/menu_screens/management_screens/module_screens/index.dart';
import 'package:truebpm/screens/menu_screens/management_screens/tab_module_screens/index.dart';

// OT Registration screens
import 'package:truebpm/screens/ot_registration_screens/ot_page_screen.dart';

// E-Leave screens
import 'package:truebpm/screens/e_leave_screens/e_leave_page_screen.dart';

// Opportunities screens
import 'package:truebpm/screens/opportunities_screens/opportunities_page_screen.dart';

// Car Booking screens
import 'package:truebpm/screens/car_booking_screens/car_booking_page_screen.dart';

// Product screens
import 'package:truebpm/screens/product_screens/product_page_screen.dart';
// Quotation screens
import 'package:truebpm/screens/quotation_screens/quotation_page_screen.dart';
// Customer screens
import 'package:truebpm/screens/customer_screens/customer_page_screen.dart';
// User screens
import 'package:truebpm/screens/user_screens/user_page_screen.dart';
// Project Management screens
import 'package:truebpm/screens/project_management_screens/project_management_page_screen.dart';

// Predictions screens
import 'package:truebpm/screens/predictions_screens/predictions_page_screen.dart';

// Project CMDR screens
import 'package:truebpm/screens/project_cmdr_screens/project_cmdr_page_screen.dart';
// Weekly Report screens
import 'package:truebpm/screens/weekly_report_screens/weekly_report_page_screen.dart';

class AppPages {
  static Map<String, WidgetBuilder> routes = {
    // Auth routes
    AppRoutes.splash: (context) => const SplashScreen(),
    AppRoutes.login: (context) => const LoginScreen(),

    // Main tab route
    AppRoutes.mainTab: (context) => const MainTabScreen(),

    // Dashboard module route
    AppRoutes.dashboard: (context) => const DashboardPageScreen(),
    AppRoutes.dashboardConfig: (context) => const DashboardConfigPageScreen(),

    // Home module routes
    AppRoutes.home: (context) => const ListHomeScreen(),
    AppRoutes.detailHome: (context) => const DetailHomeScreen(),

    // E-Leave module routes
    AppRoutes.eLeave: (context) => const ELeavePageScreen(),

    // Task module routes
    AppRoutes.task: (context) => const ListTaskScreen(),
    AppRoutes.detailTask: (context) => const DetailTaskScreen(),

    // Travel Request module route
    AppRoutes.travelRequest: (context) => const TravelRequestPageScreen(),

    // Travel Claim module route
    AppRoutes.travelClaim: (context) => const TravelClaimPageScreen(),

    // Contractor Submission module route
    AppRoutes.contractorSubmission: (context) =>
        const ContractorSubmissionPageScreen(),

    // Safety Training Process module route
    AppRoutes.safetyTrainingProcess: (context) =>
        const SafetyTrainingProcessPageScreen(),

    // E-Signing module route
    AppRoutes.eSigningRequest: (context) => const ESigningRequestPageScreen(),

    // Menu module routes
    AppRoutes.menu: (context) => const ListMenuScreen(),
    AppRoutes.detailMenu: (context) => const DetailMenuScreen(),

    // Module management routes
    AppRoutes.modulePage: (context) => const ModulePageScreen(),
    AppRoutes.tabModule: (context) => const TabModuleScreen(),

    // OT Registration route
    AppRoutes.otRegistration: (context) => const OTPageScreen(),

    // Opportunities route
    AppRoutes.opportunities: (context) => const OpportunitiesPageScreen(),

    // Car Booking route
    AppRoutes.carBooking: (context) => const CarBookingPageScreen(),

    // Product route
    AppRoutes.product: (context) => const ProductPageScreen(),

    // Quotation route
    AppRoutes.quotation: (context) => const QuotationPageScreen(),

    // Customer route
    AppRoutes.customer: (context) =>
        const CustomerPageScreen(), // Weekly Report route
    // User route
    AppRoutes.user: (context) => const UserPageScreen(),

    AppRoutes.weeklyReport: (context) => const WeeklyReportPageScreen(),

    // Project Management route
    AppRoutes.projectManagement: (context) =>
        const ProjectManagementPageScreen(),

    // Predictions route
    AppRoutes.predictions: (context) => const PredictionsPageScreen(),

    // Project CMDR route
    AppRoutes.projectCmdr: (context) => const ProjectCmdrPageScreen(),
  };
}
