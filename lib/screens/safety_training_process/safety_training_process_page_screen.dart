import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/safety_training_process/body/safetr_dtls_tab_body.dart';
import 'package:truebpm/screens/safety_training_process/detail_safety_training_process_screen.dart';

/// Safety Training Process Page
/// Mirrors the structure of OT/Travel Request modules
class SafetyTrainingProcessPageScreen extends StatelessWidget {
  const SafetyTrainingProcessPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'SAFETR';
  static const String moduleName = 'Safety Training Process';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for SAFETR
  static final List<TabConfig> availableTabs = [
    TabConfig(
      code: 'DTLS',
      name: 'Details',
      isDefault: true,
      tabBodyBuilder: SafetrDetailsTabBody.new,
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
    return DetailSafetyTrainingProcessScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
