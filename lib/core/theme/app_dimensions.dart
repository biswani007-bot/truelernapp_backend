import 'package:flutter/material.dart';

/// Spacing, corner radii, and elevation constants based on Figma MCP inspection
/// File: TrueLern (CiZoTN0EnITFG3e7SFwXrU)
/// Page: Parent(full app)_TrueLern (Canvas 69:2)
abstract final class AppDimensions {
  // Spacing
  static const double space2 = 2.0;
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space10 = 10.0;
  static const double space12 = 12.0;
  static const double space14 = 14.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space28 = 28.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;

  // Screen Padding & Layout Margins
  static const double screenHorizontalPadding = 16.0;
  static const double cardPadding = 16.0;

  // Corner Radii (Exact Figma Node values)
  static const double radius6 = 6.0;
  static const double radius8 = 8.0; // Small pills, timetable date items
  static const double radius12 = 12.0; // Inputs, secondary buttons
  static const double radius16 =
      16.0; // Cards, timetable cards, quick action tiles
  static const double radius20 = 20.0; // Hero containers, modal sheets
  static const double radius24 =
      24.0; // Auth containers, Bottom Nav bar top corners
  static const double radiusFull = 9999.0; // Capsule chips / avatar circles

  // BorderRadius objects
  static const BorderRadius borderRadius8 = BorderRadius.all(
    Radius.circular(radius8),
  );
  static const BorderRadius borderRadius12 = BorderRadius.all(
    Radius.circular(radius12),
  );
  static const BorderRadius borderRadius16 = BorderRadius.all(
    Radius.circular(radius16),
  );
  static const BorderRadius borderRadius20 = BorderRadius.all(
    Radius.circular(radius20),
  );
  static const BorderRadius borderRadius24 = BorderRadius.all(
    Radius.circular(radius24),
  );
  static const BorderRadius borderRadiusPill = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // Bottom Navigation Dimensions & Radius
  static const BorderRadius navBarRadius = BorderRadius.only(
    topLeft: Radius.circular(24.0),
    topRight: Radius.circular(24.0),
  );

  // Box Shadows (Exact Figma Effects)
  // Card soft drop shadow (Figma 0px 4px 20px rgba(0,0,0,0.04))
  static const List<BoxShadow> cardShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 20.0,
      offset: Offset(0, 4),
    ),
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.02),
      blurRadius: 4.0,
      offset: Offset(0, 1),
    ),
  ];

  // Primary Button Glow (Figma #0037B1 20-25% opacity)
  static const List<BoxShadow> buttonShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 55, 177, 0.22),
      blurRadius: 14.0,
      offset: Offset(0, 4),
    ),
  ];

  // Bottom Nav Bar subtle top shadow
  static const List<BoxShadow> navBarShadow = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.04),
      blurRadius: 20.0,
      offset: Offset(0, -4),
    ),
  ];
}
