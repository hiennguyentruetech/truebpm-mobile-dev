import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/travel_request_screens/detail_travel_request_screen.dart';
import 'package:truebpm/screens/travel_request_screens/body/tr_dtls_tab_body.dart';
import 'package:truebpm/screens/travel_request_screens/body/tr_adva_tab_body.dart';
import 'package:truebpm/screens/travel_request_screens/body/tr_adad_tab_body.dart';

/// Travel Request Page
/// Mirrors the structure of OT Registration module
class TravelRequestPageScreen extends StatelessWidget {
  const TravelRequestPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'TRAREQ';
  static const String moduleName = 'Travel Request';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for TRAREQ
  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: TRDetailsTabBody.new),
    TabConfig(code: 'ADVA', name: 'Advance', tabBodyBuilder: TRAdvanceTabBody.new),
    TabConfig(code: 'ADAD', name: 'Additional Advance', tabBodyBuilder: TRAdditionalAdvanceTabBody.new),
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
    return DetailTravelRequestScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}

