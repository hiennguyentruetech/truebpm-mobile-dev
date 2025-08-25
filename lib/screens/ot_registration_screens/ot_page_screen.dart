import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/ot_registration_screens/detail_ot_screen.dart';
import 'package:truebpm/screens/ot_registration_screens/body/ot_dtls_tab_body.dart';

/// OT Registration Page
/// Mirrors the structure of menu_screens/management_screens/module_screens
class OTPageScreen extends StatelessWidget {
  const OTPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'OVTIME';
  static const String moduleName = 'OT Registration';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for OVTIME
  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: OTDetailsTabBody.new),
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
    return DetailOTScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
