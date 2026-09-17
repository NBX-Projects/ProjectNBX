import 'package:flutter/material.dart';

/// Design System: Standardized Border Radius Tokens for ProjectNBX
/// Provides consistent curved corners across all UI components.
class AppRadius {
  AppRadius._();

  /// Micro elements: tooltips, tiny badges, indicators, tags (4px)
  static const double xs = 4.0;
  static const Radius radiusXs = Radius.circular(xs);
  static const BorderRadius borderXs = BorderRadius.all(radiusXs);

  /// Small controls: chips, tags, dropdown items, secondary buttons (8px)
  static const double sm = 8.0;
  static const Radius radiusSm = Radius.circular(sm);
  static const BorderRadius borderSm = BorderRadius.all(radiusSm);

  /// Medium controls: text inputs, search fields, list tiles, dialog items (12px)
  static const double md = 12.0;
  static const Radius radiusMd = Radius.circular(md);
  static const BorderRadius borderMd = BorderRadius.all(radiusMd);

  /// Large structural elements: cards, server cards, panels, modals, dialogs (16px)
  static const double lg = 16.0;
  static const Radius radiusLg = Radius.circular(lg);
  static const BorderRadius borderLg = BorderRadius.all(radiusLg);

  /// Inset corners for banners inside 16px cards with 1px borders (15px) to prevent anti-aliasing seams
  static const Radius radiusLgInset = Radius.circular(15.0);
  static const BorderRadius topLg = BorderRadius.vertical(top: radiusLgInset);
  static const BorderRadius bottomLgInset = BorderRadius.vertical(bottom: radiusLgInset);
  static const BorderRadius borderLgInset = BorderRadius.all(radiusLgInset);

  /// Vertical / Directional combinations
  static const BorderRadius topSm = BorderRadius.vertical(top: radiusSm);
  static const BorderRadius topMd = BorderRadius.vertical(top: radiusMd);
  static const BorderRadius bottomSm = BorderRadius.vertical(bottom: radiusSm);
  static const BorderRadius bottomMd = BorderRadius.vertical(bottom: radiusMd);
  static const BorderRadius bottomLg = BorderRadius.vertical(bottom: radiusLg);

  /// Fully rounded pills & circles: primary pill buttons, status pills, avatars (9999px)
  static const double pill = 9999.0;
  static const Radius radiusPill = Radius.circular(pill);
  static const BorderRadius borderPill = BorderRadius.all(radiusPill);

  /// Standard OutlinedBorders for Dialogs, Cards, Buttons, and Sheets
  static const OutlinedBorder shapeXs = RoundedRectangleBorder(borderRadius: borderXs);
  static const OutlinedBorder shapeSm = RoundedRectangleBorder(borderRadius: borderSm);
  static const OutlinedBorder shapeMd = RoundedRectangleBorder(borderRadius: borderMd);
  static const OutlinedBorder shapeLg = RoundedRectangleBorder(borderRadius: borderLg);
  static const OutlinedBorder shapePill = RoundedRectangleBorder(borderRadius: borderPill);
}
