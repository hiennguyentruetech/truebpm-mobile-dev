import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/e_signing_screen/body/esigng_dtls_tab_body.dart';
import 'package:truebpm/screens/e_signing_screen/body/esigng_his_tab_body.dart';
import 'package:truebpm/screens/e_signing_screen/detail_e_signing_request_screen.dart';

/// E-Signing Page
class ESigningRequestPageScreen extends StatelessWidget {
  const ESigningRequestPageScreen({super.key});

  static const String moduleCode = 'ESIGNG';
  static const String moduleName = 'E-Signing';
  static const String defaultTabCode = 'DTLS';

  static final List<TabConfig> availableTabs = [
    TabConfig(
      code: 'DTLS',
      name: 'Details',
      isDefault: true,
      tabBodyBuilder: ESigningDetailsTabBody.new,
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
      name: 'History',
      tabBodyBuilder: ESigningHistoryTabBody.new,
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
    return DetailESigningRequestScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
