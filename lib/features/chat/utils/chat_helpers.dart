import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

String getAuthorInitials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  final parts = trimmed
      .split(RegExp(r'[\s_\-]+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  final single = parts.isNotEmpty ? parts.first : trimmed;
  if (single.length >= 2) {
    return single.substring(0, 2).toUpperCase();
  }
  return single.toUpperCase();
}

Color resolveAuthorColor(String name, bool isDark) {
  const darkPalette = [
    Color(0xFF38BDF8), // Sky Blue
    Color(0xFFC084FC), // Lavender / Soft Purple
    Color(0xFFF472B6), // Pink
    Color(0xFFFBBF24), // Amber / Warm Gold
    Color(0xFF34D399), // Emerald / Mint
    Color(0xFFFB923C), // Orange / Coral
    Color(0xFFA78BFA), // Pastel Violet
    Color(0xFF2DD4BF), // Cyan / Teal
    Color(0xFFF87171), // Pastel Red / Salmon
    Color(0xFFA3E635), // Pastel Lime
    Color(0xFF67E8F9), // Light Cyan
    Color(0xFFE879F9), // Fuchsia / Magenta
  ];
  const lightPalette = [
    Color(0xFF0284C7), // Deep Sky Blue
    Color(0xFF7C3AED), // Deep Purple
    Color(0xFFDB2777), // Deep Pink
    Color(0xFFD97706), // Deep Amber
    Color(0xFF059669), // Deep Emerald
    Color(0xFFEA580C), // Deep Orange
    Color(0xFF4F46E5), // Indigo
    Color(0xFF0D9488), // Deep Teal
    Color(0xFFDC2626), // Deep Red
    Color(0xFF65A30D), // Deep Lime
    Color(0xFF0891B2), // Deep Cyan
    Color(0xFFC026D3), // Deep Magenta
  ];
  final palette = isDark ? darkPalette : lightPalette;
  if (name.trim().isEmpty) return palette[0];
  int hash = 0;
  for (var i = 0; i < name.length; i++) {
    hash = (hash * 31 + name.codeUnitAt(i)) & 0x7FFFFFFF;
  }
  return palette[hash % palette.length];
}

class ChatAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final bool isDark;
  final double size;

  const ChatAvatar({
    super.key,
    required this.initials,
    required this.color,
    required this.isDark,
    this.size = 34,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.45 : 0.6),
          width: 1.2,
        ),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.jetBrainsMono(
            fontSize: size * 0.32,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ),
    );
  }
}
