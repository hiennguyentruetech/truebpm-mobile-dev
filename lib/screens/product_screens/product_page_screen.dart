import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/core_screens/tab_doc_core_body_screen.dart';
import 'package:truebpm/screens/product_screens/detail_product_screen.dart';
import 'package:truebpm/screens/product_screens/body/product_dtls_tab_body.dart';

/// Product Page
/// Mirrors the structure of ot_registration_screens
class ProductPageScreen extends StatelessWidget {
  const ProductPageScreen({super.key});

  // Module configuration
  static const String moduleCode = 'PRD';
  static const String moduleName = 'Product';
  static const String defaultTabCode = 'DTLS';

  // Available tabs for PRD
  static final List<TabConfig> availableTabs = [
    TabConfig(code: 'DTLS', name: 'Details', isDefault: true, tabBodyBuilder: ProductDetailsTabBody.new),
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
    return DetailProductScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
