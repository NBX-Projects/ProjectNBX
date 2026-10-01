import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/localization/locale_controller.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/core/theme/theme_controller.dart';
import 'package:justtalking/core/widgets/window_controls.dart';
import 'package:justtalking/features/auth/controllers/auth_controller.dart';
import 'package:justtalking/features/auth/widgets/login_form.dart';
import 'package:justtalking/features/auth/widgets/register_form.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:window_manager/window_manager.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isRegister = false;

  static const Duration _animDuration = Duration(milliseconds: 300);

  void _switchMode(bool isRegister) {
    if (_isRegister == isRegister) return;
    setState(() {
      _isRegister = isRegister;
    });
    ref.read(authControllerProvider.notifier).clearError();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.lightDanger;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: isDark ? 1.0 : 0.0, end: isDark ? 1.0 : 0.0),
      duration: _animDuration,
      curve: Curves.easeInOut,
      builder: (context, t, child) {
        final panelBg = Color.lerp(
          AppColors.lightSurfaceElevated,
          AppColors.darkSurfaceElevated,
          t,
        )!;
        final cardBg = Color.lerp(
          AppColors.lightSurface,
          AppColors.darkSurface,
          t,
        )!;
        final primaryColor = Color.lerp(
          AppColors.lightPrimary,
          AppColors.darkPrimary,
          t,
        )!;
        final onPrimaryColor = Color.lerp(
          Colors.white,
          const Color(0xFF181926),
          t,
        )!;
        final textPrimary = Color.lerp(
          AppColors.lightTextPrimary,
          AppColors.darkTextPrimary,
          t,
        )!;
        final textMuted = Color.lerp(
          AppColors.lightTextMuted,
          AppColors.darkTextMuted,
          t,
        )!;
        final taglineColor = Color.lerp(
          AppColors.lightTextSecondary,
          const Color(0xFFE7D9C9),
          t,
        )!;
        final borderColor = Color.lerp(
          const Color(0xFFE2E8F0),
          const Color(0xFF2B2D3F),
          t,
        )!;
        final inputBg = Color.lerp(Colors.white, const Color(0xFF141520), t)!;
        final tabBg = Color.lerp(
          const Color(0xFFF1F5F9),
          const Color(0xFF141520),
          t,
        )!;
        final toggleBg = Color.lerp(Colors.white, const Color(0xFF1B1C2A), t)!;
        final toggleInnerBg = Color.lerp(
          const Color(0xFFF1F5F9),
          const Color(0xFF141520),
          t,
        )!;

        final themeToggle = _buildThemeToggle(
          isDark: isDark,
          buttonBg: toggleInnerBg,
          borderColor: borderColor,
          primaryColor: primaryColor,
        );

        return Scaffold(
          backgroundColor: cardBg,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 600;
                final shortViewport = constraints.maxHeight < 620;
                final wideLayout =
                    constraints.maxWidth >= 800 && constraints.maxHeight >= 480;
                final logoSize = compact
                    ? 96.0
                    : shortViewport
                    ? 84.0
                    : 96.0;

                if (wideLayout) {
                  final brandPanelWidth = (constraints.maxWidth * 0.35).clamp(
                    320.0,
                    420.0,
                  );

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: brandPanelWidth,
                        child: _BrandPanel(
                          isDark: isDark,
                          panelBg: panelBg,
                          borderColor: borderColor,
                          titleColor: textPrimary,
                          taglineColor: taglineColor,
                          primaryColor: primaryColor,
                          tagBackground: toggleBg,
                          themeToggle: themeToggle,
                        ),
                      ),
                      Expanded(
                        child: Container(
                          color: cardBg,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SizedBox(
                                height: 48,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: DragToMoveArea(
                                        child: SizedBox.expand(),
                                      ),
                                    ),
                                    WindowControls(height: 48, buttonWidth: 46),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: compact ? 20 : 36,
                                      vertical: shortViewport ? 12 : 24,
                                    ),
                                    child: ConstrainedBox(
                                      constraints: const BoxConstraints(
                                        maxWidth: 480,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            _isRegister
                                                ? 'Crie sua conta'
                                                : 'Boas-vindas de volta',
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 26,
                                              fontWeight: FontWeight.w700,
                                              color: textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _isRegister
                                                ? 'Conecte-se com sua comunidade.'
                                                : 'Entre e continue de onde a conversa parou.',
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: textMuted,
                                              height: 1.45,
                                            ),
                                          ),
                                          const SizedBox(height: 22),
                                          _buildModeSwitcher(
                                            tabBg: tabBg,
                                            borderColor: borderColor,
                                            primaryColor: primaryColor,
                                            onPrimaryColor: onPrimaryColor,
                                            textMuted: textMuted,
                                          ),
                                          if (authState.errorMessage !=
                                              null) ...[
                                            const SizedBox(height: 16),
                                            _buildErrorBanner(
                                              errorMessage:
                                                  authState.errorMessage!,
                                              dangerColor: dangerColor,
                                            ),
                                          ],
                                          SizedBox(
                                            height: shortViewport ? 14 : 20,
                                          ),
                                          _buildFormSwitcher(
                                            primaryColor: primaryColor,
                                            onPrimaryColor: onPrimaryColor,
                                            inputBg: inputBg,
                                            borderColor: borderColor,
                                            textPrimary: textPrimary,
                                            textMuted: textMuted,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                // Compact / Single-column Layout
                return Container(
                  color: cardBg,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 48,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              _OrganizationThemeTag(
                                backgroundColor: toggleBg,
                                borderColor: borderColor,
                                themeToggle: themeToggle,
                              ),
                              const Expanded(
                                child: DragToMoveArea(child: SizedBox.expand()),
                              ),
                              const WindowControls(height: 48, buttonWidth: 46),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 20 : 28,
                              vertical: shortViewport ? 12 : 20,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 480),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const SizedBox(height: 14),
                                  Center(
                                    child: SvgPicture.asset(
                                      isDark
                                          ? 'assets/brand/nbx-projects-symbol-dark.svg'
                                          : 'assets/brand/nbx-projects-symbol.svg',
                                      width: logoSize,
                                      height: logoSize,
                                      semanticsLabel: 'Símbolo da NBX Projects',
                                    ),
                                  ),
                                  SizedBox(height: compact ? 8 : 12),
                                  Text.rich(
                                    TextSpan(
                                      style: GoogleFonts.spaceGrotesk()
                                          .copyWith(
                                            fontSize: 30,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -0.4,
                                          ),
                                      children: [
                                        TextSpan(
                                          text: 'Just ',
                                          style: TextStyle(color: textPrimary),
                                        ),
                                        TextSpan(
                                          text: 'Talking',
                                          style: TextStyle(color: primaryColor),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: Text(
                                      _isRegister
                                          ? 'A conversa é só o começo. Crie sua conta e encontre sua comunidade.'
                                          : 'A conversa é só o começo. Entre para encontrar sua comunidade.',
                                      key: ValueKey(_isRegister),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: textMuted,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: shortViewport ? 16 : 22),
                                  _buildModeSwitcher(
                                    tabBg: tabBg,
                                    borderColor: borderColor,
                                    primaryColor: primaryColor,
                                    onPrimaryColor: onPrimaryColor,
                                    textMuted: textMuted,
                                  ),
                                  if (authState.errorMessage != null) ...[
                                    const SizedBox(height: 16),
                                    _buildErrorBanner(
                                      errorMessage: authState.errorMessage!,
                                      dangerColor: dangerColor,
                                    ),
                                  ],
                                  SizedBox(height: shortViewport ? 14 : 20),
                                  _buildFormSwitcher(
                                    primaryColor: primaryColor,
                                    onPrimaryColor: onPrimaryColor,
                                    inputBg: inputBg,
                                    borderColor: borderColor,
                                    textPrimary: textPrimary,
                                    textMuted: textMuted,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeToggle({
    required bool isDark,
    required Color buttonBg,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return Tooltip(
      message: isDark
          ? 'Alternar para Tema Claro'
          : 'Alternar para Tema Escuro',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            ref.read(themeModeProvider.notifier).toggleTheme();
          },
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: buttonBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor.withValues(alpha: 0.6)),
            ),
            alignment: Alignment.center,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (c, anim) =>
                  ScaleTransition(scale: anim, child: c),
              child: Icon(
                isDark ? LucideIcons.sun : LucideIcons.moon,
                key: ValueKey(isDark),
                size: 15,
                color: primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeSwitcher({
    required Color tabBg,
    required Color borderColor,
    required Color primaryColor,
    required Color onPrimaryColor,
    required Color textMuted,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tabBg,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _switchMode(false),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: !_isRegister ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Entrar',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: !_isRegister
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: !_isRegister ? onPrimaryColor : textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _switchMode(true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _isRegister ? primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Criar Conta',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: _isRegister
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: _isRegister ? onPrimaryColor : textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner({
    required String errorMessage,
    required Color dangerColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: dangerColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: dangerColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.triangleAlert, color: dangerColor, size: 15),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              errorMessage,
              style: TextStyle(color: dangerColor, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSwitcher({
    required Color primaryColor,
    required Color onPrimaryColor,
    required Color inputBg,
    required Color borderColor,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: _isRegister
          ? RegisterForm(
              key: const ValueKey('register_form'),
              onSwitchToLogin: () => _switchMode(false),
              primaryColor: primaryColor,
              onPrimaryColor: onPrimaryColor,
              inputBg: inputBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textMuted: textMuted,
            )
          : LoginForm(
              key: const ValueKey('login_form'),
              onSwitchToRegister: () => _switchMode(true),
              primaryColor: primaryColor,
              onPrimaryColor: onPrimaryColor,
              inputBg: inputBg,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textMuted: textMuted,
            ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel({
    required this.isDark,
    required this.panelBg,
    required this.borderColor,
    required this.titleColor,
    required this.taglineColor,
    required this.primaryColor,
    required this.tagBackground,
    required this.themeToggle,
  });

  final bool isDark;
  final Color panelBg;
  final Color borderColor;
  final Color titleColor;
  final Color taglineColor;
  final Color primaryColor;
  final Color tagBackground;
  final Widget themeToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(right: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top bar area with Theme Toggle button on top-left and window drag area
          SizedBox(
            height: 48,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: _OrganizationThemeTag(
                    backgroundColor: tagBackground,
                    borderColor: borderColor,
                    themeToggle: themeToggle,
                  ),
                ),
                const Expanded(child: DragToMoveArea(child: SizedBox.expand())),
              ],
            ),
          ),
          // Centered Brand Content
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 36,
                  vertical: 24,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SvgPicture.asset(
                        isDark
                            ? 'assets/brand/nbx-projects-symbol-dark.svg'
                            : 'assets/brand/nbx-projects-symbol.svg',
                        width: 128,
                        height: 128,
                        semanticsLabel: 'Símbolo da NBX Projects',
                      ),
                      const SizedBox(height: 22),
                      Text.rich(
                        TextSpan(
                          style: GoogleFonts.spaceGrotesk().copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            height: 1.15,
                          ),
                          children: [
                            TextSpan(
                              text: 'Just ',
                              style: TextStyle(color: titleColor),
                            ),
                            TextSpan(
                              text: 'Talking',
                              style: TextStyle(color: primaryColor),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'A conversa é só o começo.',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.4,
                          color: taglineColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: AppRadius.borderMd,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrganizationLabel extends ConsumerWidget {
  const _OrganizationLabel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final strings = ref.watch(stringsProvider);

    return Text(
      strings.organizationTitle,
      style: GoogleFonts.jetBrainsMono(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _OrganizationThemeTag extends StatelessWidget {
  const _OrganizationThemeTag({
    required this.backgroundColor,
    required this.borderColor,
    required this.themeToggle,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Widget themeToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          themeToggle,
          const SizedBox(width: 8),
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: _OrganizationLabel(),
          ),
        ],
      ),
    );
  }
}
