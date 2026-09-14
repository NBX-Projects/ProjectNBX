import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/localization/app_language.dart';
import 'package:projectnbx/core/localization/app_strings.dart';
import 'package:projectnbx/core/localization/locale_controller.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
import 'package:projectnbx/features/voice/controllers/audio_devices_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SettingsScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _selectedSection = 'account';

  // Voice Settings State
  double _inputVolume = 0.85;
  double _outputVolume = 0.90;
  bool _isPushToTalk = false;
  final String _pttKey = 'CAPS LOCK';
  bool _noiseSuppression = true;
  bool _echoCancellation = true;
  bool _dtxEnabled = true;

  // Account Status
  String _userStatus = 'online';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final strings = ref.watch(stringsProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Settings Navigation Sidebar
            _buildSettingsSidebar(context, isDark, strings),

            // Vertical Divider
            Container(
              width: 1,
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),

            // Right Main Settings Content
            Expanded(
              child: Container(
                alignment: Alignment.topLeft,
                color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 36,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: _buildSectionContent(isDark, user, strings),
                        ),
                      ),
                    ),

                    // Close / ESC Button at Top Right
                    Positioned(
                      top: 24,
                      right: 32,
                      child: _buildCloseButton(context, isDark),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SIDEBAR
  // ===========================================================================
  Widget _buildSettingsSidebar(
    BuildContext context,
    bool isDark,
    AppStrings strings,
  ) {
    return Container(
      width: 240,
      color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkPrimary
                        : AppColors.lightPrimary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    LucideIcons.settings,
                    size: 16,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  strings.settingsTitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),

          _buildSidebarCategory(isDark, strings.userCategory),
          _buildSidebarItem(
            id: 'account',
            title: strings.myAccount,
            icon: LucideIcons.user,
            isDark: isDark,
          ),
          _buildSidebarItem(
            id: 'appearance',
            title: strings.appearanceAndLanguage,
            icon: LucideIcons.palette,
            isDark: isDark,
          ),

          const SizedBox(height: 16),
          _buildSidebarCategory(isDark, 'ÁUDIO & CONTROLES'),
          _buildSidebarItem(
            id: 'voice',
            title: strings.voiceAndVideo,
            icon: LucideIcons.mic,
            isDark: isDark,
          ),
          _buildSidebarItem(
            id: 'hotkeys',
            title: strings.hotkeysAndPTT,
            icon: LucideIcons.keyboard,
            isDark: isDark,
          ),

          const SizedBox(height: 16),
          _buildSidebarCategory(isDark, 'SISTEMA'),
          _buildSidebarItem(
            id: 'system',
            title: strings.systemStatusTitle,
            icon: LucideIcons.activity,
            isDark: isDark,
          ),

          const Spacer(),

          // Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () {
                Navigator.of(context).pop();
                ref.read(authControllerProvider.notifier).logout();
              },
              mouseCursor: SystemMouseCursors.click,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                      .withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                        (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                            .withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.logOut,
                      size: 16,
                      color: isDark
                          ? AppColors.darkDanger
                          : AppColors.lightDanger,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      strings.logOut,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkDanger
                            : AppColors.lightDanger,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarCategory(bool isDark, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 8, bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
        ),
      ),
    );
  }

  Widget _buildSidebarItem({
    required String id,
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    final isSelected = _selectedSection == id;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => setState(() => _selectedSection = id),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceElevated)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: isDark
                        ? AppColors.darkBorderFocus
                        : AppColors.lightBorderFocus,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    : (isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? (isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary)
                        : (isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCloseButton(BuildContext context, bool isDark) {
    return Column(
      children: [
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          mouseCursor: SystemMouseCursors.click,
          borderRadius: BorderRadius.circular(9999),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Icon(
              LucideIcons.x,
              size: 16,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'ESC',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // SECTIONS
  // ===========================================================================
  Widget _buildSectionContent(
    bool isDark,
    UserModel? user,
    AppStrings strings,
  ) {
    switch (_selectedSection) {
      case 'account':
        return _buildAccountSection(isDark, user, strings);
      case 'appearance':
        return _buildAppearanceSection(isDark, strings);
      case 'voice':
        return _buildVoiceSection(isDark, strings);
      case 'hotkeys':
        return _buildHotkeysSection(isDark, strings);
      case 'system':
        return _buildSystemSection(isDark, strings);
      default:
        return _buildAccountSection(isDark, user, strings);
    }
  }

  // 1. MINHA CONTA
  Widget _buildAccountSection(
    bool isDark,
    UserModel? user,
    AppStrings strings,
  ) {
    final username = user?.username ?? 'Sr. 6Seven';
    final email = user?.email ?? 'dev@projectnbx.com';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderTitle(
          isDark,
          strings.myAccount,
          strings.accountDescription,
        ),
        const SizedBox(height: 24),

        // User Profile Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkLavender
                          : AppColors.lightLavender,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        username.isNotEmpty ? username[0].toUpperCase() : 'U',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: isDark
                                ? AppColors.darkTextMuted
                                : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: (isDark ? AppColors.darkSage : AppColors.lightSage)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color:
                            (isDark ? AppColors.darkSage : AppColors.lightSage)
                                .withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      strings.connected,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkSage
                            : AppColors.lightSage,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Divider(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              const SizedBox(height: 16),
              _buildAccountRow(
                isDark,
                strings.currentStatus,
                _userStatus == 'online'
                    ? strings.currentStatusOnline
                    : strings.currentStatusAway,
                action: DropdownButton<String>(
                  value: _userStatus,
                  dropdownColor: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  underline: const SizedBox(),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'online',
                      child: Text('🟢 ${strings.online}'),
                    ),
                    DropdownMenuItem(
                      value: 'idle',
                      child: Text('🟡 ${strings.idle}'),
                    ),
                    DropdownMenuItem(
                      value: 'dnd',
                      child: Text('🔴 ${strings.dnd}'),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _userStatus = val);
                  },
                ),
              ),
              const SizedBox(height: 12),
              _buildAccountRow(
                isDark,
                strings.securitySession,
                strings.sessionActive,
                badgeText: strings.active,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountRow(
    bool isDark,
    String label,
    String value, {
    String? badgeText,
    Widget? action,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
        ?action,
        if (badgeText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              badgeText,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
              ),
            ),
          ),
      ],
    );
  }

  // 2. APARÊNCIA & IDIOMA
  Widget _buildAppearanceSection(bool isDark, AppStrings strings) {
    final currentLang = ref.watch(localeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderTitle(
          isDark,
          strings.appearanceAndLanguage,
          strings.appearanceDescription,
        ),
        const SizedBox(height: 24),

        Text(
          strings.themeSelector,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            // Dark Mode Option (Pastel Tech)
            Expanded(
              child: _buildThemeOptionCard(
                title: strings.darkThemeTitle,
                subtitle: strings.darkThemeSubtitle,
                isSelected: isDark,
                icon: LucideIcons.moon,
                previewBg: const Color(0xFF181926),
                accentColor: const Color(0xFFF5CBA7),
                isDark: isDark,
                onTap: () {
                  if (!isDark) {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  }
                },
              ),
            ),
            const SizedBox(width: 14),

            // Light Mode Option (Forest Slate)
            Expanded(
              child: _buildThemeOptionCard(
                title: strings.lightThemeTitle,
                subtitle: strings.lightThemeSubtitle,
                isSelected: !isDark,
                icon: LucideIcons.sun,
                previewBg: const Color(0xFFFAF9F6),
                accentColor: const Color(0xFF2D6A4F),
                isDark: isDark,
                onTap: () {
                  if (isDark) {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // Language Selector
        Text(
          strings.languageSelector,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: AppLanguage.values.map((lang) {
            final isSelected = currentLang == lang;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: InkWell(
                  onTap: () {
                    ref.read(localeProvider.notifier).setLanguage(lang);
                  },
                  mouseCursor: SystemMouseCursors.click,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                            : (isDark
                                  ? AppColors.darkBorder
                                  : AppColors.lightBorder),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lang.name,
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            LucideIcons.check,
                            size: 16,
                            color: isDark
                                ? AppColors.darkPrimary
                                : AppColors.lightPrimary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildThemeOptionCard({
    required String title,
    required String subtitle,
    required bool isSelected,
    required IconData icon,
    required Color previewBg,
    required Color accentColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: previewBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(9999),
                  ),
                  child: Text(
                    'Preview',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isSelected && isDark ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSelected
                      ? (isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary)
                      : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. VOZ & ÁUDIO
  Widget _buildVoiceSection(bool isDark, AppStrings strings) {
    final audioState = ref.watch(audioDevicesProvider);
    final audioNotifier = ref.read(audioDevicesProvider.notifier);

    final inputItems = audioState.inputDevices.isNotEmpty
        ? audioState.inputDevices.map((d) {
            final label = d.label.isNotEmpty
                ? d.label
                : 'Microfone (${d.deviceId.substring(0, d.deviceId.length.clamp(0, 8))})';
            return DropdownMenuItem(
              value: d.deviceId,
              child: Text(label, overflow: TextOverflow.ellipsis),
            );
          }).toList()
        : [
            const DropdownMenuItem(
              value: 'default',
              child: Text('Microfone Padrão do Sistema'),
            ),
          ];

    final outputItems = audioState.outputDevices.isNotEmpty
        ? audioState.outputDevices.map((d) {
            final label = d.label.isNotEmpty
                ? d.label
                : 'Alto-falantes (${d.deviceId.substring(0, d.deviceId.length.clamp(0, 8))})';
            return DropdownMenuItem(
              value: d.deviceId,
              child: Text(label, overflow: TextOverflow.ellipsis),
            );
          }).toList()
        : [
            const DropdownMenuItem(
              value: 'default',
              child: Text('Alto-falantes Padrão do Sistema'),
            ),
          ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeaderTitle(
              isDark,
              strings.voiceAndVideo,
              strings.voiceDescription,
            ),
            Tooltip(
              message: 'Detectar novos microfones e fones conectados',
              child: InkWell(
                onTap: audioState.isLoading
                    ? null
                    : () => audioNotifier.loadDevices(),
                mouseCursor: SystemMouseCursors.click,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (audioState.isLoading)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Icon(
                          LucideIcons.refreshCw,
                          size: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      const SizedBox(width: 6),
                      Text(
                        'Reescanear',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Device Selectors
        _buildDeviceDropdown(
          isDark,
          strings.inputDevice,
          audioState.selectedInputDeviceId,
          inputItems,
          (val) {
            if (val != null) audioNotifier.selectInputDevice(val);
          },
        ),

        const SizedBox(height: 14),

        // Input Volume Slider
        _buildSliderRow(
          isDark,
          strings.inputVolume,
          _inputVolume,
          (val) => setState(() => _inputVolume = val),
        ),

        const SizedBox(height: 20),

        _buildDeviceDropdown(
          isDark,
          strings.outputDevice,
          audioState.selectedOutputDeviceId,
          outputItems,
          (val) {
            if (val != null) audioNotifier.selectOutputDevice(val);
          },
        ),

        const SizedBox(height: 14),

        // Output Volume Slider
        _buildSliderRow(
          isDark,
          strings.outputVolume,
          _outputVolume,
          (val) => setState(() => _outputVolume = val),
        ),

        const SizedBox(height: 24),
        Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        const SizedBox(height: 20),

        // Voice Processing Toggles
        Text(
          strings.audioProcessing,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 12),

        _buildSwitchTile(
          isDark,
          strings.noiseSuppression,
          strings.noiseSuppressionDesc,
          _noiseSuppression,
          (val) => setState(() => _noiseSuppression = val),
        ),
        _buildSwitchTile(
          isDark,
          strings.echoCancellation,
          strings.echoCancellationDesc,
          _echoCancellation,
          (val) => setState(() => _echoCancellation = val),
        ),
        _buildSwitchTile(
          isDark,
          strings.vadOptimization,
          strings.vadOptimizationDesc,
          _dtxEnabled,
          (val) => setState(() => _dtxEnabled = val),
        ),
      ],
    );
  }

  Widget _buildDeviceDropdown(
    bool isDark,
    String label,
    String? currentValue,
    List<DropdownMenuItem<String>> items,
    ValueChanged<String?> onChanged,
  ) {
    final safeValue =
        (currentValue != null && items.any((it) => it.value == currentValue))
        ? currentValue
        : (items.isNotEmpty ? items.first.value : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
          ),
          child: DropdownButton<String>(
            value: safeValue,
            isExpanded: true,
            underline: const SizedBox(),
            dropdownColor: isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
            items: items,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSliderRow(
    bool isDark,
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: isDark
                  ? AppColors.darkPrimary
                  : AppColors.lightPrimary,
              inactiveTrackColor: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              thumbColor: isDark
                  ? AppColors.darkPrimary
                  : AppColors.lightPrimary,
              overlayColor:
                  (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                      .withValues(alpha: 0.2),
              trackHeight: 4,
            ),
            child: Slider(
              value: value,
              min: 0.0,
              max: 1.0,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 45,
          child: Text(
            '${(value * 100).toInt()}%',
            textAlign: TextAlign.right,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile(
    bool isDark,
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: isDark
                ? AppColors.darkPrimary
                : AppColors.lightPrimary,
            activeTrackColor:
                (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                    .withValues(alpha: 0.38),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // 4. ATALHOS & PTT
  Widget _buildHotkeysSection(bool isDark, AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderTitle(
          isDark,
          strings.hotkeysAndPTT,
          strings.hotkeysDescription,
        ),
        const SizedBox(height: 24),

        // Input Mode Selection
        Text(
          strings.inputMode,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: _buildInputModeCard(
                title: strings.voiceActivity,
                description: strings.voiceActivityDesc,
                isSelected: !_isPushToTalk,
                icon: LucideIcons.mic,
                isDark: isDark,
                onTap: () => setState(() => _isPushToTalk = false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInputModeCard(
                title: strings.pushToTalk,
                description: strings.pushToTalkDesc,
                isSelected: _isPushToTalk,
                icon: LucideIcons.radio,
                isDark: isDark,
                onTap: () => setState(() => _isPushToTalk = true),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        if (_isPushToTalk) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.pttKeyLabel,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      strings.pttKeyDesc,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorderFocus
                          : AppColors.lightBorderFocus,
                    ),
                  ),
                  child: Text(
                    _pttKey,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],

        // Global Shortcuts List
        Text(
          strings.globalShortcuts,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 10),

        _buildHotkeyRow(isDark, strings.muteUnmuteAction, 'Ctrl + Shift + M'),
        _buildHotkeyRow(isDark, strings.deafenAction, 'Ctrl + Shift + D'),
        _buildHotkeyRow(isDark, strings.searchShortcut, 'Ctrl + K'),
        _buildHotkeyRow(isDark, strings.toggleThemeShortcut, 'Ctrl + T'),
      ],
    );
  }

  Widget _buildInputModeCard({
    required String title,
    required String description,
    required bool isSelected,
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? (isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary)
                      : (isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark
                    ? AppColors.darkTextMuted
                    : AppColors.lightTextMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHotkeyRow(bool isDark, String action, String shortcut) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            action,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isDark
                    ? AppColors.darkBorderFocus
                    : AppColors.lightBorderFocus,
              ),
            ),
            child: Text(
              shortcut,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.darkTextPrimary
                    : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. STATUS DOS SERVIÇOS & REDE
  Widget _buildSystemSection(bool isDark, AppStrings strings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderTitle(
          isDark,
          strings.systemStatusTitle,
          strings.systemStatusDesc,
        ),
        const SizedBox(height: 24),

        _buildServiceStatusCard(
          isDark: isDark,
          serviceName: 'Banco de Dados & Storage',
          endpoint: 'Armazenamento seguro de canais, contas e servidores',
          status: 'ONLINE & SINCRONIZADO',
          icon: LucideIcons.database,
          accentColor: isDark ? AppColors.darkSage : AppColors.lightSage,
        ),
        const SizedBox(height: 12),

        _buildServiceStatusCard(
          isDark: isDark,
          serviceName: 'Servidor de Voz & Transmissão',
          endpoint:
              'Áudio cristalino de alta fidelidade com latência ultrabaixa',
          status: 'PRONTO (< 50ms)',
          icon: LucideIcons.radio,
          accentColor: isDark
              ? AppColors.darkLavender
              : AppColors.lightLavender,
        ),
        const SizedBox(height: 12),

        _buildServiceStatusCard(
          isDark: isDark,
          serviceName: 'API Gateway & WebSocket Hub',
          endpoint:
              'Sincronização em tempo real de mensagens e status de presença',
          status: 'CONECTADO',
          icon: LucideIcons.server,
          accentColor: isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
        ),
      ],
    );
  }

  Widget _buildServiceStatusCard({
    required bool isDark,
    required String serviceName,
    required String endpoint,
    required String status,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  serviceName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  endpoint,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeaderTitle(
    bool isDark,
    String title,
    String description,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
      ],
    );
  }
}
