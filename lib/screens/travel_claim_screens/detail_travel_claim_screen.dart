import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/travel_claim_screens/travel_claim_page_screen.dart';

/// Detail screen for Travel Claim (TRACLA)
class DetailTravelClaimScreen extends DetailCoreScreen {
  const DetailTravelClaimScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => TravelClaimPageScreen.moduleCode;

  @override
  String get moduleName => TravelClaimPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => TravelClaimPageScreen.availableTabs;
}

