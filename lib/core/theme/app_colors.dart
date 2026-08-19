import 'package:flutter/material.dart';

class AppColors {
  // Deep Cyber-Onyx & Slate Backgrounds
  static const Color bgOnyx = Color(0xFF080A0F);
  static const Color bgSurface = Color(0xFF0E131A);
  static const Color bgCard = Color(0xFF141A23);
  static const Color bgCardHover = Color(0xFF1B2330);
  static const Color bgCardElevated = Color(0xFF1E2634);
  static const Color bgInput = Color(0xFF121721);
  static const Color bgGlass = Color(0xD90E131A);
  static const Color bgGlassCard = Color(0xCC141A23);
  static const Color bgGlassFloating = Color(0xE6141A23);

  // Vibrant Neon Accents
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color cyanGlow = Color(0x3300F0FF);
  static const Color cyanGlowIntense = Color(0x6600F0FF);

  static const Color neonViolet = Color(0xFF8B5CF6);
  static const Color violetGlow = Color(0x338B5CF6);
  static const Color violetGlowIntense = Color(0x668B5CF6);

  static const Color neonEmerald = Color(0xFF10B981);
  static const Color emeraldGlow = Color(0x3310B981);

  static const Color neonCoral = Color(0xFFF43F5E);
  static const Color coralGlow = Color(0x33F43F5E);

  static const Color neonAmber = Color(0xFFF59E0B);
  static const Color amberGlow = Color(0x33F59E0B);

  static const Color neonIndigo = Color(0xFF6366F1);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textCyan = Color(0xFF38BDF8);

  // Cyber Gradients
  static const LinearGradient cyanVioletGradient = LinearGradient(
    colors: [Color(0xFF00F0FF), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient violetIndigoGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldCyanGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF00F0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coralAmberGradient = LinearGradient(
    colors: [Color(0xFFF43F5E), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroCardGradient = LinearGradient(
    colors: [Color(0xFF1A2332), Color(0xFF0E131A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient activeVoiceGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF00F0FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF161C26), Color(0xFF0E131A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Borders & Glows
  static const Color borderSubtle = Color(0xFF1E293B);
  static const Color borderGlow = Color(0xFF334155);
  static const Color borderHighlight = Color(0xFF475569);
}

