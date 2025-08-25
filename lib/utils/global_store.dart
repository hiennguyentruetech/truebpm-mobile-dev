// Import all application strings and constants
import 'package:truebpm/providers/asset_strings.dart';
import 'package:truebpm/host/host_strings.dart';
import 'package:truebpm/utils/app_constants.dart';
import 'package:truebpm/utils/app_strings.dart';

// Import all functions and classes related to global state management
import 'package:truebpm/utils/logger.dart';
import 'package:truebpm/utils/functions.dart';
import 'package:truebpm/utils/core_api_logger.dart';
  
final 
  // Khai báo các biến string toàn cục để sử dụng trong toàn bộ ứng dụng
  assets = AssetStrings(),
  hosts = HostStrings(),
  appConstants = AppConstants(),
  appStrings = AppStrings(),
  
  // Khai báo các hàm và lớp liên quan đến quản lý trạng thái toàn cục;
  funcs = Functions(),
  logger = appLogger,
  apiLogger = CoreApiLogger;
