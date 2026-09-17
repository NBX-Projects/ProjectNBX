import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/core/widgets/window_controls.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/widgets/login_form.dart';
import 'package:projectnbx/features/auth/widgets/register_form.dart';
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
        final canvasBg = Color.lerp(
          AppColors.lightCanvas,
          AppColors.darkCanvas,
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
        final toggleBg = Color.lerp(
          const Color(0xFFF1F5F9),
          const Color(0xFF1B1C2A),
          t,
        )!;

        return Scaffold(
          backgroundColor: canvasBg,
          body: Stack(
            children: [
              // Top Window Bar with Theme Toggle (Left) & Window Controls (Right)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // Theme Mode Switcher (Circular Button on Top-Left)
                      Tooltip(
                        message: isDark
                            ? 'Alternar para Tema Claro'
                            : 'Alternar para Tema Escuro',
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .toggleTheme();
                            },
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: toggleBg,
                                shape: BoxShape.circle,
                                border: Border.all(color: borderColor),
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
                      ),
                      // Drag Window Area
                      const Expanded(
                        child: DragToMoveArea(child: SizedBox.expand()),
                      ),
                      // Desktop Window Controls (Top-Right)
                      const WindowControls(height: 38, buttonWidth: 42),
                    ],
                  ),
                ),
              ),

              // Centered Seamless Form Area
              Positioned.fill(
                top: 52,
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 24,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 380),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Dynamic Vector Logo (Adapts to primaryColor)

                          const SizedBox(height: 14),

                          // Brand Title
                          Text.rich(
                            TextSpan(
                              style: GoogleFonts.spaceGrotesk().copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Project',
                                  style: TextStyle(color: textPrimary),
                                ),
                                TextSpan(
                                  text: 'NBX',
                                  style: TextStyle(color: primaryColor),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),

                          // Dynamic Subtitle
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Text(
                              _isRegister
                                  ? 'Crie sua conta para começar'
                                  : 'Entre na sua conta para continuar',
                              key: ValueKey(_isRegister),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: textMuted,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Segmented Mode Switcher (Pill Style)
                          Container(
                            height: 42,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: tabBg,
                              borderRadius: AppRadius.borderPill,
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
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        decoration: BoxDecoration(
                                          color: !_isRegister
                                              ? primaryColor
                                              : Colors.transparent,
                                          borderRadius: AppRadius.borderPill,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Entrar',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: !_isRegister
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: !_isRegister
                                                ? onPrimaryColor
                                                : textMuted,
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
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isRegister
                                              ? primaryColor
                                              : Colors.transparent,
                                          borderRadius: AppRadius.borderPill,
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Criar Conta',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: _isRegister
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: _isRegister
                                                ? onPrimaryColor
                                                : textMuted,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Error Banner
                          if (authState.errorMessage != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: dangerColor.withValues(alpha: 0.12),
                                borderRadius: AppRadius.borderSm,
                                border: Border.all(
                                  color: dangerColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    LucideIcons.triangleAlert,
                                    color: dangerColor,
                                    size: 15,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      authState.errorMessage!,
                                      style: TextStyle(
                                        color: dangerColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 20),

                          // Modular Form Switcher (Animated)
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
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
    );
  }
}
