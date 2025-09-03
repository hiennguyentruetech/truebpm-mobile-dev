import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/travel_claim_screens/detail_travel_claim_screen.dart';
import 'package:truebpm/screens/travel_claim_screens/body/trc_dtls_tab_body.dart';
import 'package:truebpm/screens/travel_claim_screens/body/trc_info_general_tab_body.dart';
import 'package:truebpm/screens/travel_claim_screens/body/trc_info_special_tab_body.dart';
import 'package:truebpm/widgets/core/core_action_dialog.dart';

/// Travel Claim Page
/// Mirrors the structure of OT Registration module
class TravelClaimPageScreen extends StatelessWidget {
  const TravelClaimPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'TRACLA';
  static const String moduleName = 'Travel Claim';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for TRACLA
  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: TRCDetailsTabBody.new),
    // Two UI tabs for INFO, each displays different key from itemDetail.value
    TabConfig(code: 'INFO', name: 'General Expense', tabBodyBuilder: TRCInfoGeneralTabBody.new),
    TabConfig(code: 'INSE', name: 'Special Expense', tabBodyBuilder: TRCInfoSpecialTabBody.new),
    TabConfig(code: 'CMT', name: 'Comments', tabBodyBuilder: TabCmtCoreBodyScreen.new),
    TabConfig(code: 'DOC', name: 'Documents', tabBodyBuilder: TabDocCoreBodyScreen.new),
  ];

  // Print report actions for Travel Claim
  // URL pattern: https://solomon.truetech.com.vn/report/?context=travelClaim&id={id}&fileName={code}
  static final List<PrintReportOption> printReports = [
    const PrintReportOption(
      reportName: 'Travel Claim Report',
      reportUrl: 'https://solomon.truetech.com.vn/report/?context=travelClaim&id={id}&fileName={code}',
      reportIcon: Icons.picture_as_pdf_rounded,
      urlParams: {
        'id': 'value.id',
        'code': 'value.code',
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
      // ListCoreScreen doesn't take printReports directly; passed via detailScreenBuilder
      detailScreenBuilder: _createDetailScreen,
    );
  }

  Widget? _createDetailScreen(BuildContext context, Map<String, dynamic> listItem) {
    return DetailTravelClaimScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
      printReports: printReports,
    );
  }
}

