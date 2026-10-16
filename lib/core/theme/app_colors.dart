import 'package:flutter/material.dart';

/// Authoritative color tokens derived directly from Figma MCP inspection
/// File: TrueLern (CiZoTN0EnITFG3e7SFwXrU)
/// Page: Parent(full app)_TrueLern (Canvas 69:2)
/// Exact primary spec: Node 71:3 ("App Icon Launcher" brand spec #0037B1)
abstract final class AppColors {
  // Figma Exact Brand Primary Palette (#0037B1)
  static const Color primary = Color(0xFF0037B1); // Figma Brand Blue #0037b1
  static const Color primaryDark = Color(
    0xFF002B8C,
  ); // Figma Deep Blue (pressed/shading)
  static const Color primaryLight = Color(
    0xFF1E4ED8,
  ); // Figma Bright Blue variant
  static const Color primaryTonal = Color(
    0xFFE0E7FF,
  ); // Primary soft pill / active background

  // Figma Exact Accent Palette (Classes/Timetable & Status)
  static const Color accentCyan = Color(
    0xFF22D3EE,
  ); // Active card pill / highlight
  static const Color accentCyanBg = Color(
    0x1A22D3EE,
  ); // 10% opacity Cyan pill bg
  static const Color accentTeal = Color(0xFF14B8A6); // Schedule / subject pill
  static const Color accentTealBg = Color(
    0x1A14B8A6,
  ); // 10% opacity Teal pill bg
  static const Color accentOrange = Color(
    0xFFF97316,
  ); // Progress / alert accent

  // Figma Exact Canvas & Surface Gradients
  // Dashboard canvas gradient (Node 76:3476): 106.91deg #F3E8FF -> #E0F2FE -> #FFFFFF
  static const Color canvasGradientStart = Color(
    0xFFF3E8FF,
  ); // Soft lavender top-left
  static const Color canvasGradientMid = Color(0xFFE0F2FE); // Soft sky blue mid
  static const Color canvasGradientEnd = Color(
    0xFFFFFFFF,
  ); // Pure white bottom-right
  static const List<Color> canvasGradient = [
    canvasGradientStart,
    canvasGradientMid,
    canvasGradientEnd,
  ];

  // Frosted Glassmorphism Surfaces
  static const Color surfaceGlass = Color(
    0xCCFAF8FF,
  ); // rgba(250, 248, 255, 0.8)
  static const Color surfaceGlassBorder = Color(
    0x80FFFFFF,
  ); // rgba(255, 255, 255, 0.5)

  // Standard Surfaces
  static const Color background = Color(
    0xFFFAF8FF,
  ); // Figma Parent Canvas background
  static const Color surface = Color(0xFFFFFFFF); // Pure White Card Surface
  static const Color surfaceSecondary = Color(
    0xFFF1F5F9,
  ); // Secondary Pill / Filter Surface
  static const Color surfaceElevated = Color(0xFFFFFFFF);

  // Backward compatibility / dark slate surfaces
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);

  // Dividers & Borders
  static const Color border = Color(0xFFE2E8F0); // Subtle Border / Divider
  static const Color borderMedium = Color(0xFFCBD5E1);
  static const Color borderLight = Color(0xFFF1F5F9);

  // Text Hierarchy (Hanken Grotesk / Be Vietnam Pro colors)
  static const Color textPrimary = Color(
    0xFF0F172A,
  ); // High-contrast headline / body
  static const Color textSecondary = Color(0xFF475569); // Subtitles / metadata
  static const Color textMuted = Color(
    0xFF94A3B8,
  ); // Placeholders / inactive labels
  static const Color textDisabled = Color(0xFFCBD5E1);
  static const Color textInverse = Color(
    0xFFFFFFFF,
  ); // Pure white on primary surfaces

  // Semantic Status: Success / Present
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF059669);
  static const Color successBg = Color(0xFFECFDF5);

  // Semantic Status: Warning / Pending
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningDark = Color(0xFFD97706);
  static const Color warningBg = Color(0xFFFFFBEB);

  // Semantic Status: Error / Overdue / Absent
  static const Color error = Color(0xFFEF4444);
  static const Color errorDark = Color(0xFFDC2626);
  static const Color errorBg = Color(0xFFFEF2F2);

  // Bottom Navigation Bar
  static const Color navBackground = Color(0xFFFFFFFF);
  static const Color navActive = Color(0xFF0037B1);
  static const Color navInactive = Color(0xFF94A3B8);
}
