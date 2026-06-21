import 'package:flutter/material.dart';

class AppColors {
  // Core palette (matches UI: deep navy + light periwinkle)
  static const Color primary       = Color(0xFF1B2A4A);   // dark navy
  static const Color primaryLight  = Color(0xFF2D3E6B);
  static const Color accent        = Color(0xFFB8C8E8);   // light periwinkle (card bg)
  static const Color accentMedium  = Color(0xFF8FA8D8);
  static const Color highlight     = Color(0xFF5B7EC9);   // blue for codes/labels

  // Background
  static const Color background    = Color(0xFFFFFFFF);
  static const Color surface       = Color(0xFFFFFFFF);
  static const Color cardGray      = Color(0xFFEEEEEE);   // unselected course card
  static const Color cardBlue      = Color(0xFFD8E3F5);   // selected / enrolled card
  static const Color inputFill     = Color(0xFFF0F0F0);
  static const Color navBarBg      = Color(0xFFFFFFFF);

  // Text
  static const Color textDark      = Color(0xFF1B2A4A);
  static const Color textGray      = Color(0xFF8B9AB0);
  static const Color textBlue      = Color(0xFF5B7EC9);   // course codes
  static const Color textOnDark    = Color(0xFFFFFFFF);
  static const Color textRed       = Color(0xFFCC3333);   // logout

  // Status
  static const Color error         = Color(0xFFE53935);
  static const Color success       = Color(0xFF43A047);
  static const Color warning       = Color(0xFFFF9800);

  // Divider
  static const Color divider       = Color(0xFFEEEEEE);
}
