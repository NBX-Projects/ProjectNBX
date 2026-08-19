import 'package:flutter/material.dart';

class AppColors {
  // Deep Cyber-Onyx Backgrounds
  static const Color bgOnyx = Color(0xFF090A0F);
  static const Color bgSurface = Color(0xFF0F1218);
  static const Color bgCard = Color(0xFF161B22);
  static const Color bgCardHover = Color(0xFF1F242D);
  static const Color bgInput = Color(0xFF141820);
  static const Color bgGlass = Color(0xCC121720);

  // Futuristic Neon Accents
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color cyanGlow = Color(0x3300F0FF);
  static const Color neonViolet = Color(0xFF9D4EDD);
  static const Color violetGlow = Color(0x339D4EDD);
  static const Color neonEmerald = Color(0xFF00FF9D);
  static const Color emeraldGlow = Color(0x3300FF9D);
  static const Color neonCoral = Color(0xFFFF3366);
  static const Color coralGlow = Color(0x33FF3366);
  static const Color neonAmber = Color(0xFFFFB703);

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);
  static const Color textCyan = Color(0xFF58A6FF);

  // Cyber Gradients
  static const LinearGradient cyanVioletGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF9D4EDD)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeVoiceGradient = LinearGradient(
    colors: [Color(0xFF00FF9D), Color(0xFF00F0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF161B22), Color(0xFF0F1218)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Borders & Glows
  static const Color borderSubtle = Color(0xFF21262D);
  static const Color borderGlow = Color(0xFF30363D);
}
