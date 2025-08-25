import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/car_booking_screens/detail_car_booking_screen.dart';
import 'package:truebpm/screens/car_booking_screens/body/car_booking_dtls_tab_body.dart';

/// Car Booking Page
/// Mirrors the structure of ot_registration_screens
class CarBookingPageScreen extends StatelessWidget {
  const CarBookingPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'CARBKG';
  static const String moduleName = 'Car Booking';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for CARBKG
  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: CarBookingDetailsTabBody.new),
    TabConfig(code: 'CMT', name: 'Comments', tabBodyBuilder: TabCmtCoreBodyScreen.new),
    TabConfig(code: 'DOC', name: 'Documents', tabBodyBuilder: TabDocCoreBodyScreen.new),
  ];

  @override
  Widget build(BuildContext context) {
    return ListCoreScreen(
      moduleCode: moduleCode,
      moduleName: moduleName,
      tabModuleCode: defaultTabCode,
      availableTabs: availableTabs,
      detailScreenBuilder: _createDetailScreen,
    );
  }

  Widget? _createDetailScreen(BuildContext context, Map<String, dynamic> listItem) {
    return DetailCarBookingScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
