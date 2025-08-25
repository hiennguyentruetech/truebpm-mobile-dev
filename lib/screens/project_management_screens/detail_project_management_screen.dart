import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/project_management_screens/project_management_page_screen.dart';
import 'package:truebpm/models/tab_doc_config.dart';

/// Detail screen for Project Management (PRJMGT)
class DetailProjectManagementScreen extends DetailCoreScreen {
  const DetailProjectManagementScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => ProjectManagementPageScreen.moduleCode;

  @override
  String get moduleName => ProjectManagementPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => ProjectManagementPageScreen.availableTabs;

  // Provide DOC sub-tabs for PRJMGT
  @override
  List<TabDocConfig>? get docSubTabs => ProjectManagementPageScreen.documentSubTabs;
}
