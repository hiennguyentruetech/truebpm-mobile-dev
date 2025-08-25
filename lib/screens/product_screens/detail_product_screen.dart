import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/product_screens/product_page_screen.dart';

/// Detail screen for Product (PRD)
class DetailProductScreen extends DetailCoreScreen {
  const DetailProductScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => ProductPageScreen.moduleCode;

  @override
  String get moduleName => ProductPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => ProductPageScreen.availableTabs;
}
