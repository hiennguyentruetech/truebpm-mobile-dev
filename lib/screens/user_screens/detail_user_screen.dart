import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/user_screens/user_page_screen.dart';

/// Detail screen for User (USER)
class DetailUserScreen extends DetailCoreScreen {
  const DetailUserScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => UserPageScreen.moduleCode;

  @override
  String get moduleName => UserPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => UserPageScreen.availableTabs;
}
