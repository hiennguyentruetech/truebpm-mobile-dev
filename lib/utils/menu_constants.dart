import 'package:flutter/material.dart';

class MenuConstants {
  // App Bar Configuration
  static const double expandedHeight = 250.0;
  static const double collapsedLogoSize = 40.0;
  static const double expandedLogoSize = 80.0;
  static const double collapsedTitleSize = 16.0;
  static const double expandedTitleSize = 24.0;
  
  // Animation Durations
  static const Duration standardAnimationDuration = Duration(milliseconds: 500);
  static const Duration fastAnimationDuration = Duration(milliseconds: 300);
  static const Duration backgroundAnimationDuration = Duration(milliseconds: 600);
  static const Duration titleAnimationDuration = Duration(milliseconds: 400);
  static const Duration menuExpansionDuration = Duration(milliseconds: 350);
  
  // Animation Curves
  static const Curve standardCurve = Curves.easeInOutCubic;
  static const Curve menuExpansionCurve = Curves.easeInOut;
  static const Curve titleCurve = Curves.easeInOut;
  static const Curve welcomeSectionCurve = Curves.easeInOutQuart;
  
  // Expansion Thresholds
  static const double expandedThreshold = 0.35;
  static const double collapsedThreshold = 0.55;
  
  // Colors
  static final List<Color> menuColors = [
    Colors.blue.shade600,
    Colors.blue.shade700,
    Colors.blue.shade800,
    Colors.blue.shade900,
    Colors.blue.shade400,
  ];
  
  static final List<Color> gradientColors = [
    Colors.blue.shade300,
    Colors.blue.shade600,
    Colors.blue.shade900,
  ];
  
  static const List<double> gradientStops = [0.0, 0.5, 1.0];
  
  // Spacing and Padding
  static const EdgeInsets defaultPadding = EdgeInsets.all(16);
  static const EdgeInsets menuItemPadding = EdgeInsets.all(10);
  static const EdgeInsets childMenuItemPadding = EdgeInsets.all(7);
  static const double menuItemMarginBottom = 4.0;
  static const double menuLevelIndentation = 10.0;
  
  // Border Radius
  static const double defaultBorderRadius = 10.0;
  static const double welcomeSectionBorderRadius = 20.0;
  static const double iconContainerBorderRadius = 6.0;
  static const double trailingIconBorderRadius = 5.0;
  
  // Icon Sizes
  static const double parentMenuIconSize = 20.0;
  static const double childMenuIconSize = 16.0;
  static const double trailingIconSize = 14.0;
  static const double navigationIconSize = 10.0;
  
  // Asset Paths
  static const String appLogoPath = 'assets/logos/app_logo.jpg';
  
  // Text Styles
  static const String welcomeText = 'WELCOME!';
}
