import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/core/theme/theme_controller.dart';
import 'package:justtalking/features/auth/controllers/auth_controller.dart';
import 'package:justtalking/features/auth/models/user_model.dart';
import 'package:justtalking/features/settings/screens/settings_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class UserStatusChip extends ConsumerStatefulWidget {
  final UserModel? user;
  final bool isDark;
  final VoidCallback? onToggleTheme;

  const UserStatusChip({
    super.key,
    required this.user,
    required this.isDark,
    this.onToggleTheme,
  });

  @override
  ConsumerState<UserStatusChip> createState() => _UserStatusChipState();
}

class _UserStatusChipState extends ConsumerState<UserStatusChip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _profileEntry;
  String? _localSelectedStatus;

  UserModel? get _currentUser {
    return ref.watch(authControllerProvider).user ?? widget.user;
  }

  String get _currentStatus {
    return _localSelectedStatus ?? _normalizeStatus(_currentUser?.status);
  }

  @override
  void dispose() {
    _profileEntry?.remove();
    _profileEntry = null;
    super.dispose();
  }

  String get _displayName {
    final user = _currentUser;
    final fullName = user?.displayName.trim() ?? '';
    final name = fullName.isEmpty ? (user?.username.trim() ?? '') : fullName;
    return name.isEmpty ? 'User' : name.split(RegExp(r'\s+')).first;
  }

  void _onStatusSelected(String status) {
    setState(() {
      _localSelectedStatus = status;
    });
    ref.read(authControllerProvider.notifier).updateStatus(status);
    _profileEntry?.markNeedsBuild();
  }

  void _toggleProfile() {
    if (_profileEntry != null) {
      _closeProfile();
      return;
    }

    _localSelectedStatus = _normalizeStatus(_currentUser?.status);
    _profileEntry = OverlayEntry(
      builder: (context) {
        final activeUser = ref.watch(authControllerProvider).user ?? widget.user;
        final currentSt = _localSelectedStatus ?? _normalizeStatus(activeUser?.status);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _closeProfile,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              targetAnchor: Alignment.bottomRight,
              followerAnchor: Alignment.topRight,
              offset: const Offset(0, 8),
              child: _ProfilePopover(
                user: activeUser,
                displayName: _displayName,
                status: currentSt,
                isDark: isDark,
                onStatusChanged: _onStatusSelected,
                onToggleTheme: _toggleTheme,
                onOpenSettings: _openSettings,
                onComplete: _closeProfile,
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_profileEntry!);
    setState(() {});
  }

  void _toggleTheme() {
    if (widget.onToggleTheme != null) {
      widget.onToggleTheme!();
    } else {
      ref.read(themeModeProvider.notifier).toggleTheme();
    }
    _profileEntry?.markNeedsBuild();
  }

  void _closeProfile() {
    _profileEntry?.remove();
    _profileEntry = null;
    if (mounted) setState(() {});
  }

  void _openSettings() {
    _closeProfile();
    SettingsScreen.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;
    final status = _currentStatus;
    final statusColor = _statusColor(status, widget.isDark);
    final initial = _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U';
    final avatarUrl = user?.avatarUrl?.trim();

    return Semantics(
      button: true,
      label: 'Abrir menu do perfil de $_displayName',
      child: Tooltip(
        message: 'Perfil e configurações',
        child: CompositedTransformTarget(
          link: _layerLink,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Material(
              color: _profileEntry != null
                  ? (widget.isDark
                        ? AppColors.darkSurfaceElevated
                        : AppColors.lightSurfaceElevated)
                  : Colors.transparent,
              borderRadius: AppRadius.borderSm,
              child: InkWell(
                onTap: _toggleProfile,
                mouseCursor: SystemMouseCursors.click,
                borderRadius: AppRadius.borderSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.isDark
                                  ? AppColors.darkLavender
                                  : AppColors.lightLavender,
                            ),
                            child: ClipOval(
                              child: avatarUrl != null && avatarUrl.isNotEmpty
                                  ? Image.network(
                                      avatarUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              _buildInitial(initial),
                                    )
                                  : Center(
                                      child: Text(
                                        initial,
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: widget.isDark
                                              ? AppColors.darkCanvas
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: statusColor,
                                border: Border.all(
                                  color: widget.isDark
                                      ? const Color(0xFF141520)
                                      : Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            _statusLabel(status),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: widget.isDark ? AppColors.darkCanvas : Colors.white,
        ),
      ),
    );
  }
}

class _ProfilePopover extends StatelessWidget {
  final UserModel? user;
  final String displayName;
  final String status;
  final bool isDark;
  final ValueChanged<String> onStatusChanged;
  final VoidCallback onToggleTheme;
  final VoidCallback onOpenSettings;
  final VoidCallback onComplete;

  const _ProfilePopover({
    required this.user,
    required this.displayName,
    required this.status,
    required this.isDark,
    required this.onStatusChanged,
    required this.onToggleTheme,
    required this.onOpenSettings,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final panelColor = isDark
        ? AppColors.darkSurfaceElevated
        : AppColors.lightSurface;
    final mutedColor = isDark
        ? AppColors.darkTextMuted
        : AppColors.lightTextMuted;
    final avatarUrl = user?.avatarUrl?.trim();
    final bannerUrl = user?.bannerUrl?.trim();
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';
    final hasBanner = bannerUrl != null && bannerUrl.isNotEmpty;
    final isGifAvatar = user?.isGifAvatar == true;
    final isGifBanner = user?.isGifBanner == true;
    final customStatus = user?.customStatus?.trim();

    return Material(
      color: panelColor,
      elevation: 14,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderSm,
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini Capa / Banner
            Container(
              height: 52,
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
              child: isGifBanner
                  ? Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        margin: const EdgeInsets.all(5),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'GIF',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.translate(
                    offset: const Offset(0, -18),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? AppColors.darkLavender
                                    : AppColors.lightLavender,
                                border: Border.all(
                                  color: panelColor,
                                  width: 2.5,
                                ),
                              ),
                              child: ClipOval(
                                child: avatarUrl != null && avatarUrl.isNotEmpty
                                    ? Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            _buildProfileInitial(initial, isDark),
                                      )
                                    : Center(
                                        child: Text(
                                          initial,
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.darkCanvas
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
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0.5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.75),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'GIF',
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _statusColor(status, isDark),
                                  border: Border.all(
                                    color: panelColor,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (user?.username.isNotEmpty == true)
                                Text(
                                  '@${user!.username}',
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.darkPrimary
                                        : AppColors.lightPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (customStatus != null && customStatus.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      child: Text(
                        customStatus,
                        style: GoogleFonts.inter(
                          fontSize: 10.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'STATUS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: mutedColor,
                ),
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  for (final option in const [
                    'online',
                    'ausente',
                    'ocupado',
                  ]) ...[
                    if (option != 'online') const SizedBox(width: 5),
                    Expanded(
                      child: _ProfileStatusButton(
                        status: option,
                        selected: status == option,
                        isDark: isDark,
                        onTap: () => onStatusChanged(option),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // Tema (somente ícone)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Semantics(
                      button: true,
                      label: isDark ? 'Modo Claro' : 'Modo Escuro',
                      child: OutlinedButton(
                        onPressed: onToggleTheme,
                        style: OutlinedButton.styleFrom(
                          enabledMouseCursor: SystemMouseCursors.click,
                          foregroundColor: isDark
                              ? const Color(0xFFF5CBA7)
                              : const Color(0xFF2D6A4F),
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          padding: EdgeInsets.zero,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderXs,
                          ),
                        ),
                        child: Icon(
                          isDark ? LucideIcons.sun : LucideIcons.moon,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Configurações (somente ícone)
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Semantics(
                      button: true,
                      label: 'Configurações',
                      child: OutlinedButton(
                        onPressed: onOpenSettings,
                        style: OutlinedButton.styleFrom(
                          enabledMouseCursor: SystemMouseCursors.click,
                          foregroundColor: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                          side: BorderSide(
                            color: isDark
                                ? AppColors.darkBorder
                                : AppColors.lightBorder,
                          ),
                          padding: EdgeInsets.zero,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderXs,
                          ),
                        ),
                        child: const Icon(LucideIcons.settings, size: 16),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Concluir (botão mais flat, ocupando o restante do espaço)
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: FilledButton(
                        onPressed: onComplete,
                        style: FilledButton.styleFrom(
                          enabledMouseCursor: SystemMouseCursors.click,
                          backgroundColor: isDark
                              ? AppColors.darkPrimary
                              : AppColors.lightPrimary,
                          foregroundColor: isDark
                              ? AppColors.darkCanvas
                              : Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.borderXs,
                          ),
                        ),
                        child: Text(
                          'Concluir',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);
  }
}

class _ProfileStatusButton extends StatelessWidget {
  final String status;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _ProfileStatusButton({
    required this.status,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status, isDark);
    return Semantics(
      button: true,
      selected: selected,
      label: 'Status ${_statusLabel(status)}',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: InkWell(
          onTap: onTap,
          mouseCursor: SystemMouseCursors.click,
          borderRadius: AppRadius.borderXs,
          child: Container(
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.14)
                  : (isDark
                        ? const Color(0xFF202225)
                        : const Color(0xFFF1F5F9)),
              borderRadius: AppRadius.borderXs,
              border: Border.all(
                color: selected
                    ? color
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
            ),
            child: Text(
              _statusLabel(status),
              style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? color
                    : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _normalizeStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'ausente':
    case 'away':
    case 'idle':
      return 'ausente';
    case 'ocupado':
    case 'busy':
    case 'dnd':
      return 'ocupado';
    default:
      return 'online';
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'ausente':
      return 'Ausente';
    case 'ocupado':
      return 'Ocupado';
    default:
      return 'Online';
  }
}

Color _statusColor(String status, bool isDark) {
  switch (status) {
    case 'ausente':
      return isDark ? AppColors.darkPrimary : AppColors.lightPeach;
    case 'ocupado':
      return isDark ? AppColors.darkDanger : AppColors.lightDanger;
    default:
      return isDark ? AppColors.darkSage : AppColors.lightSage;
  }
}

Widget _buildProfileInitial(String initial, bool isDark) {
  return Center(
    child: Text(
      initial,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: isDark ? AppColors.darkCanvas : Colors.white,
      ),
    ),
  );
}
