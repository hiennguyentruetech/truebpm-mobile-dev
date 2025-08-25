import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/ot_registration_screens/ot_page_screen.dart';

/// Detail screen for OT Registration (OVTIME)
class DetailOTScreen extends DetailCoreScreen {
  const DetailOTScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => OTPageScreen.moduleCode;

  @override
  String get moduleName => OTPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => OTPageScreen.availableTabs;
}
