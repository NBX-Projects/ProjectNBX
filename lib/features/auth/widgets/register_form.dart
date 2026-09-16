import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';

class RegisterForm extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToLogin;
  final Color? primaryColor;
  final Color? onPrimaryColor;
  final Color? inputBg;
  final Color? borderColor;
  final Color? textPrimary;
  final Color? textMuted;

  const RegisterForm({
    super.key,
    required this.onSwitchToLogin,
    this.primaryColor,
    this.onPrimaryColor,
    this.inputBg,
    this.borderColor,
    this.textPrimary,
    this.textMuted,
  });

  @override
  ConsumerState<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends ConsumerState<RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(authControllerProvider.notifier);
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await notifier.register(
      username,
      email,
      password,
      name: name.isNotEmpty ? name : username,
    );

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
          // Nome Completo
          TextFormField(
            controller: _nameController,
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Nome Completo',
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
                return 'Informe seu nome completo';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Nome de Usuário
          TextFormField(
            controller: _usernameController,
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Nome de Usuário',
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
                return 'Informe seu nome de usuário';
              }
              if (value.trim().contains(' ')) {
                return 'Nome de usuário não pode conter espaços';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // E-mail
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: GoogleFonts.inter(
              color: textPrimary,
              fontSize: 13.5,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'E-mail',
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
                  LucideIcons.mail,
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
                return 'Informe seu e-mail';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Informe um e-mail válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Senha
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
              if (value.length < 6) {
                return 'A senha deve ter no mínimo 6 caracteres';
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
                          'CRIAR CONTA',
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

          // Footer: Já tem uma conta? Entrar
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: widget.onSwitchToLogin,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text.rich(
                    TextSpan(
                      text: 'Já tem uma conta? ',
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: textMuted,
                      ),
                      children: [
                        TextSpan(
                          text: 'Entrar',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w600,
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
    );
  }
}
