import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';

class LoginForm extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToRegister;
  final Color? primaryColor;
  final Color? onPrimaryColor;
  final Color? inputBg;
  final Color? borderColor;
  final Color? textPrimary;
  final Color? textMuted;

  const LoginForm({
    super.key,
    required this.onSwitchToRegister,
    this.primaryColor,
    this.onPrimaryColor,
    this.inputBg,
    this.borderColor,
    this.textPrimary,
    this.textMuted,
  });

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials() {
    setState(() {
      _loginController.text = 'srSixSeven@gmail.com';
      _passwordController.text = 'SixSeven67*';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await ref.read(authControllerProvider.notifier).login(
          _loginController.text.trim(),
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);

    final primaryColor = widget.primaryColor ??
        (isDark ? AppColors.darkPrimary : AppColors.lightPrimary);
    final onPrimaryColor = widget.onPrimaryColor ??
        (isDark ? AppColors.darkCanvas : Colors.white);
    final textPrimary = widget.textPrimary ??
        (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final textMuted = widget.textMuted ??
        (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted);
    final textSecondary = textMuted;
    final inputBg = widget.inputBg ??
        (isDark ? const Color(0xFF141520) : const Color(0xFFFAFAFA));
    final borderColor = widget.borderColor ??
        (isDark ? const Color(0xFF2B2D3F) : const Color(0xFFE2E8F0));

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Login Identifier (Username or Email)
          TextFormField(
            controller: _loginController,
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'E-mail ou Nome de Usuário',
              hintStyle: GoogleFonts.inter(
                color: textMuted,
                fontSize: 13.5,
              ),
              filled: true,
              fillColor: inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  LucideIcons.user,
                  size: 16,
                  color: textSecondary,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 42,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Informe seu e-mail ou nome de usuário';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Password
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Senha',
              hintStyle: GoogleFonts.inter(
                color: textMuted,
                fontSize: 13.5,
              ),
              filled: true,
              fillColor: inputBg,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  LucideIcons.lock,
                  size: 16,
                  color: textSecondary,
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 42,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 16,
                  color: textSecondary,
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Informe sua senha';
              }
              return null;
            },
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 22),

          // Submit Button
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: authState.isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: onPrimaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9999),
                ),
              ),
              child: authState.isLoading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(onPrimaryColor),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'ACESSAR',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.arrowRight, size: 16),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 18),

          // Demo Credentials Shortcut
          Center(
            child: InkWell(
              onTap: _fillDemoCredentials,
              borderRadius: BorderRadius.circular(9999),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.key,
                      size: 14,
                      color: textMuted,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Preencher credenciais de teste (dev@nbx.com)',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: textMuted,
                        ),
                        overflow: TextOverflow.ellipsis,
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
}
