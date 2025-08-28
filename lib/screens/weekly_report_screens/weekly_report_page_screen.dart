import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/weekly_report_screens/detail_weekly_report_screen.dart';
import 'package:truebpm/screens/weekly_report_screens/body/weekly_report_dtls_tab_body.dart';

/// Weekly Report Page
class WeeklyReportPageScreen extends StatelessWidget {
  const WeeklyReportPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'WKLRPT';
  static const String moduleName = 'Weekly Report';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for WKLRPT
  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: WeeklyReportDetailsTabBody.new),
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
    return DetailWeeklyReportScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}


