import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/dashboard_config_screens/dashboard_config_page_screen.dart';

/// Detail screen for Dashboard Config (DASCFG)
class DetailDashboardConfigScreen extends DetailCoreScreen {
  const DetailDashboardConfigScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => DashboardConfigPageScreen.moduleCode;

  @override
  String get moduleName => DashboardConfigPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => DashboardConfigPageScreen.availableTabs;
}
