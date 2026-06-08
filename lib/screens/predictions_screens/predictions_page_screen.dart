import 'package:flutter/material.dart';
import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/list_core_screen.dart';
import 'package:truebpm/screens/core_screens/tab_cmt_core_body_screen.dart';
import 'package:truebpm/screens/predictions_screens/body/predictions_dtls_tab_body.dart';
import 'package:truebpm/screens/predictions_screens/body/predictions_history_tab_body.dart';
import 'package:truebpm/screens/predictions_screens/body/predictions_leaderboard_tab_body.dart';
import 'package:truebpm/screens/predictions_screens/detail_predictions_screen.dart';

/// Predictions Page
class PredictionsPageScreen extends StatelessWidget {
  const PredictionsPageScreen({super.key});

  static const String moduleCode = 'PREDIC';
  static const String moduleName = 'Predictions';
  static const String defaultTabCode = 'DTLS';

  static final List<TabConfig> availableTabs = [
    TabConfig(
      code: 'DTLS',
      name: 'Details',
      isDefault: true,
      tabBodyBuilder: PredictionsDetailsTabBody.new,
    ),
    TabConfig(
      code: 'PREDHIS',
      apiCode: 'DTLS',
      name: "Other's Predictions",
      tabBodyBuilder: PredictionsHistoryTabBody.new,
    ),
    TabConfig(
      code: 'PREDLEAD',
      apiCode: 'DTLS',
      name: 'Leaderboard',
      tabBodyBuilder: PredictionsLeaderboardTabBody.new,
    ),
    TabConfig(
      code: 'CMT',
      name: 'Comments',
      tabBodyBuilder: TabCmtCoreBodyScreen.new,
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
    return DetailPredictionsScreen(
      listItem: listItem,
      initialTabCode: defaultTabCode,
    );
  }
}
