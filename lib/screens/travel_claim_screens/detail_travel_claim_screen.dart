import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/travel_claim_screens/travel_claim_page_screen.dart';
import 'package:truebpm/widgets/core/core_action_dialog.dart';

/// Detail screen for Travel Claim (TRACLA)
class DetailTravelClaimScreen extends DetailCoreScreen {
  DetailTravelClaimScreen({
    super.key,
    required Map<String, dynamic> listItem,
    String? initialTabCode,
    bool fromTaskScreen = false,
    String? taskId,
    List<PrintReportOption>? printReports,
  }) : super(
          listItem: listItem,
          initialTabCode: initialTabCode,
          fromTaskScreen: fromTaskScreen,
          taskId: taskId,
          printReports: printReports ?? TravelClaimPageScreen.printReports,
        );

  @override
  String get moduleCode => TravelClaimPageScreen.moduleCode;

  @override
  String get moduleName => TravelClaimPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => TravelClaimPageScreen.availableTabs;
}

