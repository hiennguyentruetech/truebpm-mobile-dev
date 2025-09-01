import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/menu_screens/management_screens/dataspy_screens/dataspy_page_screen.dart';

/// Detail screen for DataSpy (DATASPY)
class DetailDataSpyScreen extends DetailCoreScreen {
  const DetailDataSpyScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => DataSpyPageScreen.moduleCode;

  @override
  String get moduleName => DataSpyPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => DataSpyPageScreen.availableTabs;
}
