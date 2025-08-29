import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/e_leave_screens/detail_e_leave_screen.dart';
import 'package:truebpm/screens/e_leave_screens/body/e_leave_dtls_tab_body.dart';

/// E-Leave Page
/// Mirrors the structure of ot_registration_screens
class ELeavePageScreen extends StatelessWidget {
  const ELeavePageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'ELEAVE';
  static const String moduleName = 'E-Leave';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for ELEAVE
  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: ELeaveDetailsTabBody.new),
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
    return DetailELeaveScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
