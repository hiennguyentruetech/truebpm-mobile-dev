import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/opportunities_screens/detail_opportunities_screen.dart';
import 'package:truebpm/screens/opportunities_screens/body/opportunities_dtls_tab_body.dart';
import 'package:truebpm/screens/opportunities_screens/body/opportunities_poi_tab_body.dart';

/// Opportunities Page
/// Mirrors the structure of OT Registration and other core modules
class OpportunitiesPageScreen extends StatelessWidget {
  const OpportunitiesPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'OPPRTU';
  static const String moduleName = 'Opportunities';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for OPPRTU
  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: OpportunitiesDetailsTabBody.new),
    TabConfig(code: 'POI', name: 'Product of Interest', tabBodyBuilder: OpportunitiesPOITabBody.new),
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
    return DetailOpportunitiesScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
