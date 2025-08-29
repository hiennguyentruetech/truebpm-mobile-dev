import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/e_leave_screens/e_leave_page_screen.dart';

/// Detail screen for E-Leave (ELEAVE)
class DetailELeaveScreen extends DetailCoreScreen {
  const DetailELeaveScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => ELeavePageScreen.moduleCode;

  @override
  String get moduleName => ELeavePageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => ELeavePageScreen.availableTabs;
}
