import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/core/widgets/window_controls.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:window_manager/window_manager.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isRegister = false;
  bool _obscurePassword = true;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  static const Duration _themeAnimDuration = Duration(milliseconds: 300);

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _switchMode(bool isRegister) {
    setState(() {
      _isRegister = isRegister;
    });
    ref.read(authControllerProvider.notifier).clearError();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authControllerProvider.notifier);
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (_isRegister) {
      final username = _usernameController.text.trim();
      final success = await notifier.register(username, email, password);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkSage
                : AppColors.lightSage,
            content: Text(
              'Conta criada com sucesso! Bem-vindo ao ProjectNBX.',
              style: TextStyle(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkCanvas
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    } else {
      await notifier.login(email, password);
    }
  }

  void _fillDemoCredentials() {
    setState(() {
      _emailController.text = 'tauisilva@gmail.com';
      _passwordController.text = 'Minazuki1902*';
      if (_isRegister) {
        _usernameController.text = 'Taui Lima';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);

    final canvasBg = isDark ? AppColors.darkCanvas : AppColors.lightCanvas;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final onPrimaryColor = isDark ? AppColors.darkCanvas : Colors.white;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final textMuted = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.lightDanger;
    final secondaryAccent = isDark
        ? AppColors.darkSage
        : AppColors.lightPrimary;

    return AnimatedTheme(
      data: theme,
      duration: _themeAnimDuration,
      curve: Curves.easeInOut,
      child: AnimatedContainer(
        duration: _themeAnimDuration,
        curve: Curves.easeInOut,
        color: canvasBg,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Top Window Bar with Theme Toggle & Window Controls
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 52,
                child: DragToMoveArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        const Spacer(),
                        // Theme Toggle Pill
                        Tooltip(
                          message: isDark
                              ? 'Mudar para Tema Claro'
                              : 'Mudar para Tema Escuro',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(9999),
                              onTap: () {
                                ref.read(themeModeProvider.notifier).toggleTheme();
                              },
                              child: AnimatedContainer(
                                duration: _themeAnimDuration,
                                curve: Curves.easeInOut,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(9999),
                                  border: Border.all(color: borderColor),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.04,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    AnimatedSwitcher(
                                      duration: _themeAnimDuration,
                                      transitionBuilder: (child, anim) =>
                                          ScaleTransition(scale: anim, child: child),
                                      child: Icon(
                                        isDark ? LucideIcons.sun : LucideIcons.moon,
                                        key: ValueKey(isDark),
                                        size: 16,
                                        color: primaryColor,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isDark ? 'Tema Claro' : 'Tema Escuro',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Desktop Window Controls
                        const WindowControls(),
                      ],
                    ),
                  ),
                ),
              ),

              // Central Form Content
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: AnimatedContainer(
                      duration: _themeAnimDuration,
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: borderColor, width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? const Color(0x730F0F17)
                                : const Color(0x0A1E293B),
                            blurRadius: isDark ? 32 : 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(36),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Branding Header with Logo & Title
                            Center(
                              child: Column(
                                children: [
                                  AnimatedContainer(
                                    duration: _themeAnimDuration,
                                    width: 68,
                                    height: 68,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: primaryColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1.5,
                                      ),
                                      color: isDark
                                          ? AppColors.darkSurfaceElevated
                                          : AppColors.lightSurfaceElevated,
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.asset(
                                        'assets/logo.png',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                              return Container(
                                                color: cardBg,
                                                child: Icon(
                                                  LucideIcons.terminal,
                                                  color: primaryColor,
                                                  size: 28,
                                                ),
                                              );
                                            },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'ProjectNBX',
                                    style:
                                        (isDark
                                                ? GoogleFonts.spaceGrotesk()
                                                : GoogleFonts.plusJakartaSans())
                                            .copyWith(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: -0.5,
                                              color: textPrimary,
                                            ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isRegister
                                        ? 'Crie seu perfil de desenvolvedor no ProjectNBX'
                                        : 'Acesse seu workspace de áudio, chat e colaboração',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: textSecondary,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Tab / Segmented Mode Switcher (Pill Style)
                            AnimatedContainer(
                              duration: _themeAnimDuration,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.darkInput
                                    : AppColors.lightCanvas,
                                borderRadius: BorderRadius.circular(9999),
                                border: Border.all(color: borderColor),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _switchMode(false),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: !_isRegister
                                              ? primaryColor
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            9999,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Entrar',
                                          style: GoogleFonts.jetBrainsMono(
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
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => _switchMode(true),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isRegister
                                              ? primaryColor
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            9999,
                                          ),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          'Criar Conta',
                                          style: GoogleFonts.jetBrainsMono(
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
                                ],
                              ),
                            ),

                            // Error Banner if needed
                            if (authState.errorMessage != null) ...[
                              const SizedBox(height: 20),
                              AnimatedContainer(
                                duration: _themeAnimDuration,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: dangerColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: dangerColor.withValues(alpha: 0.4),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      LucideIcons.triangleAlert,
                                      color: dangerColor,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        authState.errorMessage!,
                                        style: TextStyle(
                                          color: dangerColor,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Form Inputs
                            if (_isRegister) ...[
                              TextFormField(
                                controller: _usernameController,
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Nome de Usuário',
                                  hintText: 'Ex: taui_dev',
                                  prefixIcon: Icon(
                                    LucideIcons.user,
                                    size: 18,
                                    color: textSecondary,
                                  ),
                                ),
                                validator: (value) {
                                  if (_isRegister &&
                                      (value == null || value.trim().isEmpty)) {
                                    return 'Informe seu nome de usuário';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                labelText: 'E-mail',
                                hintText: 'dev@nbx.com',
                                prefixIcon: Icon(
                                  LucideIcons.mail,
                                  size: 18,
                                  color: textSecondary,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Informe seu e-mail';
                                }
                                if (!value.contains('@') ||
                                    !value.contains('.')) {
                                  return 'Informe um e-mail válido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 14,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Senha',
                                hintText: '••••••••',
                                prefixIcon: Icon(
                                  LucideIcons.lock,
                                  size: 18,
                                  color: textSecondary,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? LucideIcons.eyeOff
                                        : LucideIcons.eye,
                                    size: 18,
                                    color: textSecondary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Informe sua senha';
                                }
                                if (value.length < 6) {
                                  return 'A senha deve ter no mínimo 6 caracteres';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) => _submit(),
                            ),

                            const SizedBox(height: 26),

                            // Action Pill Button
                            AnimatedContainer(
                              duration: _themeAnimDuration,
                              child: ElevatedButton(
                                onPressed: authState.isLoading ? null : _submit,
                                child: authState.isLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                onPrimaryColor,
                                              ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _isRegister
                                                ? 'CRIAR CONTA'
                                                : 'ACESSAR',
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            LucideIcons.arrowRight,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Quick Test / Demo credentials helper
                            Center(
                              child: TextButton.icon(
                                onPressed: _fillDemoCredentials,
                                icon: Icon(
                                  LucideIcons.sparkles,
                                  size: 14,
                                  color: secondaryAccent,
                                ),
                                label: Text(
                                  'Preencher credenciais de teste (dev@nbx.com)',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
