import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/menu_screens/management_screens/dataspy_screens/detail_dataspy_screen.dart';
import 'package:truebpm/screens/menu_screens/management_screens/dataspy_screens/body/dataspy_dtls_tab_body.dart';
import 'package:truebpm/screens/menu_screens/management_screens/dataspy_screens/body/dataspy_permission_tab_body.dart';
import 'package:truebpm/screens/menu_screens/management_screens/dataspy_screens/body/dataspy_query_tab_body.dart';

/// DataSpy Management Page
/// Mirrors the structure of ot_registration_screens for DATASPY module
class DataSpyPageScreen extends StatelessWidget {
  const DataSpyPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'DATASPY';
  static const String moduleName = 'Data Spy';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for DATASPY
  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: DataSpyDetailsTabBody.new),
    TabConfig(code: 'PERMISSION', name: 'Permissions', tabBodyBuilder: DataSpyPermissionTabBody.new),
    TabConfig(code: 'QUERY', name: 'Query Where', tabBodyBuilder: DataSpyQueryTabBody.new),
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
    return DetailDataSpyScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
