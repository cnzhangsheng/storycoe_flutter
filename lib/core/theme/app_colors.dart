import 'package:flutter/material.dart';

/// App color palette matching the original React design
class AppColors {
  AppColors._();

  // Surface colors
  static const Color surfaceContainerLow = Color(0xFFFEF9EA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerHigh = Color(0xFFF3EEDD);
  static const Color surfaceContainerHighest = Color(0xFFEDE8D6);

  // Primary colors (Blue)
  static const Color primaryContainer = Color(0xFFA0E4FF);
  static const Color onPrimaryContainer = Color(0xFF005469);
  static const Color onPrimaryFixed = Color(0xFF004050);

  // Secondary colors (Coral)
  static const Color secondaryContainer = Color(0xFFFFC4B6);
  static const Color onSecondaryContainer = Color(0xFF7E2C18);

  // Tertiary colors (Purple)
  static const Color tertiaryContainer = Color(0xFFD6C6FF);
  static const Color onTertiaryContainer = Color(0xFF4A3E6E);

  // Text colors
  static const Color onSurface = Color(0xFF3A382F);
  static const Color onSurfaceVariant = Color(0xFF67645A);

  // Error colors
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF410002);

  // Shadows
  static List<BoxShadow> gummyShadowBlue = [
    BoxShadow(
      color: primaryContainer.withValues(alpha: 0.25),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  static List<BoxShadow> gummyShadowCoral = [
    BoxShadow(
      color: secondaryContainer.withValues(alpha: 0.25),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  static List<BoxShadow> gummyShadowPurple = [
    BoxShadow(
      color: tertiaryContainer.withValues(alpha: 0.25),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  // Inner glow
  static List<BoxShadow> innerGlow = [
    BoxShadow(
      color: Colors.white.withValues(alpha: 0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: -4,
    ),
  ];
}