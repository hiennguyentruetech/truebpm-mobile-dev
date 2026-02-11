import 'package:flutter/material.dart';
import 'package:truebpm/screens/ot_registration_screens/detail_ot_screen.dart';
import 'package:truebpm/screens/car_booking_screens/detail_car_booking_screen.dart';
import 'package:truebpm/screens/product_screens/detail_product_screen.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/project_cmdr_screens/project_cmdr_detail_screen.dart';
import 'package:truebpm/screens/e_leave_screens/detail_e_leave_screen.dart';
import 'package:truebpm/screens/menu_screens/management_screens/dataspy_screens/detail_dataspy_screen.dart';
import 'package:truebpm/screens/travel_request_screens/detail_travel_request_screen.dart';
import 'package:truebpm/screens/travel_claim_screens/detail_travel_claim_screen.dart';
import 'package:truebpm/screens/weekly_report_screens/detail_weekly_report_screen.dart';
import 'package:truebpm/screens/quotation_screens/detail_quotation_screen.dart';

/// Enum định nghĩa các loại module có thể navigate
enum TaskModuleType {
  overtime('OVTIME'),
  carBooking('CARBKG'),
  product('PRD'),
  cmdrmd('CMDRMD'),
  travelRequest('TRAREQ'),
  travelClaim('TRACLA'),
  quotation('QUTATI'),
  weeklyReport('WKLRPT'),
  eLeave('ELEAVE'),
  dataSpy('DATASPY'),
  generic('GENERIC');

  const TaskModuleType(this.code);
  final String code;

  /// Get module type từ module code
  static TaskModuleType fromCode(String moduleCode) {
    switch (moduleCode.toUpperCase()) {
      case 'OVTIME':
        return TaskModuleType.overtime;
      case 'CARBKG':
        return TaskModuleType.carBooking;
      case 'PRD':
        return TaskModuleType.product;
      case 'CMDRMD':
        return TaskModuleType.cmdrmd;
      case 'TRAREQ':
        return TaskModuleType.travelRequest;
      case 'TRACLA':
        return TaskModuleType.travelClaim;
      case 'WKLRPT':
        return TaskModuleType.weeklyReport;
      case 'ELEAVE':
        return TaskModuleType.eLeave;
      case 'DATASPY':
        return TaskModuleType.dataSpy;
      case 'QUTATI':
        return TaskModuleType.quotation;
      case 'CTM':
        return TaskModuleType.generic; // Use generic detail for now
      default:
        return TaskModuleType.generic;
    }
  }
}

/// Configuration class cho task navigation
class TaskNavigationConfig {
  final String moduleCode;
  final String listItemId;
  final String taskId;
  final String initialTabCode;
  final bool fromTaskScreen;

  const TaskNavigationConfig({
    required this.moduleCode,
    required this.listItemId,
    required this.taskId,
    this.initialTabCode = 'DTLS',
    this.fromTaskScreen = true,
  });

  /// Tạo config từ task data
  factory TaskNavigationConfig.fromTask(Map<String, dynamic> task) {
    final moduleCode = task['rootContainerId']?['displayDescription']?.toString() ?? '';
    final parsedDisplayDescription = task['displayDescriptionParsed'] as Map<String, dynamic>?;
    final listItemId = parsedDisplayDescription?['id']?.toString() ?? '';
    final taskId = task['id']?.toString() ?? '';

    return TaskNavigationConfig(
      moduleCode: moduleCode,
      listItemId: listItemId,
      taskId: taskId,
    );
  }

  /// Validate config
  bool get isValid => moduleCode.isNotEmpty && listItemId.isNotEmpty;
}

/// Factory class để tạo target screen dựa trên module type
class TaskScreenFactory {
  /// Tạo target screen dựa trên config
  static Widget createScreen(TaskNavigationConfig config) {
    final moduleType = TaskModuleType.fromCode(config.moduleCode);
    
    switch (moduleType) {
      case TaskModuleType.overtime:
        return DetailOTScreen(
          listItem: {'id': config.listItemId},
          initialTabCode: config.initialTabCode,
          fromTaskScreen: config.fromTaskScreen,
          taskId: config.taskId,
        );

      case TaskModuleType.carBooking:
        return DetailCarBookingScreen(
          listItem: {'id': config.listItemId},
          initialTabCode: config.initialTabCode,
          fromTaskScreen: config.fromTaskScreen,
          taskId: config.taskId,
        );

      case TaskModuleType.product:
        return DetailProductScreen(
          listItem: {'id': config.listItemId},
          initialTabCode: config.initialTabCode,
          fromTaskScreen: config.fromTaskScreen,
          taskId: config.taskId,
        );

      case TaskModuleType.cmdrmd:
        return DetailProjectCmdrScreen(
          listItem: {'id': config.listItemId},
          initialTabCode: config.initialTabCode,
          fromTaskScreen: config.fromTaskScreen,
          taskId: config.taskId,
        );

      case TaskModuleType.travelRequest:
        return DetailTravelRequestScreen(
          listItem: {'id': config.listItemId},
          initialTabCode: config.initialTabCode,
          fromTaskScreen: config.fromTaskScreen,
          taskId: config.taskId,
        );

      case TaskModuleType.travelClaim:
        return DetailTravelClaimScreen(
          listItem: {'id': config.listItemId},
          initialTabCode: config.initialTabCode,
          fromTaskScreen: config.fromTaskScreen,
          taskId: config.taskId,
        );

      case TaskModuleType.quotation:
        return DetailQuotationScreen(
          listItem: {'id': config.listItemId},
          initialTabCode: config.initialTabCode,
          fromTaskScreen: config.fromTaskScreen,
          taskId: config.taskId,
        );

      case TaskModuleType.weeklyReport:
        return DetailWeeklyReportScreen(
          listItem: {'id': config.listItemId},
          initialTabCode: config.initialTabCode,
          fromTaskScreen: config.fromTaskScreen,
          taskId: config.taskId,
        );

      case TaskModuleType.eLeave:
        return DetailELeaveScreen(
          listItem: {'id': config.listItemId},
          initialTabCode: config.initialTabCode,
          fromTaskScreen: config.fromTaskScreen,
          taskId: config.taskId,
        );

      case TaskModuleType.dataSpy:
        return DetailDataSpyScreen(
          listItem: {'id': config.listItemId},
          initialTabCode: config.initialTabCode,
          fromTaskScreen: config.fromTaskScreen,
          taskId: config.taskId,
        );

      case TaskModuleType.generic:
        return GenericDetailCoreScreen(
          moduleCode: config.moduleCode,
          listItem: {'id': config.listItemId},
          initialTabCode: config.initialTabCode,
          fromTaskScreen: config.fromTaskScreen,
          taskId: config.taskId,
        );
    }
  }

  /// Get screen title dựa trên module type (optional)
  static String getScreenTitle(TaskModuleType moduleType) {
    switch (moduleType) {
      case TaskModuleType.overtime:
        return 'Overtime Request';
      case TaskModuleType.carBooking:
        return 'Car Booking';
      case TaskModuleType.product:
        return 'Product Management';
      case TaskModuleType.cmdrmd:
        return 'Project Management';
      case TaskModuleType.travelRequest:
        return 'Travel Request';
      case TaskModuleType.travelClaim:
        return 'Travel Claim';
      case TaskModuleType.quotation:
        return 'Quotation';
      case TaskModuleType.weeklyReport:
        return 'Weekly Report';
      case TaskModuleType.eLeave:
        return 'E-Leave Request';
      case TaskModuleType.dataSpy:
        return 'Data Spy';
      case TaskModuleType.generic:
        return 'Task Detail';
    }
  }
}

/// Extension để dễ dàng add thêm module types
extension TaskModuleTypeExtension on TaskModuleType {
  /// Get display name
  String get displayName {
    switch (this) {
      case TaskModuleType.overtime:
        return 'Overtime';
      case TaskModuleType.carBooking:
        return 'Car Booking';
      case TaskModuleType.product:
        return 'Product';
      case TaskModuleType.cmdrmd:
        return 'Project Management';
      case TaskModuleType.travelRequest:
        return 'Travel Request';
      case TaskModuleType.travelClaim:
        return 'Travel Claim';
      case TaskModuleType.quotation:
        return 'Quotation';
      case TaskModuleType.weeklyReport:
        return 'Weekly Report';
      case TaskModuleType.eLeave:
        return 'E-Leave';
      case TaskModuleType.dataSpy:
        return 'Data Spy';
      case TaskModuleType.generic:
        return 'General Task';
    }
  }

  /// Get icon cho module (optional)
  IconData get icon {
    switch (this) {
      case TaskModuleType.overtime:
        return Icons.access_time;
      case TaskModuleType.carBooking:
        return Icons.directions_car;
      case TaskModuleType.product:
        return Icons.inventory_2;
      case TaskModuleType.cmdrmd:
        return Icons.person;
      case TaskModuleType.travelRequest:
        return Icons.flight_takeoff;
      case TaskModuleType.travelClaim:
        return Icons.receipt_long;
      case TaskModuleType.quotation:
        return Icons.request_quote;
      case TaskModuleType.weeklyReport:
        return Icons.calendar_view_week;
      case TaskModuleType.eLeave:
        return Icons.event_note;
      case TaskModuleType.dataSpy:
        return Icons.analytics;
      case TaskModuleType.generic:
        return Icons.task_alt;
    }
  }
}
