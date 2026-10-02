import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/localization/app_strings.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/auth/controllers/auth_controller.dart';
import 'package:justtalking/features/auth/models/user_model.dart';
import 'package:justtalking/features/settings/widgets/dialogs/change_password_dialog.dart';
import 'package:justtalking/features/settings/widgets/dialogs/profile_image_dialog.dart';
import 'package:justtalking/features/settings/widgets/section_header.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class AccountSection extends ConsumerStatefulWidget {
  final bool isDark;
  final UserModel? user;
  final AppStrings strings;
  final bool isMobile;

  const AccountSection({
    super.key,
    required this.isDark,
    required this.user,
    required this.strings,
    this.isMobile = false,
  });

  @override
  ConsumerState<AccountSection> createState() => _AccountSectionState();
}

class _AccountSectionState extends ConsumerState<AccountSection> {
  String _userStatus = 'online';
  bool _isEditingProfile = false;
  bool _isSavingProfile = false;
  final _profileFormKey = GlobalKey<FormState>();
  final _nameEditController = TextEditingController();
  final _usernameEditController = TextEditingController();
  final _emailEditController = TextEditingController();
  final _bioEditController = TextEditingController();
  final _customStatusEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initUserStatus(widget.user);
  }

  @override
  void didUpdateWidget(covariant AccountSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.user?.status != oldWidget.user?.status) {
      _initUserStatus(widget.user);
    }
  }

  void _initUserStatus(UserModel? user) {
    if (user != null && user.status.isNotEmpty) {
      final st = user.status.toLowerCase();
      if (st == 'ausente' || st == 'away' || st == 'idle') {
        _userStatus = 'idle';
      } else if (st == 'ocupado' || st == 'busy' || st == 'dnd') {
        _userStatus = 'dnd';
      } else {
        _userStatus = 'online';
      }
    }
  }

  @override
  void dispose() {
    _nameEditController.dispose();
    _usernameEditController.dispose();
    _emailEditController.dispose();
    _bioEditController.dispose();
    _customStatusEditController.dispose();
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
      _bioEditController.text = user?.bio ?? '';
      _customStatusEditController.text = user?.customStatus ?? '';
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
          bio: _bioEditController.text.trim(),
          customStatus: _customStatusEditController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final user = widget.user;
    final strings = widget.strings;
    final isMobile = widget.isMobile;

    final displayName = (user?.name.isNotEmpty == true)
        ? user!.name
        : (user?.username.isNotEmpty == true ? user!.username : 'User name');
    final username = user?.username.isNotEmpty == true
        ? user!.username
        : 'username';
    final email = user?.email.isNotEmpty == true
        ? user!.email
        : 'email@email.com';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final avatarUrl = user?.avatarUrl?.trim();
    final bannerUrl = user?.bannerUrl?.trim();
    final hasBanner = bannerUrl != null && bannerUrl.isNotEmpty;
    final isGifAvatar = user?.isGifAvatar == true;
    final isGifBanner = user?.isGifBanner == true;
    final customStatus = user?.customStatus?.trim();
    final bio = user?.bio?.trim();

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

    // Normaliza o status para o dropdown
    String currentDropdownStatus = _userStatus;
    if (currentDropdownStatus == 'ausente' || currentDropdownStatus == 'away') {
      currentDropdownStatus = 'idle';
    } else if (currentDropdownStatus == 'ocupado' ||
        currentDropdownStatus == 'busy') {
      currentDropdownStatus = 'dnd';
    } else if (currentDropdownStatus != 'idle' &&
        currentDropdownStatus != 'dnd') {
      currentDropdownStatus = 'online';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          isDark: isDark,
          title: strings.myAccount,
          description: 'Gerencie seus dados pessoais, credenciais de acesso e segurança da conta',
        ),
        const SizedBox(height: 24),

        // 1. User Profile Details Card (com Capa e Avatar Modernos)
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: AppRadius.borderLg,
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Capa de Perfil (Banner)
              Stack(
                children: [
                  Container(
                    height: 135,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: !hasBanner
                          ? LinearGradient(
                              colors: isDark
                                  ? [
                                      const Color(0xFF2C243B),
                                      const Color(0xFF1E2030),
                                      const Color(0xFF1A2634),
                                    ]
                                  : [
                                      const Color(0xFFD8E2DC),
                                      const Color(0xFFFFE5D9),
                                      const Color(0xFFECE4DB),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      image: hasBanner
                          ? DecorationImage(
                              image: NetworkImage(bannerUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                  ),
                  if (isGifBanner)
                    Positioned(
                      top: 10,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'GIF ANIMADO',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 12,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.6),
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white38),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.borderPill,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                      onPressed: () => ProfileImageDialog.show(
                        context,
                        ref,
                        isAvatar: false,
                      ),
                      icon: const Icon(
                        LucideIcons.image,
                        size: 13,
                        color: Colors.white,
                      ),
                      label: Text(
                        hasBanner ? 'Alterar Capa' : 'Adicionar Capa',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Header Content com Avatar Sobreposto
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.translate(
                      offset: const Offset(0, -32),
                      child: isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Stack(
                                      children: [
                                        Container(
                                          width: 78,
                                          height: 78,
                                          decoration: BoxDecoration(
                                            color: isDark
                                                ? AppColors.darkLavender
                                                : AppColors.lightLavender,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: cardBg,
                                              width: 3.5,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child:
                                                avatarUrl != null &&
                                                    avatarUrl.isNotEmpty
                                                ? Image.network(
                                                    avatarUrl,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (
                                                          context,
                                                          error,
                                                          stackTrace,
                                                        ) => Center(
                                                          child: Text(
                                                            initial,
                                                            style: GoogleFonts.jetBrainsMono(
                                                              fontSize: 26,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: isDark
                                                                  ? Colors.black
                                                                  : Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                  )
                                                : Center(
                                                    child: Text(
                                                      initial,
                                                      style:
                                                          GoogleFonts.jetBrainsMono(
                                                            fontSize: 26,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: isDark
                                                                ? Colors.black
                                                                : Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        if (isGifAvatar)
                                          Positioned(
                                            left: 0,
                                            bottom: 0,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                    vertical: 1,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.8,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                              ),
                                              child: Text(
                                                'GIF',
                                                style:
                                                    GoogleFonts.jetBrainsMono(
                                                      fontSize: 7.5,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: InkWell(
                                            onTap: () => ProfileImageDialog.show(
                                              context,
                                              ref,
                                              isAvatar: true,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Container(
                                              width: 26,
                                              height: 26,
                                              decoration: BoxDecoration(
                                                color: primaryColor,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: cardBg,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                LucideIcons.camera,
                                                size: 13,
                                                color: onPrimaryColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                              fontSize: 18,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color:
                                                                  textPrimary,
                                                            ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2.5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        (isDark
                                                                ? AppColors
                                                                      .darkSage
                                                                : AppColors
                                                                      .lightSage)
                                                            .withValues(
                                                              alpha: 0.15,
                                                            ),
                                                    borderRadius:
                                                        AppRadius.borderPill,
                                                    border: Border.all(
                                                      color:
                                                          (isDark
                                                                  ? AppColors
                                                                        .darkSage
                                                                  : AppColors
                                                                        .lightSage)
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    strings.connected,
                                                    style:
                                                        GoogleFonts.jetBrainsMono(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: isDark
                                                              ? AppColors
                                                                    .darkSage
                                                              : AppColors
                                                                    .lightSage,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
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
                                                fontSize: 12,
                                                color: textMuted,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!_isEditingProfile) ...[
                                  const SizedBox(height: 14),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
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
                                          horizontal: 14,
                                          vertical: 10,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _startEditingProfile(user),
                                      icon: const Icon(
                                        LucideIcons.pencil,
                                        size: 13,
                                      ),
                                      label: Text(
                                        'Editar Perfil',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      width: 78,
                                      height: 78,
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkLavender
                                            : AppColors.lightLavender,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: cardBg,
                                          width: 3.5,
                                        ),
                                      ),
                                      child: ClipOval(
                                        child:
                                            avatarUrl != null &&
                                                avatarUrl.isNotEmpty
                                            ? Image.network(
                                                avatarUrl,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (
                                                      context,
                                                      error,
                                                      stackTrace,
                                                    ) => Center(
                                                      child: Text(
                                                        initial,
                                                        style:
                                                            GoogleFonts.jetBrainsMono(
                                                              fontSize: 26,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w800,
                                                              color: isDark
                                                                  ? Colors.black
                                                                  : Colors
                                                                        .white,
                                                            ),
                                                      ),
                                                    ),
                                              )
                                            : Center(
                                                child: Text(
                                                  initial,
                                                  style:
                                                      GoogleFonts.jetBrainsMono(
                                                        fontSize: 26,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        color: isDark
                                                            ? Colors.black
                                                            : Colors.white,
                                                      ),
                                                ),
                                              ),
                                      ),
                                    ),
                                    if (isGifAvatar)
                                      Positioned(
                                        left: 0,
                                        bottom: 0,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 4,
                                            vertical: 1,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.8,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              3,
                                            ),
                                          ),
                                          child: Text(
                                            'GIF',
                                            style: GoogleFonts.jetBrainsMono(
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: InkWell(
                                        onTap: () => ProfileImageDialog.show(
                                          context,
                                          ref,
                                          isAvatar: true,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Container(
                                          width: 26,
                                          height: 26,
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: cardBg,
                                              width: 2,
                                            ),
                                          ),
                                          child: Icon(
                                            LucideIcons.camera,
                                            size: 13,
                                            color: onPrimaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          color: textPrimary,
                                                        ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color:
                                                    (isDark
                                                            ? AppColors.darkSage
                                                            : AppColors
                                                                  .lightSage)
                                                        .withValues(
                                                          alpha: 0.15,
                                                        ),
                                                borderRadius:
                                                    AppRadius.borderPill,
                                                border: Border.all(
                                                  color:
                                                      (isDark
                                                              ? AppColors
                                                                    .darkSage
                                                              : AppColors
                                                                    .lightSage)
                                                          .withValues(
                                                            alpha: 0.3,
                                                          ),
                                                ),
                                              ),
                                              child: Text(
                                                strings.connected,
                                                style:
                                                    GoogleFonts.jetBrainsMono(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: isDark
                                                          ? AppColors.darkSage
                                                          : AppColors.lightSage,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
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
                                ),
                                if (!_isEditingProfile)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: ElevatedButton.icon(
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
                                          horizontal: 14,
                                          vertical: 8,
                                        ),
                                      ),
                                      onPressed: () =>
                                          _startEditingProfile(user),
                                      icon: const Icon(
                                        LucideIcons.pencil,
                                        size: 13,
                                      ),
                                      label: Text(
                                        'Editar Perfil',
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),

                    if (customStatus != null && customStatus.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.04),
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(color: borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              size: 14,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                customStatus,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (bio != null && bio.isNotEmpty) ...[
                      Text(
                        'Sobre Mim',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bio,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          color: textSecondary,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    Divider(color: borderColor),
                    const SizedBox(height: 16),

                    // Formulário de Edição Interativo ou Dados Readonly
                    if (_isEditingProfile) ...[
                      Form(
                        key: _profileFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Atualizar Informações e Preferências',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _nameEditController,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13.5,
                              ),
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
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13.5,
                              ),
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
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13.5,
                              ),
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
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _customStatusEditController,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13.5,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Status Customizado (Mensagem)',
                                hintText: 'Ex: Desenvolvendo com Flutter 🚀',
                                prefixIcon: Icon(
                                  LucideIcons.sparkles,
                                  size: 16,
                                  color: textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bioEditController,
                              maxLines: 3,
                              maxLength: 300,
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 13.5,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Sobre Mim (Bio)',
                                hintText: 'Conte um pouco sobre você...',
                                alignLabelWithHint: true,
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 40),
                                  child: Icon(
                                    LucideIcons.fileText,
                                    size: 16,
                                    color: textSecondary,
                                  ),
                                ),
                              ),
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
                                  onPressed: _isSavingProfile
                                      ? null
                                      : _saveProfile,
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
                        currentDropdownStatus == 'online'
                            ? strings.currentStatusOnline
                            : (currentDropdownStatus == 'idle'
                                  ? strings.idle
                                  : strings.dnd),
                        action: DropdownButton<String>(
                          value: currentDropdownStatus,
                          dropdownColor: cardBg,
                          underline: const SizedBox(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: textPrimary,
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
                          onChanged: (val) async {
                            if (val != null) {
                              setState(() => _userStatus = val);
                              await ref
                                  .read(authControllerProvider.notifier)
                                  .updateStatus(val);
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
              isMobile
                  ? Column(
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
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  Text(
                                    'Sua conta é protegida por criptografia de alta segurança bcrypt',
                                    style: GoogleFonts.inter(
                                      fontSize: 11.5,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
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
                            onPressed: () =>
                                ChangePasswordDialog.show(context, ref, isDark: isDark),
                            icon: const Icon(LucideIcons.keyRound, size: 14),
                            label: Text(
                              'Alterar Senha',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
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
                          onPressed: () =>
                              ChangePasswordDialog.show(context, ref, isDark: isDark),
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
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: dangerColor.withValues(alpha: 0.12),
                            borderRadius: AppRadius.borderSm,
                          ),
                          child: Icon(
                            LucideIcons.logOut,
                            size: 20,
                            color: dangerColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Encerrar Sessão',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: textPrimary,
                                ),
                              ),
                              Text(
                                'Desconectar seu usuário deste dispositivo com segurança',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: dangerColor,
                          side: BorderSide(
                            color: dangerColor.withValues(alpha: 0.6),
                          ),
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
                    ),
                  ],
                )
              : Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: dangerColor.withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Icon(
                        LucideIcons.logOut,
                        size: 20,
                        color: dangerColor,
                      ),
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
                        side: BorderSide(
                          color: dangerColor.withValues(alpha: 0.6),
                        ),
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
}
