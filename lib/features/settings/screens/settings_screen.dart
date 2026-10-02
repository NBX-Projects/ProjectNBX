import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/localization/app_strings.dart';
import 'package:justtalking/core/localization/locale_controller.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/core/widgets/window_controls.dart';
import 'package:justtalking/features/auth/controllers/auth_controller.dart';
import 'package:justtalking/features/auth/models/user_model.dart';
import 'package:justtalking/features/settings/widgets/sections/account_section.dart';
import 'package:justtalking/features/settings/widgets/sections/appearance_section.dart';
import 'package:justtalking/features/settings/widgets/sections/hotkeys_section.dart';
import 'package:justtalking/features/settings/widgets/sections/system_section.dart';
import 'package:justtalking/features/settings/widgets/sections/voice_section.dart';
import 'package:justtalking/features/settings/widgets/settings_sidebar.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final String? initialSection;
  final bool? supportsHotkeys;

  const SettingsScreen({super.key, this.initialSection, this.supportsHotkeys});

  static Future<void> show(
    BuildContext context, {
    String? initialSection,
    bool? supportsHotkeys,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SettingsScreen(
          initialSection: initialSection,
          supportsHotkeys: supportsHotkeys,
        ),
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
  late String _selectedSection;
  bool _mobileShowingDetail = false;
  final ScrollController _scrollController = ScrollController();

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  bool get _supportsHotkeys {
    if (widget.supportsHotkeys != null) {
      return widget.supportsHotkeys!;
    }
    if (!kIsWeb) {
      return !(Platform.isAndroid || Platform.isIOS);
    }
    return defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection ?? 'account';
    if (!_supportsHotkeys && _selectedSection == 'hotkeys') {
      _selectedSection = 'voice';
    }
    _mobileShowingDetail = widget.initialSection != null;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getSectionTitle(String section, AppStrings strings) {
    switch (section) {
      case 'account':
        return strings.myAccount;
      case 'appearance':
        return strings.appearanceAndLanguage;
      case 'voice':
        return strings.voiceAndVideo;
      case 'hotkeys':
        return _supportsHotkeys ? strings.hotkeysAndPTT : strings.voiceAndVideo;
      case 'system':
        return strings.systemStatusTitle;
      default:
        return strings.settingsTitle;
    }
  }

  Widget _buildSectionContent(
    bool isDark,
    UserModel? user,
    AppStrings strings, {
    bool isMobile = false,
  }) {
    switch (_selectedSection) {
      case 'account':
        return AccountSection(
          isDark: isDark,
          user: user,
          strings: strings,
          isMobile: isMobile,
        );
      case 'appearance':
        return AppearanceSection(
          isDark: isDark,
          strings: strings,
          isMobile: isMobile,
        );
      case 'voice':
        return VoiceSection(
          isDark: isDark,
          strings: strings,
          isMobile: isMobile,
        );
      case 'hotkeys':
        return _supportsHotkeys
            ? HotkeysSection(
                isDark: isDark,
                strings: strings,
                isMobile: isMobile,
              )
            : VoiceSection(
                isDark: isDark,
                strings: strings,
                isMobile: isMobile,
              );
      case 'system':
        return SystemSection(
          isDark: isDark,
          strings: strings,
          isMobile: isMobile,
        );
      default:
        return AccountSection(
          isDark: isDark,
          user: user,
          strings: strings,
          isMobile: isMobile,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_supportsHotkeys && _selectedSection == 'hotkeys') {
      _selectedSection = 'voice';
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final strings = ref.watch(stringsProvider);
    final user = authState.user;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () {
              if (isMobile && _mobileShowingDetail) {
                setState(() => _mobileShowingDetail = false);
              } else {
                Navigator.of(context).maybePop();
              }
            },
          },
          child: Focus(
            autofocus: true,
            child: PopScope(
              canPop: !isMobile || !_mobileShowingDetail,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                if (isMobile && _mobileShowingDetail) {
                  setState(() => _mobileShowingDetail = false);
                }
              },
              child: Scaffold(
                backgroundColor:
                    isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
                body: SafeArea(
                  top: !_isDesktop,
                  bottom: isMobile,
                  child: isMobile
                      ? _buildMobileLayout(context, isDark, user, strings)
                      : _buildDesktopLayout(context, isDark, user, strings),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    bool isDark,
    UserModel? user,
    AppStrings strings,
  ) {
    if (_mobileShowingDetail) {
      return Column(
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.arrowLeft, size: 20),
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                  tooltip: 'Voltar',
                  splashRadius: 20,
                  onPressed: () => setState(() => _mobileShowingDetail = false),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getSectionTitle(_selectedSection, strings),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : AppColors.lightTextSecondary,
                  tooltip: 'Fechar',
                  splashRadius: 20,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            width: double.infinity,
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: _buildSectionContent(
                  isDark,
                  user,
                  strings,
                  isMobile: true,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.darkPrimary : AppColors.lightPrimary,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(
                  LucideIcons.settings,
                  size: 16,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  strings.settingsTitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.lightTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.x, size: 20),
                color: isDark
                    ? AppColors.darkTextSecondary
                    : AppColors.lightTextSecondary,
                tooltip: 'Fechar',
                splashRadius: 20,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
        Container(
          height: 1,
          width: double.infinity,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: SettingsSidebar(
              selectedSection: _selectedSection,
              onSelectSection: (section) {
                setState(() {
                  _selectedSection = section;
                  _mobileShowingDetail = true;
                });
              },
              isDark: isDark,
              strings: strings,
              isMobile: true,
              supportsHotkeys: _supportsHotkeys,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    bool isDark,
    UserModel? user,
    AppStrings strings,
  ) {
    return Column(
      children: [
        Container(
          height: 42,
          color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
          child: Row(
            children: [
              Container(
                width: 240,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Icon(
                        LucideIcons.settings,
                        size: 16,
                        color: isDark ? Colors.black : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        strings.settingsTitle,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Expanded(child: DragToMoveArea(child: SizedBox.expand())),
              if (_isDesktop) const WindowControls(height: 42, buttonWidth: 42),
            ],
          ),
        ),
        Container(
          height: 1,
          width: double.infinity,
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SettingsSidebar(
                selectedSection: _selectedSection,
                onSelectSection: (section) {
                  setState(() {
                    _selectedSection = section;
                  });
                },
                isDark: isDark,
                strings: strings,
                isMobile: false,
                supportsHotkeys: _supportsHotkeys,
              ),
              Container(
                width: 1,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              Expanded(
                child: Container(
                  color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Scrollbar(
                          controller: _scrollController,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 32,
                            ),
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 720,
                                ),
                                child: _buildSectionContent(
                                  isDark,
                                  user,
                                  strings,
                                  isMobile: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 24,
                          right: 28,
                          left: 12,
                        ),
                        child: SettingsCloseButton(isDark: isDark),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
