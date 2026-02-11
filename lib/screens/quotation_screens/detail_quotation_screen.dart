import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/quotation_screens/quotation_page_screen.dart';
import 'package:truebpm/widgets/core/core_action_dialog.dart';

/// Detail screen for Quotation (QUTATI)
class DetailQuotationScreen extends DetailCoreScreen {
  DetailQuotationScreen({
    super.key,
    required Map<String, dynamic> listItem,
    String? initialTabCode,
    bool fromTaskScreen = false,
    String? taskId,
    List<PrintReportOption>? printReports,
  }) : super(
          listItem: listItem,
          initialTabCode: initialTabCode,
          fromTaskScreen: fromTaskScreen,
          taskId: taskId,
          printReports: printReports,
        );

  @override
  String get moduleCode => QuotationPageScreen.moduleCode;

  @override
  String get moduleName => QuotationPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => QuotationPageScreen.availableTabs;
}
