import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Text styles for the application
class AppTextStyles {
  // Headings
  static const TextStyle h1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -1.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle h2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle h3 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle h4 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle h5 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static const TextStyle h6 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    color: AppColors.textPrimary,
  );

  // Body text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.25,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  // Button text
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.25,
    color: Colors.white,
  );

  // Caption and overline
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
    letterSpacing: 1.5,
    color: AppColors.textSecondary,
  );

  // Dark mode variants
  static TextStyle h1Dark = h1.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle h2Dark = h2.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle h3Dark = h3.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle h4Dark = h4.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle h5Dark = h5.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle h6Dark = h6.copyWith(color: AppColors.textPrimaryDark);
  
  static TextStyle bodyLargeDark = bodyLarge.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle bodyMediumDark = bodyMedium.copyWith(color: AppColors.textPrimaryDark);
  static TextStyle bodySmallDark = bodySmall.copyWith(color: AppColors.textSecondaryDark);
  
  static TextStyle captionDark = caption.copyWith(color: AppColors.textSecondaryDark);
  static TextStyle overlineDark = overline.copyWith(color: AppColors.textSecondaryDark);
}