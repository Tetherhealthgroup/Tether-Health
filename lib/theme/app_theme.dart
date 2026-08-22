import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.deepTeal,
        brightness: Brightness.light,
        primary: AppColors.deepTeal,
        secondary: AppColors.coral,
        surface: AppColors.paper,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: AppColors.deepTeal,
          fontSize: 40,
          height: 1.08,
          letterSpacing: -1.7,
          fontWeight: FontWeight.w800,
        ),
        bodyLarge: TextStyle(
          color: AppColors.tealSecondary,
          fontSize: 17,
          height: 1.48,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
    );
  }
}
