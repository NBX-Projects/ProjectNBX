import 'package:flutter/material.dart';

/// Paleta de Cores Oficial do UX NBX (Figma 1:1)
class AppColors {
  // Backgrounds & Panels
  static const Color bg = Color(0xFF1A1D22);         // Fundo principal
  static const Color panel = Color(0xFF2B2F36);      // Cards e superfícies elevadas
  static const Color deep = Color(0xFF202225);       // Barra lateral e inputs
  static const Color input = Color(0xFF202225);
  static const Color card = Color(0xFF2B2F36);
  static const Color cardHover = Color(0xFF333842);

  // Cores de Acento & Status
  static const Color accent = Color(0xFF5865F2);     // Blurple Oficial
  static const Color primary = Color(0xFF5865F2);
  static const Color green = Color(0xFF43B581);      // Voz ativa / Online
  static const Color red = Color(0xFFF04747);        // Mudo / Desconectar / Perigo
  static const Color yellow = Color(0xFFFAA61A);     // Ausente / Warning / Nitro
  static const Color purple = Color(0xFF9B59B6);     // Dev / Booster
  
  // Tipografia & Textos
  static const Color text = Color(0xFFDCDDDE);       // Texto principal
  static const Color textPrimary = Color(0xFFDCDDDE);
  static const Color dim = Color(0xFFB9BBBE);        // Texto secundário
  static const Color textSecondary = Color(0xFFB9BBBE);
  static const Color muted = Color(0xFF8E9297);      // Timestamps e hashes
  static const Color textMuted = Color(0xFF8E9297);

  // Bordas & Divisórias
  static const Color border = Color(0x0FFFFFFF);     // rgba(255, 255, 255, 0.06)
  static const Color borderSubtle = Color(0x1AFFFFFF); // rgba(255, 255, 255, 0.10)
  static const Color borderGlow = Color(0x335865F2);

  // Gradients
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF5865F2), Color(0xFF7289DA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient voiceActiveGradient = LinearGradient(
    colors: [Color(0xFF43B581), Color(0xFF5865F2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
