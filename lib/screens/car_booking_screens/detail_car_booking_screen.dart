import 'package:truebpm/models/core_detail_model.dart';
import 'package:truebpm/screens/core_screens/detail_core_screen.dart';
import 'package:truebpm/screens/car_booking_screens/car_booking_page_screen.dart';

/// Detail screen for Car Booking (CARBKG)
class DetailCarBookingScreen extends DetailCoreScreen {
  const DetailCarBookingScreen({
    super.key,
    required super.listItem,
    super.initialTabCode,
    super.fromTaskScreen = false,
    super.taskId,
  });

  @override
  String get moduleCode => CarBookingPageScreen.moduleCode;

  @override
  String get moduleName => CarBookingPageScreen.moduleName;

  @override
  List<TabConfig> get availableTabs => CarBookingPageScreen.availableTabs;
}
