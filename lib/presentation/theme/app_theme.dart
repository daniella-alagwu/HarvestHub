import 'package:flutter/material.dart';
import 'colors/app_colors.dart';
import 'text_styles.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.mainGreen,
        primary: AppColors.mainGreen,
        secondary: AppColors.autumnRust,
        surface: AppColors.surface,
        error: AppColors.error,
        brightness: Brightness.light,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.mainGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.headingMedium.copyWith(
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.mainGreen,
          disabledBackgroundColor: AppColors.disabledGreen,
          foregroundColor: Colors.white,
          textStyle: AppTextStyles.buttonLabel,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.mainGreen, width: 1.5),
        ),
        hintStyle: AppTextStyles.bodyMuted,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.border),
        ),
      ),
      textTheme: TextTheme(
        headlineSmall: AppTextStyles.headingLarge,
        titleMedium: AppTextStyles.headingMedium,
        bodyMedium: AppTextStyles.bodyRegular,
        bodySmall: AppTextStyles.bodyMuted,
        labelLarge: AppTextStyles.buttonLabel,
      ),
    );
  }
}
