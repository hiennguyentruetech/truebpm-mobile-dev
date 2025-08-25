import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/menu_screens/management_screens/module_screens/module_page_screen.dart';

/// Detail screen specifically for MODULE management
/// Extends DetailCoreScreen and provides module-specific tab body creation
class DetailModuleScreen extends DetailCoreScreen {
  const DetailModuleScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.printReports, // accept reports from ModulePageScreen
  });

  @override
  String get moduleCode => ModulePageScreen.moduleCode;

  @override
  String get moduleName => ModulePageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => ModulePageScreen.availableTabs;
}
