import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/project_cmdr_screens/project_cmdr_detail_screen.dart';
import 'package:truebpm/screens/project_cmdr_screens/body/cmdr_dtls_tab_body.dart';

/// Project CMDR Page
/// Mirrors the structure of OT Registration module
class ProjectCmdrPageScreen extends StatelessWidget {
  const ProjectCmdrPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'CMDRMD';
  static const String moduleName = 'Project Commander';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for CMDRMD
  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: CmdrDetailsTabBody.new),
    TabConfig(code: 'CMT', name: 'Comments', tabBodyBuilder: TabCmtCoreBodyScreen.new),
    // Add revision config for Documents tab
    TabConfig(
      code: 'CMDRMD',
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
        enableRevision: true,
        enableDocumentType: true,
        dataRevision: 'DROPDOWN.RESOURCE/REVISION',
        dataDocumentType: 'DROPDOWN.PRJMGT/PROJECTDOCTYPE',
      ),
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
    return DetailProjectCmdrScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
