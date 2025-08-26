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
        enableRevision: true,
        enableDocumentType: true,
        dataRevision: 'DROPDOWN.RESOURCE/REVISION',
        dataDocumentType: 'DROPDOWN.PRJMGT/PROJECTDOCTYPE',
        onDataChanged: onDataChanged,
      ),
    ),
    TabConfig(code: 'FOLDEREXPLORER', name: 'Folder Explorer', tabBodyBuilder: ProjectManagementFolderExplorerTabBody.new),
    TabConfig(code: 'CMT', name: 'Project Note', tabBodyBuilder: TabCmtCoreBodyScreen.new),
    TabConfig(code: 'ADDCOST', name: 'Additional Cost', tabBodyBuilder: ProjectManagementAddCostDocTabBody.new),
    TabConfig(code: 'ESTCOSTS', name: 'Estimated Cost', tabBodyBuilder: ProjectManagementEstCostsTabBody.new),
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
    return DetailProjectManagementScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
