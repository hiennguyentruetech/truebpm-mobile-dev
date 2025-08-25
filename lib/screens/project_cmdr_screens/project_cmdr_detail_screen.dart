import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/project_cmdr_screens/project_cmdr_page_screen.dart';

/// Detail screen for Project CMDR (CMDRMD)
class DetailProjectCmdrScreen extends DetailCoreScreen {
  const DetailProjectCmdrScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => ProjectCmdrPageScreen.moduleCode;

  @override
  String get moduleName => ProjectCmdrPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => ProjectCmdrPageScreen.availableTabs;
}
