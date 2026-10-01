import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';

class UserStatusChip extends StatefulWidget {
  final UserModel? user;
  final bool isDark;

  const UserStatusChip({super.key, required this.user, required this.isDark});

  @override
  State<UserStatusChip> createState() => _UserStatusChipState();
}

class _UserStatusChipState extends State<UserStatusChip> {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _profileEntry;
  late String _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = _normalizeStatus(widget.user?.status);
  }

  @override
  void didUpdateWidget(covariant UserStatusChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user?.status != widget.user?.status && _profileEntry == null) {
      _selectedStatus = _normalizeStatus(widget.user?.status);
    }
  }

  @override
  void dispose() {
    _profileEntry?.remove();
    _profileEntry = null;
    super.dispose();
  }

  String get _displayName {
    final fullName = widget.user?.displayName.trim() ?? '';
    final name = fullName.isEmpty ? (widget.user?.username.trim() ?? '') : fullName;
    return name.isEmpty ? 'User' : name.split(RegExp(r'\s+')).first;
  }

  void _toggleProfile() {
    if (_profileEntry != null) {
      _closeProfile();
      return;
    }

    _selectedStatus = _normalizeStatus(widget.user?.status);
    _profileEntry = OverlayEntry(
      builder: (context) => Stack(
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
              user: widget.user,
              displayName: _displayName,
              status: _selectedStatus,
              isDark: widget.isDark,
              onStatusChanged: (status) {
                _selectedStatus = status;
                _profileEntry?.markNeedsBuild();
              },
              onComplete: _closeProfile,
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_profileEntry!);
    setState(() {});
  }

  void _closeProfile() {
    _profileEntry?.remove();
    _profileEntry = null;
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(_selectedStatus);
    final initial = _displayName[0].toUpperCase();
    final avatarUrl = widget.user?.avatarUrl?.trim();

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: _profileEntry != null
              ? (widget.isDark ? const Color(0xFF2B2F36) : const Color(0xFFF1F5F9))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: _toggleProfile,
            mouseCursor: SystemMouseCursors.click,
            borderRadius: BorderRadius.circular(9),
            child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF5865F2), Color(0xFF7289DA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: ClipOval(
                        child: avatarUrl != null && avatarUrl.isNotEmpty
                            ? Image.network(
                                avatarUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildInitial(initial),
                              )
                            : Center(
                                child: Text(
                                  initial,
                                  style: GoogleFonts.jetBrainsMono(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
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
                      _statusLabel(_selectedStatus),
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
  );
}

  Widget _buildInitial(String initial) {
    return Center(
      child: Text(
        initial,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: widget.isDark
              ? const Color(0xFFC5B4E3)
              : const Color(0xFF5B4282),
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
  final VoidCallback onComplete;

  const _ProfilePopover({
    required this.user,
    required this.displayName,
    required this.status,
    required this.isDark,
    required this.onStatusChanged,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final panelColor = isDark ? const Color(0xFF2B2F36) : Colors.white;
    final mutedColor = isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted;
    final avatarUrl = user?.avatarUrl?.trim();
    final initial = displayName[0].toUpperCase();

    return Material(
      color: panelColor,
      elevation: 14,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: SizedBox(
        width: 220,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF5865F2), Color(0xFF7289DA)],
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
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.darkTextPrimary
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          'Personalizar perfil',
                          style: GoogleFonts.inter(fontSize: 10, color: mutedColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
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
                  for (final option in const ['online', 'ausente', 'ocupado']) ...[
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
              const SizedBox(height: 11),
              SizedBox(
                width: double.infinity,
                height: 30,
                child: FilledButton(
                  onPressed: onComplete,
                  style: FilledButton.styleFrom(
                    enabledMouseCursor: SystemMouseCursors.click,
                    backgroundColor: const Color(0xFF5865F2),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: Text(
                    'Concluir',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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
    final color = _statusColor(status);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 25,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.14)
              : (isDark ? const Color(0xFF202225) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(6),
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
            color: selected ? color : (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
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
      return 'ausente';
    case 'ocupado':
    case 'busy':
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

Color _statusColor(String status) {
  switch (status) {
    case 'ausente':
      return const Color(0xFFFAA61A);
    case 'ocupado':
      return const Color(0xFFF04747);
    default:
      return const Color(0xFF43B581);
  }
}

Widget _buildProfileInitial(String initial, bool isDark) {
  return Center(
    child: Text(
      initial,
      style: GoogleFonts.jetBrainsMono(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: isDark ? const Color(0xFFC5B4E3) : const Color(0xFF5B4282),
      ),
    ),
  );
}
