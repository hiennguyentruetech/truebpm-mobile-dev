import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/e_signing_screen/e_signing_request_page_screen.dart';

/// Detail screen for E-Signing (ESIGNG)
class DetailESigningRequestScreen extends DetailCoreScreen {
  const DetailESigningRequestScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => ESigningRequestPageScreen.moduleCode;

  @override
  String get moduleName => ESigningRequestPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => ESigningRequestPageScreen.availableTabs;
}
