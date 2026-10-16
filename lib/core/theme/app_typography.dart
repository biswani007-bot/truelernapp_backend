import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized typography definitions derived directly from Figma MCP inspection.
/// Primary Font Family: Hanken Grotesk (Node 76:3476, Node 76:1820)
/// Secondary Font Family: Be Vietnam Pro (Node 71:232 auth/inputs)
abstract final class AppTypography {
  // Display / Hero Headings (Hanken Grotesk Bold 700)
  static TextStyle get displayLarge => GoogleFonts.hankenGrotesk(
    fontSize: 34.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  static TextStyle get displayMedium => GoogleFonts.hankenGrotesk(
    fontSize: 30.0,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
    color: AppColors.textPrimary,
  );

  // Screen Titles / App Bar: 21.5px, Bold (700) or SemiBold (600)
  static TextStyle get titleLarge => GoogleFonts.hankenGrotesk(
    fontSize: 21.5,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    height: 1.25,
    color: AppColors.textPrimary,
  );

  // Section Headers / Card Titles: 17px, SemiBold (600)
  static TextStyle get titleMedium => GoogleFonts.hankenGrotesk(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    height: 1.35,
    color: AppColors.textPrimary,
  );

  // Subtitles / Card Subheaders: 15px, Medium (500)
  static TextStyle get titleSmall => GoogleFonts.hankenGrotesk(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );

  // Body Text: 15-17px Regular / Medium
  static TextStyle get bodyLarge => GoogleFonts.hankenGrotesk(
    fontSize: 17.0,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => GoogleFonts.hankenGrotesk(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    height: 1.42,
    color: AppColors.textSecondary,
  );

  static TextStyle get bodyMediumEmphasis => GoogleFonts.hankenGrotesk(
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
    height: 1.42,
    color: AppColors.textPrimary,
  );

  // Captions & Metadata: 13px Medium
  static TextStyle get bodySmall => GoogleFonts.hankenGrotesk(
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    height: 1.33,
    color: AppColors.textMuted,
  );

  // Pills, Chips, Timetable Badges: 12-15px Medium/SemiBold
  static TextStyle get labelLarge => GoogleFonts.hankenGrotesk(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelMedium => GoogleFonts.hankenGrotesk(
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelSmall => GoogleFonts.hankenGrotesk(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
    height: 1.3,
    color: AppColors.textSecondary,
  );

  // Primary Button Text: 15px SemiBold
  static TextStyle get buttonText => GoogleFonts.hankenGrotesk(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textInverse,
  );

  // Auth / Form Inputs (Be Vietnam Pro from Figma auth spec)
  static TextStyle get inputLabel => GoogleFonts.beVietnamPro(
    fontSize: 15.0,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static TextStyle get inputText => GoogleFonts.beVietnamPro(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get inputHint => GoogleFonts.beVietnamPro(
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
  );
}
