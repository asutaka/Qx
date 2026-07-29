import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Định nghĩa kiểu chữ (Typography) cho Quiz Arena sử dụng Google Fonts.
class AppTypography {
  static TextStyle get titleStyle => GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );

  static TextStyle get subtitleStyle => GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodyStyle => GoogleFonts.outfit(
        fontSize: 14,
        color: AppColors.textPrimary,
      );

  static TextStyle get buttonStyle => GoogleFonts.spaceGrotesk(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      );
}
