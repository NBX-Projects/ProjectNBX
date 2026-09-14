import 'package:flutter/material.dart';

class AppColors {
  // ==========================================
  // 🌑 DARK THEME (Matte Charcoal & Pastel Tech)
  // Reference: Pastel Tech Aesthetic
  // ==========================================
  static const Color darkCanvas = Color(0xFF181926); // Deep Matte Charcoal
  static const Color darkSurface = Color(0xFF1E2030); // Structural Card Panels
  static const Color darkSurfaceElevated = Color(
    0xFF24273A,
  ); // Floating Overlays & Hovers
  static const Color darkInput = Color(0xFF141520); // Inset Input Fields
  static const Color darkBorder = Color(0xFF313244); // Precision 1px Frame
  static const Color darkBorderFocus = Color(0xFF3B4252); // Interactive Border

  // Dark Mineral Pastels
  static const Color darkPrimary = Color(
    0xFFF5CBA7,
  ); // Warm Pastel Peach / Apricot
  static const Color darkPrimaryHover = Color(0xFFE4BC98);
  static const Color darkSage = Color(
    0xFFA8C5B5,
  ); // Pastel Sage Green (Active/Success)
  static const Color darkLavender = Color(0xFFC5B4E3); // Soft Lavender / Lilac
  static const Color darkPowderBlue = Color(
    0xFFA5C4D4,
  ); // Powder Blue (Tech/Code)
  static const Color darkDanger = Color(0xFFF38BA8); // Pastel Coral / Red

  // Dark Typography
  static const Color darkTextPrimary = Color(0xFFE6E9EF); // Creamy White
  static const Color darkTextSecondary = Color(0xFFBAC2DE); // Soft Muted Gray
  static const Color darkTextMuted = Color(0xFF6E738D); // Subtext & Metadata

  // ==========================================
  // ☀️ LIGHT THEME (Forest Slate & Daylight Pastel)
  // Reference: Forest Slate Engineering Portfolio
  // ==========================================
  static const Color lightCanvas = Color(0xFFFAF9F6); // Alabaster Cream
  static const Color lightSurface = Color(0xFFFFFFFF); // Pure White Cards
  static const Color lightSurfaceElevated = Color(0xFFE8F2EC); // Soft Sage Tint
  static const Color lightInput = Color(0xFFFFFFFF); // Input Background
  static const Color lightBorder = Color(0xFFE2E8F0); // Subtle Border
  static const Color lightBorderFocus = Color(0xFFCBD5E1);

  // Light Chromatic Accents
  static const Color lightPrimary = Color(0xFF2D6A4F); // Forest Sage
  static const Color lightPrimaryHover = Color(0xFF1B4332);
  static const Color lightSage = Color(
    0xFF2D6A4F,
  ); // Forest Sage (Active/Success)
  static const Color lightLavender = Color(0xFF5B4282); // Deep Royal Lavender
  static const Color lightSkyBlue = Color(0xFF2C5E8A); // Deep Slate Blue
  static const Color lightPeach = Color(0xFFA05022); // Terracotta Peach
  static const Color lightDanger = Color(0xFFDC2626); // Deep Crimson

  static const Color lightTextPrimary = Color(
    0xFF1E293B,
  ); // Deep Slate Graphite
  static const Color lightTextSecondary = Color(0xFF475569); // Muted Slate Gray
  static const Color lightTextMuted = Color(0xFF64748B); // Secondary Slate

  // ==========================================
  // 🎨 SERVER BANNER & ACCENT PRESETS
  // ==========================================
  static const List<List<Color>> bannerPresets = [
    [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4338CA)],
    [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
    [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF059669)],
    [Color(0xFF450A0A), Color(0xFF7F1D1D), Color(0xFF991B1B)],
    [Color(0xFF3B0764), Color(0xFF581C87), Color(0xFF6B21A8)],
  ];

  static const List<Color> serverAccentPalette = [
    Color(0xFFF5CBA7), // Pastel Peach
    Color(0xFF4ADE80), // Pastel Sage
    Color(0xFF38BDF8), // Cyan Blue
    Color(0xFFF87171), // Coral Red
    Color(0xFFC084FC), // Soft Lavender
  ];

  static List<Color> getBannerGradient(int presetIndex, [String fallbackId = '']) {
    if (presetIndex >= 0 && presetIndex < bannerPresets.length) {
      return bannerPresets[presetIndex];
    }
    if (fallbackId.isNotEmpty) {
      final hash = fallbackId.hashCode.abs() % bannerPresets.length;
      return bannerPresets[hash];
    }
    return bannerPresets[0];
  }
}

