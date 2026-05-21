import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/contractor_submission_screens/body/consub_dtls_tab_body.dart';
import 'package:truebpm/screens/contractor_submission_screens/body/consub_his_tab_body.dart';
import 'package:truebpm/screens/contractor_submission_screens/detail_contractor_submission_screen.dart';

/// Contractor Submission Page
/// Mirrors the structure of OT/Travel Request modules
class ContractorSubmissionPageScreen extends StatelessWidget {
  const ContractorSubmissionPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'CONSUB';
  static const String moduleName = 'Contractor Submission';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for CONSUB
  static final List<TabConfig> availableTabs = [
    TabConfig(
      code: 'DTLS',
      name: 'Details',
      isDefault: true,
      tabBodyBuilder: ConsubDetailsTabBody.new,
    ),
    TabConfig(
      code: 'CMT',
      name: 'Comments',
      tabBodyBuilder: TabCmtCoreBodyScreen.new,
    ),
    TabConfig(
      code: 'DOC',
      name: 'Documents',
      tabBodyBuilder: TabDocCoreBodyScreen.new,
    ),
    TabConfig(
      code: 'HIS',
      name: 'Workflow History',
      tabBodyBuilder: ConsubHistoryTabBody.new,
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

  Widget? _createDetailScreen(
    BuildContext context,
    Map<String, dynamic> listItem,
  ) {
    return DetailContractorSubmissionScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
