import 'package:flutter/material.dart';
import 'package:storybird_flutter/core/theme/app_colors.dart';

/// App text styles matching the original design
class AppTextStyles {
  AppTextStyles._();

  // Headline font family (Plus Jakarta Sans)
  static const String headlineFont = 'PlusJakartaSans';

  // Body font family (Be Vietnam Pro)
  static const String bodyFont = 'BeVietnamPro';

  // Headline styles
  static TextStyle get headline1 => TextStyle(
        fontFamily: headlineFont,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        color: AppColors.onPrimaryFixed,
        fontStyle: FontStyle.italic,
        height: 1.2,
      );

  static TextStyle get headline2 => TextStyle(
        fontFamily: headlineFont,
        fontSize: 24,
        fontWeight: FontWeight.w900,
        color: AppColors.onPrimaryFixed,
        fontStyle: FontStyle.italic,
        height: 1.2,
      );

  static TextStyle get headline3 => TextStyle(
        fontFamily: headlineFont,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: AppColors.onPrimaryFixed,
        height: 1.3,
      );

  // Body styles
  static TextStyle get bodyLarge => TextStyle(
        fontFamily: bodyFont,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
        height: 1.5,
      );

  static TextStyle get bodyMedium => TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurface,
        height: 1.5,
      );

  static TextStyle get bodySmall => TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceVariant,
        height: 1.4,
      );

  // Label styles
  static TextStyle get labelLarge => TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.4,
      );

  static TextStyle get labelMedium => TextStyle(
        fontFamily: bodyFont,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
        height: 1.4,
      );

  static TextStyle get labelSmall => TextStyle(
        fontFamily: bodyFont,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 0.5,
        height: 1.4,
      );

  // Button styles
  static TextStyle get buttonLarge => TextStyle(
        fontFamily: headlineFont,
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: AppColors.onSecondaryContainer,
        height: 1.2,
      );

  static TextStyle get buttonMedium => TextStyle(
        fontFamily: bodyFont,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
        height: 1.2,
      );

  // Caption styles
  static TextStyle get caption => TextStyle(
        fontFamily: bodyFont,
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 1.5,
        height: 1.4,
      );
}