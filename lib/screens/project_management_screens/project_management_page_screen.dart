import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/models/tab_doc_config.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/project_management_screens/detail_project_management_screen.dart';
import 'package:truebpm/screens/project_management_screens/body/project_management_dtls_tab_body.dart';
import 'package:truebpm/screens/project_management_screens/body/project_management_pcmdrd_tab_body.dart';
import 'package:truebpm/screens/project_management_screens/body/project_management_folderexplorer_tab_body.dart';
import 'package:truebpm/screens/project_management_screens/body/project_management_addcostdoc_tab_body.dart';
import 'package:truebpm/screens/project_management_screens/body/project_management_estcosts_tab_body.dart';
import 'package:truebpm/widgets/core/core_action_dialog.dart';

/// Project Management Page
/// Mirrors the structure of menu_screens/management_screens/module_screens
class ProjectManagementPageScreen extends StatelessWidget {
  const ProjectManagementPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'PRJMGT';
  static const String moduleName = 'Project Management';
  static const String defaultTabCode = 'DTLS';

  // Sub-tabs configuration for Documents tab
  static final List<TabDocConfig> documentSubTabs = [
    const TabDocConfig(code: 'CORR', name: 'Correspondences', isDefault: true),
    const TabDocConfig(code: 'PIM', name: 'Project Information Management'),
  ];

  // Available tabs for PRJMGT with custom DOC tab builder
  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: ProjectManagementDetailsTabBody.new),
    TabConfig(code: 'PCMDRD', name: 'CMDR', tabBodyBuilder: ProjectManagementPcmdrdTabBody.new),
    TabConfig(
      code: 'DOC', 
      name: 'Documents', 
      tabBodyBuilder: ({
        Key? key,
        required String moduleCode,
        required String tabCode,
        String? itemId,
        Map<String, dynamic>? initialData,
        Function(Map<String, dynamic>)? onDataChanged,
      }) => TabDocCoreBodyScreen(
        key: key,
        moduleCode: moduleCode,
        tabCode: tabCode,
        itemId: itemId,
        initialData: initialData,
        onDataChanged: onDataChanged,
      ),
    ),
    TabConfig(code: 'FOLDEREXPLORER', name: 'Folder Explorer', tabBodyBuilder: ProjectManagementFolderExplorerTabBody.new),
    TabConfig(code: 'CMT', name: 'Project Note', tabBodyBuilder: TabCmtCoreBodyScreen.new),
    TabConfig(code: 'ADDCOST', name: 'Additional Costs', tabBodyBuilder: ProjectManagementAddCostDocTabBody.new),
    TabConfig(code: 'ESTCOSTS', name: 'Estimated Costs', tabBodyBuilder: ProjectManagementEstCostsTabBody.new),
  ];

  // Dynamic print reports for this module with URL templates
  static final List<PrintReportOption> printReports = [
    const PrintReportOption(
      reportName: 'Project CMDR Structure Report',
      // reportDescription: 'Generate comprehensive CMDR structure report for the current project',
      reportUrl: 'https://solomon.truetech.com.vn/report/?context=projectCMDRUser&id={id}&fileName=Project%20Management%20CMDR%20Structure',
      reportIcon: Icons.account_tree_rounded,
      urlParams: {
        'id': 'value.id',
      },
    ),
    const PrintReportOption(
      reportName: 'Project Summary Report',
      // reportDescription: 'Generate detailed project summary and overview report',
      reportUrl: 'https://solomon.truetech.com.vn/report/?context=projectCost&id={id}&fileName=Project%20Summary%20Report%20{projectCode}',
      reportIcon: Icons.summarize_rounded,
      urlParams: {
        'id': 'value.id',
        'projectCode': 'value.projectCode',
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ListCoreScreen(
      moduleCode: moduleCode,
      moduleName: moduleName,
      tabModuleCode: defaultTabCode,
      availableTabs: availableTabs,
      printReports: printReports,
      detailScreenBuilder: _createDetailScreen,
    );
  }

  Widget? _createDetailScreen(BuildContext context, Map<String, dynamic> listItem) {
    return DetailProjectManagementScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
      printReports: printReports,
    );
  }
}
