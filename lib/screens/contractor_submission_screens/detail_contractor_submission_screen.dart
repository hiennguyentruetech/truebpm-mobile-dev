import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/contractor_submission_screens/contractor_submission_page_screen.dart';

/// Detail screen for Contractor Submission (CONSUB)
class DetailContractorSubmissionScreen extends DetailCoreScreen {
  const DetailContractorSubmissionScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => ContractorSubmissionPageScreen.moduleCode;

  @override
  String get moduleName => ContractorSubmissionPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs =>
      ContractorSubmissionPageScreen.availableTabs;
}
