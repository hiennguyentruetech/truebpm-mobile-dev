class CoreConstants {
  // UI Constants
  static const double cardBorderRadius = 7.0;
  static const double cardElevation = 4.0;
  static const double cardPadding = 7.0;
  static const double circleSize = 40.0;
  static const double searchBorderRadius = 12.0;
  static const double infoBorderRadius = 0.0;
  
  // Animation Constants
  static const Duration cardAnimationDuration = Duration(milliseconds: 150);
  static const Duration snackBarDuration = Duration(seconds: 1);
  static const double cardScaleOnTap = 0.95;
  
  // Pagination Constants
  static const int scrollThreshold = 200;
  static const int initialPagination = 1;
  
  // Default Values
  static const List<String> defaultHeaders = ['Code', 'Name', 'Description'];
  static const List<String> defaultContents = ['code', 'name', 'description'];
  
  // Colors
  static const String primaryBlue = '#2196F3';
  static const String lightBlue = '#E3F2FD';
  
  // Text
  static const String noDataTitle = 'No Data Available';
  static const String noDataSubtitle = 'Try selecting a different DataSpy or pull down to refresh';
  static const String refreshHint = 'Pull down to refresh';
  static const String loadingText = 'Loading data...';
  static const String sessionExpiredTitle = 'Session Expired';
  static const String sessionExpiredMessage = 'Please log in again to continue using the application.';
  static const String loginAgainButton = 'Log In Again';
  static const String cancelButton = 'Cancel';
}
