import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/predictions_screens/predictions_page_screen.dart';

/// Detail screen for Predictions (PREDIC)
class DetailPredictionsScreen extends DetailCoreScreen {
  const DetailPredictionsScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => PredictionsPageScreen.moduleCode;

  @override
  String get moduleName => PredictionsPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => PredictionsPageScreen.availableTabs;
}
