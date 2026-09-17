import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/config/app_config.dart';
import 'package:projectnbx/core/localization/app_language.dart';
import 'package:projectnbx/core/localization/app_strings.dart';
import 'package:projectnbx/core/localization/locale_controller.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/core/theme/app_radius.dart';
import 'package:projectnbx/core/theme/theme_controller.dart';
import 'package:projectnbx/core/updater/update_controller.dart';
import 'package:projectnbx/core/updater/update_models.dart';
import 'package:projectnbx/core/updater/widgets/update_dialog.dart';
import 'package:projectnbx/core/widgets/window_controls.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
import 'package:projectnbx/features/voice/controllers/audio_devices_controller.dart';
import 'package:projectnbx/features/voice/controllers/audio_settings_controller.dart';
import 'package:window_manager/window_manager.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  final String initialSection;
  const SettingsScreen({super.key, this.initialSection = 'account'});

  static Future<void> show(BuildContext context, {String initialSection = 'account'}) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SettingsScreen(initialSection: initialSection),
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

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection;
  }

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  final ScrollController _scrollController = ScrollController();

  // Voice Settings State
  double _inputVolume = 0.85;
  double _outputVolume = 0.90;
  bool _isPushToTalk = false;
  final String _pttKey = 'CAPS LOCK';

  // Account Status & Profile Edit State
  String _userStatus = 'online';
  bool _isEditingProfile = false;
  bool _isSavingProfile = false;
  final _profileFormKey = GlobalKey<FormState>();
  final _nameEditController = TextEditingController();
  final _usernameEditController = TextEditingController();
  final _emailEditController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _nameEditController.dispose();
    _usernameEditController.dispose();
    _emailEditController.dispose();
    super.dispose();
  }

  void _startEditingProfile(UserModel? user) {
    setState(() {
      _isEditingProfile = true;
      _nameEditController.text = (user?.name.isNotEmpty == true)
          ? user!.name
          : (user?.username ?? '');
      _usernameEditController.text = user?.username ?? '';
      _emailEditController.text = user?.email ?? '';
    });
  }

  void _cancelEditingProfile() {
    setState(() {
      _isEditingProfile = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_profileFormKey.currentState!.validate()) return;
    setState(() => _isSavingProfile = true);

    final success = await ref
        .read(authControllerProvider.notifier)
        .updateProfile(
          name: _nameEditController.text.trim(),
          username: _usernameEditController.text.trim(),
          email: _emailEditController.text.trim(),
        );

    if (mounted) {
      setState(() => _isSavingProfile = false);
      if (success) {
        setState(() => _isEditingProfile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF2D6A4F),
            content: Text(
              'Perfil atualizado com sucesso!',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      } else {
        final error =
            ref.read(authControllerProvider).errorMessage ??
            'Falha ao atualizar perfil';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFE53935),
            content: Text(
              error,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
    bool isDark,
  ) async {
    final formKey = GlobalKey<FormState>();
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSaving = false;
    String? errorMessage;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final primaryColor = isDark
                ? AppColors.darkPrimary
                : AppColors.lightPrimary;
            final onPrimaryColor = isDark ? AppColors.darkCanvas : Colors.white;
            final cardBg = isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface;
            final borderColor = isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder;
            final textPrimary = isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary;
            final textSecondary = isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary;

            return Dialog(
              backgroundColor: cardBg,
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.borderLg,
                side: BorderSide(color: borderColor),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Padding(
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withValues(alpha: 0.15),
                                borderRadius: AppRadius.borderSm,
                              ),
                              child: Icon(
                                LucideIcons.keyRound,
                                size: 20,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Alterar Senha',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Confirme sua senha atual para definir uma nova',
                                    style: GoogleFonts.inter(
                                      fontSize: 12.5,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                LucideIcons.x,
                                size: 18,
                                color: textSecondary,
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                            ),
                          ],
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFFE53935,
                              ).withValues(alpha: 0.15),
                              borderRadius: AppRadius.borderSm,
                              border: Border.all(
                                color: const Color(
                                  0xFFE53935,
                                ).withValues(alpha: 0.4),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  LucideIcons.triangleAlert,
                                  size: 16,
                                  color: Color(0xFFE53935),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: const Color(0xFFE53935),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: currentPasswordController,
                          obscureText: obscureCurrent,
                          style: TextStyle(color: textPrimary, fontSize: 13.5),
                          decoration: InputDecoration(
                            labelText: 'Senha Atual',
                            prefixIcon: Icon(
                              LucideIcons.lock,
                              size: 16,
                              color: textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureCurrent
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                size: 16,
                                color: textSecondary,
                              ),
                              onPressed: () {
                                setDialogState(
                                  () => obscureCurrent = !obscureCurrent,
                                );
                              },
                            ),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Informe sua senha atual'
                              : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          style: TextStyle(color: textPrimary, fontSize: 13.5),
                          decoration: InputDecoration(
                            labelText: 'Nova Senha',
                            prefixIcon: Icon(
                              LucideIcons.key,
                              size: 16,
                              color: textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNew
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                size: 16,
                                color: textSecondary,
                              ),
                              onPressed: () {
                                setDialogState(() => obscureNew = !obscureNew);
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Informe a nova senha';
                            }
                            if (v.length < 6) return 'Mínimo de 6 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          style: TextStyle(color: textPrimary, fontSize: 13.5),
                          decoration: InputDecoration(
                            labelText: 'Confirmar Nova Senha',
                            prefixIcon: Icon(
                              LucideIcons.checkCheck,
                              size: 16,
                              color: textSecondary,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirm
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                size: 16,
                                color: textSecondary,
                              ),
                              onPressed: () {
                                setDialogState(
                                  () => obscureConfirm = !obscureConfirm,
                                );
                              },
                            ),
                          ),
                          validator: (v) {
                            if (v != newPasswordController.text) {
                              return 'As senhas não coincidem';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: isSaving
                                  ? null
                                  : () => Navigator.of(dialogContext).pop(),
                              child: Text(
                                'Cancelar',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 12.5,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: onPrimaryColor,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: AppRadius.borderPill,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                              ),
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      if (!formKey.currentState!.validate()) {
                                        return;
                                      }
                                      setDialogState(() {
                                        isSaving = true;
                                        errorMessage = null;
                                      });
                                      final success = await ref
                                          .read(authControllerProvider.notifier)
                                          .changePassword(
                                            currentPassword:
                                                currentPasswordController.text,
                                            newPassword:
                                                newPasswordController.text,
                                          );
                                      if (!dialogContext.mounted) return;
                                      if (success) {
                                        Navigator.of(dialogContext).pop();
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            backgroundColor: const Color(
                                              0xFF2D6A4F,
                                            ),
                                            content: Text(
                                              'Senha alterada com sucesso!',
                                              style: GoogleFonts.inter(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        );
                                      } else {
                                        final err =
                                            ref
                                                .read(authControllerProvider)
                                                .errorMessage ??
                                            'Falha ao alterar senha';
                                        setDialogState(() {
                                          isSaving = false;
                                          errorMessage = err;
                                        });
                                      }
                                    },
                              child: isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      'Salvar Nova Senha',
                                      style: GoogleFonts.jetBrainsMono(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);
    final strings = ref.watch(stringsProvider);
    final user = authState.user;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          Navigator.of(context).maybePop();
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: isDark
              ? AppColors.darkCanvas
              : AppColors.lightCanvas,
          body: SafeArea(
            top: !_isDesktop,
            child: Column(
              children: [
                // Top Titlebar & Desktop Window Controls in SafeArea
                Container(
                  height: 42,
                  color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
                  child: Row(
                    children: [
                      // Settings Title Block
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

                      // Draggable Area for Window Movement
                      const Expanded(
                        child: DragToMoveArea(child: SizedBox.expand()),
                      ),

                      // Desktop Window Controls
                      if (_isDesktop)
                        const WindowControls(height: 42, buttonWidth: 42),
                    ],
                  ),
                ),

                // Top Header Horizontal Divider
                Container(
                  height: 1,
                  width: double.infinity,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),

                // Main Settings Content Row
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Left Settings Navigation Sidebar
                      _buildSettingsSidebar(context, isDark, strings),

                      // Vertical Divider
                      Container(
                        width: 1,
                        color: isDark
                            ? AppColors.darkBorder
                            : AppColors.lightBorder,
                      ),

                      // Right Main Settings Content & Isolated ESC Column
                      Expanded(
                        child: Container(
                          color: isDark
                              ? AppColors.darkCanvas
                              : AppColors.lightCanvas,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Scrollable Main Content with styled Scrollbar
                              Expanded(
                                child: Scrollbar(
                                  controller: _scrollController,
                                  child: SingleChildScrollView(
                                    controller: _scrollController,
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
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
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Dedicated ESC / Close action column (completely isolated from scrollbar)
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 24,
                                  right: 28,
                                  left: 12,
                                ),
                                child: _buildCloseButton(context, isDark),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoiseGateCard(
    bool isDark,
    AppStrings strings,
    AudioSettings audioSettings,
    AudioSettingsNotifier notifier,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.autoSensitivity,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      strings.autoSensitivityDesc,
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
                value: audioSettings.autoNoiseGate,
                activeThumbColor: isDark
                    ? AppColors.darkPrimary
                    : AppColors.lightPrimary,
                activeTrackColor:
                    (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                        .withValues(alpha: 0.38),
                onChanged: (val) => notifier.setAutoNoiseGate(val),
              ),
            ],
          ),
          if (!audioSettings.autoNoiseGate) ...[
            const SizedBox(height: 16),
            Divider(
              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.noiseGateThreshold,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        strings.noiseGateThresholdDesc,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated,
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorderFocus
                          : AppColors.lightBorderFocus,
                    ),
                  ),
                  child: Text(
                    '${(-60 + audioSettings.noiseGateThreshold * 50).toInt()} dB (${(audioSettings.noiseGateThreshold * 100).toInt()}%)',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.darkPrimary
                          : AppColors.lightPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: AppRadius.borderSm,
              child: Stack(
                children: [
                  Container(
                    height: 10,
                    width: double.infinity,
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: audioSettings.noiseGateThreshold,
                    child: Container(
                      height: 10,
                      color: Colors.redAccent.withValues(alpha: 0.65),
                    ),
                  ),
                  FractionallySizedBox(
                    alignment: Alignment.centerRight,
                    widthFactor: (1.0 - audioSettings.noiseGateThreshold).clamp(
                      0.0,
                      1.0,
                    ),
                    child: Container(
                      height: 10,
                      color: isDark
                          ? AppColors.darkSage.withValues(alpha: 0.75)
                          : AppColors.lightSage.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Silêncio (Corta Teclado / Cliques)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    color: Colors.redAccent,
                  ),
                ),
                Text(
                  'Transmissão Ativa (Voz)',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 9.5,
                    color: isDark ? AppColors.darkSage : AppColors.lightSage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SliderTheme(
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
                value: audioSettings.noiseGateThreshold,
                min: 0.0,
                max: 1.0,
                onChanged: (val) => notifier.setNoiseGateThreshold(val),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.noiseGateRelease,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        strings.noiseGateReleaseDesc,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
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
                          (isDark
                                  ? AppColors.darkPrimary
                                  : AppColors.lightPrimary)
                              .withValues(alpha: 0.2),
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: audioSettings.noiseGateReleaseMs.toDouble(),
                      min: 100,
                      max: 600,
                      divisions: 10,
                      label: '${audioSettings.noiseGateReleaseMs}ms',
                      onChanged: (val) =>
                          notifier.setNoiseGateReleaseMs(val.toInt()),
                    ),
                  ),
                ),
                SizedBox(
                  width: 55,
                  child: Text(
                    '${audioSettings.noiseGateReleaseMs}ms',
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
            ),
          ],
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              borderRadius: AppRadius.borderSm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: (isDark ? AppColors.darkDanger : AppColors.lightDanger)
                      .withValues(alpha: 0.08),
                  borderRadius: AppRadius.borderSm,
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
                    Expanded(
                      child: Text(
                        strings.logOut,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.darkDanger
                              : AppColors.lightDanger,
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
        borderRadius: AppRadius.borderSm,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark
                      ? AppColors.darkSurfaceElevated
                      : AppColors.lightSurfaceElevated)
                : Colors.transparent,
            borderRadius: AppRadius.borderSm,
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
    return Tooltip(
      message: 'Fechar (Esc)',
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: AppRadius.borderPill,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.lightSurface,
                  border: Border.all(
                    color: isDark
                        ? AppColors.darkBorder
                        : AppColors.lightBorder,
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
              const SizedBox(height: 4),
              Text(
                'ESC',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ),
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
    final displayName = (user?.name.isNotEmpty == true)
        ? user!.name
        : (user?.username.isNotEmpty == true
              ? user!.username
              : 'Taui Silva Lima');
    final username = user?.username.isNotEmpty == true
        ? user!.username
        : 'tauilima';
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : 'tauisilva@gmail.com';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final onPrimaryColor = isDark ? AppColors.darkCanvas : Colors.white;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderTitle(
          isDark,
          strings.myAccount,
          'Gerencie seus dados pessoais, credenciais de acesso e segurança da conta',
        ),
        const SizedBox(height: 24),

        // 1. User Profile Details Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Avatar, Main Names, Status Badge & Edit Action
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkLavender
                          : AppColors.lightLavender,
                      shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        initial,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.black : Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style:
                                    (isDark
                                            ? GoogleFonts.spaceGrotesk()
                                            : GoogleFonts.plusJakartaSans())
                                        .copyWith(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (isDark
                                            ? AppColors.darkSage
                                            : AppColors.lightSage)
                                        .withValues(alpha: 0.15),
                                borderRadius: AppRadius.borderPill,
                                border: Border.all(
                                  color:
                                      (isDark
                                              ? AppColors.darkSage
                                              : AppColors.lightSage)
                                          .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                strings.connected,
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkSage
                                      : AppColors.lightSage,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '@$username',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!_isEditingProfile)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.lightSurfaceElevated,
                        foregroundColor: textPrimary,
                        elevation: 0,
                        side: BorderSide(color: borderColor),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderPill,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                      onPressed: () => _startEditingProfile(user),
                      icon: const Icon(LucideIcons.pencil, size: 14),
                      label: Text(
                        'Editar Perfil',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),
              Divider(color: borderColor),
              const SizedBox(height: 16),

              // Interactive Edit Form or Readonly Information
              if (_isEditingProfile) ...[
                Form(
                  key: _profileFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Atualizar Informações Cadastrais',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameEditController,
                        style: TextStyle(color: textPrimary, fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: 'Nome Completo',
                          hintText: 'Ex: Taui Silva Lima',
                          prefixIcon: Icon(
                            LucideIcons.idCard,
                            size: 16,
                            color: textSecondary,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe seu nome completo';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _usernameEditController,
                        style: TextStyle(color: textPrimary, fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: 'Nome de Usuário',
                          hintText: 'Ex: tauilima',
                          prefixIcon: Icon(
                            LucideIcons.user,
                            size: 16,
                            color: textSecondary,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe seu nome de usuário';
                          }
                          if (v.trim().contains(' ')) {
                            return 'Nome de usuário não pode conter espaços';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _emailEditController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(color: textPrimary, fontSize: 13.5),
                        decoration: InputDecoration(
                          labelText: 'E-mail',
                          hintText: 'Ex: tauisilva@gmail.com',
                          prefixIcon: Icon(
                            LucideIcons.mail,
                            size: 16,
                            color: textSecondary,
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Informe seu e-mail';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Informe um e-mail válido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSavingProfile
                                ? null
                                : _cancelEditingProfile,
                            child: Text(
                              'Cancelar',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12.5,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: onPrimaryColor,
                              shape: const RoundedRectangleBorder(
                                borderRadius: AppRadius.borderPill,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 12,
                              ),
                            ),
                            onPressed: _isSavingProfile ? null : _saveProfile,
                            child: _isSavingProfile
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    'Salvar Alterações',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildAccountRow(isDark, 'Nome Completo', displayName),
                const SizedBox(height: 14),
                _buildAccountRow(isDark, 'Nome de Usuário', '@$username'),
                const SizedBox(height: 14),
                _buildAccountRow(isDark, 'E-mail Cadastrado', email),
                const SizedBox(height: 14),
                _buildAccountRow(
                  isDark,
                  strings.currentStatus,
                  _userStatus == 'online'
                      ? strings.currentStatusOnline
                      : strings.currentStatusAway,
                  action: DropdownButton<String>(
                    value: _userStatus,
                    dropdownColor: cardBg,
                    underline: const SizedBox(),
                    style: GoogleFonts.inter(fontSize: 12, color: textPrimary),
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
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 2. Security & Password Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Icon(
                      LucideIcons.shieldCheck,
                      size: 20,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Segurança & Senha',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Sua conta é protegida por criptografia de alta segurança bcrypt',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: onPrimaryColor,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.borderPill,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                    ),
                    onPressed: () => _showChangePasswordDialog(context, isDark),
                    icon: const Icon(LucideIcons.keyRound, size: 14),
                    label: Text(
                      'Alterar Senha',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Divider(color: borderColor),
              const SizedBox(height: 12),
              _buildAccountRow(
                isDark,
                'Autenticação de Acesso',
                'Login habilitado por E-mail ou Nome de Usuário',
                badgeText: 'Ativo',
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. Logout & Session Management Card
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: dangerColor.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: dangerColor.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Icon(LucideIcons.logOut, size: 20, color: dangerColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encerrar Sessão',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Desconectar seu usuário deste dispositivo com segurança',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: dangerColor,
                  side: BorderSide(color: dangerColor.withValues(alpha: 0.6)),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.borderPill,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  ref.read(authControllerProvider.notifier).logout();
                },
                icon: const Icon(LucideIcons.logOut, size: 14),
                label: Text(
                  'Sair da Conta',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
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
        Expanded(
          child: Column(
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
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: 8), action],
        if (badgeText != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : AppColors.lightSurfaceElevated,
              borderRadius: AppRadius.borderXs,
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
                  borderRadius: AppRadius.borderMd,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      borderRadius: AppRadius.borderMd,
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
      borderRadius: AppRadius.borderMd,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.borderMd,
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
                borderRadius: AppRadius.borderSm,
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
                    borderRadius: AppRadius.borderPill,
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
    final audioSettings = ref.watch(audioSettingsProvider);
    final audioSettingsNotifier = ref.read(audioSettingsProvider.notifier);

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
            Expanded(
              child: _buildSectionHeaderTitle(
                isDark,
                strings.voiceAndVideo,
                strings.voiceDescription,
              ),
            ),
            const SizedBox(width: 12),
            Tooltip(
              message: 'Detectar novos microfones e fones conectados',
              child: InkWell(
                onTap: audioState.isLoading
                    ? null
                    : () => audioNotifier.loadDevices(),
                mouseCursor: SystemMouseCursors.click,
                borderRadius: AppRadius.borderSm,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface,
                    borderRadius: AppRadius.borderSm,
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

        // Input Sensitivity & Noise Gate
        Text(
          strings.inputSensitivity,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 12),

        _buildNoiseGateCard(
          isDark,
          strings,
          audioSettings,
          audioSettingsNotifier,
        ),

        const SizedBox(height: 16),
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
          audioSettings.noiseSuppression,
          (val) => audioSettingsNotifier.setNoiseSuppression(val),
        ),
        _buildSwitchTile(
          isDark,
          strings.typingNoiseSuppression,
          strings.typingNoiseSuppressionDesc,
          audioSettings.typingNoiseDetection,
          (val) => audioSettingsNotifier.setTypingNoiseDetection(val),
        ),
        _buildSwitchTile(
          isDark,
          strings.echoCancellation,
          strings.echoCancellationDesc,
          audioSettings.echoCancellation,
          (val) => audioSettingsNotifier.setEchoCancellation(val),
        ),
        _buildSwitchTile(
          isDark,
          strings.compressor,
          strings.compressorDesc,
          audioSettings.compressorEnabled,
          (val) => audioSettingsNotifier.setCompressorEnabled(val),
        ),
        _buildSwitchTile(
          isDark,
          strings.highPassFilter,
          strings.highPassFilterDesc,
          audioSettings.highPassFilter,
          (val) => audioSettingsNotifier.setHighPassFilter(val),
        ),
        _buildSwitchTile(
          isDark,
          strings.vadOptimization,
          strings.vadOptimizationDesc,
          audioSettings.vadOptimization,
          (val) => audioSettingsNotifier.setVadOptimization(val),
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
            borderRadius: AppRadius.borderMd,
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
        borderRadius: AppRadius.borderMd,
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
              borderRadius: AppRadius.borderMd,
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
                    borderRadius: AppRadius.borderSm,
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
      borderRadius: AppRadius.borderMd,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          borderRadius: AppRadius.borderMd,
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
        borderRadius: AppRadius.borderSm,
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
              borderRadius: AppRadius.borderXs,
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
    final updateState = ref.watch(updateControllerProvider);
    final isChecking = updateState.status == UpdateStatus.checking;
    final hasUpdate = updateState.isUpdateAvailable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeaderTitle(
          isDark,
          strings.systemStatusTitle,
          strings.systemStatusDesc,
        ),
        const SizedBox(height: 24),

        // Cartão de Versão e Atualizações do Aplicativo
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            borderRadius: AppRadius.borderMd,
            border: Border.all(
              color: hasUpdate
                  ? (isDark ? AppColors.darkPrimary : AppColors.lightPrimary)
                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              width: hasUpdate ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.darkPrimary
                                      : AppColors.lightPrimary)
                                  .withValues(alpha: 0.15),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Icon(
                          LucideIcons.sparkles,
                          size: 18,
                          color: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ProjectNBX Desktop',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Versão v${AppConfig.version}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      (AppConfig.isDev
                                              ? (isDark
                                                    ? AppColors.darkLavender
                                                    : AppColors.lightLavender)
                                              : (isDark
                                                    ? AppColors.darkSage
                                                    : AppColors.lightSage))
                                          .withValues(alpha: 0.18),
                                  borderRadius: AppRadius.borderXs,
                                ),
                                child: Text(
                                  AppConfig.isDev ? 'DEV' : 'PROD',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppConfig.isDev
                                        ? (isDark
                                              ? AppColors.darkLavender
                                              : AppColors.lightLavender)
                                        : (isDark
                                              ? AppColors.darkSage
                                              : AppColors.lightSage),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Botão de ação (Verificar ou Atualizar)
                  if (hasUpdate)
                    ElevatedButton.icon(
                      onPressed: () => UpdateDialog.show(context),
                      icon: const Icon(LucideIcons.download, size: 14),
                      label: Text(
                        'Nova Versão (v${updateState.latestRelease?.version ?? ""})',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderPill,
                        ),
                      ),
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: isChecking
                          ? null
                          : () {
                              ref
                                  .read(updateControllerProvider.notifier)
                                  .checkForUpdates(silent: false);
                            },
                      icon: isChecking
                          ? SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark
                                    ? AppColors.darkTextPrimary
                                    : AppColors.lightTextPrimary,
                              ),
                            )
                          : const Icon(LucideIcons.refreshCw, size: 13),
                      label: Text(
                        isChecking
                            ? 'Verificando...'
                            : 'Verificar Atualizações',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                        side: BorderSide(
                          color: isDark
                              ? AppColors.darkBorder
                              : AppColors.lightBorder,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderSm,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
              if (updateState.status == UpdateStatus.upToDate) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      LucideIcons.checkCircle2,
                      size: 14,
                      color: isDark ? AppColors.darkSage : AppColors.lightSage,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Você já está utilizando a versão mais recente.',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark
                            ? AppColors.darkSage
                            : AppColors.lightSage,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'INFRAESTRUTURA DE SERVIÇOS',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          ),
        ),
        const SizedBox(height: 12),

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
        borderRadius: AppRadius.borderMd,
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
              borderRadius: AppRadius.borderSm,
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
              borderRadius: AppRadius.borderSm,
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
