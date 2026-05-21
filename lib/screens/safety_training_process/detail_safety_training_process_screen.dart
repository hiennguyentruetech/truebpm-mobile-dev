import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/safety_training_process/safety_training_process_page_screen.dart';

/// Detail screen for Safety Training Process (SAFETR)
class DetailSafetyTrainingProcessScreen extends DetailCoreScreen {
  const DetailSafetyTrainingProcessScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => SafetyTrainingProcessPageScreen.moduleCode;

  @override
  String get moduleName => SafetyTrainingProcessPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs =>
      SafetyTrainingProcessPageScreen.availableTabs;
}
