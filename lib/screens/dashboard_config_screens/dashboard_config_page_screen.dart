import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/dashboard_config_screens/detail_dashboard_config_screen.dart';
import 'package:truebpm/screens/dashboard_config_screens/body/dashboard_config_dtls_tab_body.dart';
import 'package:truebpm/screens/dashboard_config_screens/body/dashboard_config_detail_tab_body.dart';

/// Dashboard Config Page
class DashboardConfigPageScreen extends StatelessWidget {
  const DashboardConfigPageScreen({super.key});

  static const String moduleCode = 'DASCFG';
  static const String moduleName = 'Dashboard Config';
  static const String defaultTabCode = 'DTLS';

  static final List<TabConfig> availableTabs = [
    TabConfig(
      code: 'DTLS',
      name: 'Details',
      isDefault: true,
      tabBodyBuilder: DashboardConfigDetailsTabBody.new,
    ),
    TabConfig(
      code: 'DETAIL',
      name: 'Config Detail',
      tabBodyBuilder: DashboardConfigDetailCollectionTabBody.new,
    ),
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
    return DetailDashboardConfigScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
