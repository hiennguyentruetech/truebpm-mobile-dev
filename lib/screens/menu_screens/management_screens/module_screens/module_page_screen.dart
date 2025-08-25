import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/menu_screens/management_screens/module_screens/detail_module_screen.dart';
import 'package:truebpm/screens/menu_screens/management_screens/module_screens/body/module_dtls_tab_body.dart';
import 'package:truebpm/screens/menu_screens/management_screens/module_screens/body/module_query_tab_body.dart';
import 'package:truebpm/screens/menu_screens/management_screens/module_screens/body/module_config_tab_body.dart';
import 'package:truebpm/screens/menu_screens/management_screens/module_screens/body/module_tbpms_tab_body.dart';
import 'package:truebpm/screens/menu_screens/management_screens/module_screens/body/module_atpms_tab_body.dart';
import 'package:truebpm/screens/menu_screens/management_screens/module_screens/body/module_tabpms_tab_body.dart';
// import 'package:truebpm/widgets/core/core_action_dialog.dart';

/// Extension for creating TabConfig with tab body builder
extension TabConfigBuilder on TabConfig {
  static TabConfig create<T extends Widget>(
    String code, 
    String name, 
    T Function({
      required String moduleCode,
      required String tabCode,
      String? itemId,
      Map<String, dynamic>? initialData,
      Function(Map<String, dynamic>)? onDataChanged,
    }) constructor, {
    bool isDefault = false,
  }) {
    return TabConfig(
      code: code,
      name: name,
      isDefault: isDefault,
      tabBodyBuilder: constructor,
    );
  }
}

class ModulePageScreen extends StatelessWidget {
  const ModulePageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'MODULE';
  static const String moduleName = 'Module Management';
  static const String defaultTabCode = 'DTLS';
  
  // Available tabs for MODULE
  static final List<TabConfig> availableTabs = [
    TabConfigBuilder.create('DTLS', 'Details', ModuleDtlsTabBody.new, isDefault: true),
    TabConfigBuilder.create('QUERY', 'Query Field', ModuleQueryTabBody.new),
    TabConfigBuilder.create('CONFIG', 'Grid Config', ModuleConfigTabBody.new),
    TabConfigBuilder.create('TBPMS', 'Toolbar Permission', ModuleTbpmsTabBody.new),
    TabConfigBuilder.create('ATPMS', 'Attribute Permission', ModuleAtpmsTabBody.new),
    TabConfigBuilder.create('TABPMS', 'Tab Permission', ModuleTabpmsTabBody.new),
    TabConfigBuilder.create('CMT', 'Comments', TabCmtCoreBodyScreen.new),
    TabConfigBuilder.create('DOC', 'Documents', TabDocCoreBodyScreen.new),
  ];

  // // Example print reports for this module
  // static const List<PrintReportOption> printReports = [
  //   PrintReportOption(
  //     reportName: 'Báo cáo chấm công',
  //     reportUrl: 'https://ckmk.truetech.com.vn/report/?context=attendance&id=7BC6F976-35B8-4CB8-A2D5-E96EAB6E523A&fileName=08%2F2025-T%E1%BB%95%20Nh%C3%A0%20%C4%83n-Ph%C3%B2ng%20T%E1%BB%95%20ch%E1%BB%A9c%20H%C3%A0nh%20ch%C3%ADnh',
  //   ),
  //   PrintReportOption(
  //     reportName: 'Báo cáo tổng hợp',
  //     reportUrl: 'https://example.com/report/summary',
  //   ),
  // ];

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
    return DetailModuleScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
      // printReports: printReports,
    );
  }
}
