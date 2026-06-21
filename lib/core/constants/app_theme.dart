import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: false,
    fontFamily: 'Poppins',
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: const ColorScheme.light(
      primary:   AppColors.primary,
      secondary: AppColors.highlight,
      surface:   AppColors.surface,
      error:     AppColors.error,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textDark,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.textDark),
      titleTextStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.textDark,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navBarBg,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textGray,
      showUnselectedLabels: true,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnDark,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textDark,
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30),
        borderSide: const BorderSide(color: AppColors.highlight, width: 1.5),
      ),
      hintStyle: const TextStyle(
        color: AppColors.textGray,
        fontSize: 14,
        fontFamily: 'Poppins',
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge:  TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textDark),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textDark),
      titleLarge:     TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textDark),
      titleMedium:    TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark),
      bodyLarge:      TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textDark),
      bodyMedium:     TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textGray),
      labelLarge:     TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textBlue),
    ),
  );
}
