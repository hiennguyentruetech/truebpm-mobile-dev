import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/quotation_screens/body/quotation_dtls_tab_body.dart';

/// Quotation Page Screen
/// Follows the structure used by OT Registration and other module pages
class QuotationPageScreen extends StatelessWidget {
  const QuotationPageScreen({super.key});

  static const String moduleCode = 'QUTATI';
  static const String moduleName = 'Quotation';
  static const String defaultTabCode = 'DTLS';

  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: QuotationDetailsTabBody.new),
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
      // Re-use generic detail core screen pattern (if a specific detail screen is needed later it can be plugged in)
      detailScreenBuilder: _createDetailScreen,
    );
  }

  Widget? _createDetailScreen(BuildContext context, Map<String, dynamic> listItem) {
    // For now we don't have a custom detail screen; returning null will fallback to default behavior
    return null;
  }
}
