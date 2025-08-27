import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/travel_request_screens/travel_request_page_screen.dart';

/// Detail screen for Travel Request (TRAREQ)
class DetailTravelRequestScreen extends DetailCoreScreen {
  const DetailTravelRequestScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => TravelRequestPageScreen.moduleCode;

  @override
  String get moduleName => TravelRequestPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => TravelRequestPageScreen.availableTabs;
}
