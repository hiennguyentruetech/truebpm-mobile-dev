import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/weekly_report_screens/weekly_report_page_screen.dart';

/// Detail screen for Weekly Report (WKLRPT)
class DetailWeeklyReportScreen extends DetailCoreScreen {
  const DetailWeeklyReportScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => WeeklyReportPageScreen.moduleCode;

  @override
  String get moduleName => WeeklyReportPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => WeeklyReportPageScreen.availableTabs;
}


