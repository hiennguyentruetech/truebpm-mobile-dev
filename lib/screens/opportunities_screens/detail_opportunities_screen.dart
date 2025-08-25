import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/opportunities_screens/opportunities_page_screen.dart';

/// Detail screen for Opportunities (OPPRTU)
class DetailOpportunitiesScreen extends DetailCoreScreen {
  const DetailOpportunitiesScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => OpportunitiesPageScreen.moduleCode;

  @override
  String get moduleName => OpportunitiesPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => OpportunitiesPageScreen.availableTabs;
}
