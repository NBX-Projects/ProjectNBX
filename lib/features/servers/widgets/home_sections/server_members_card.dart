import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:justtalking/core/theme/app_colors.dart';
import 'package:justtalking/core/theme/app_radius.dart';
import 'package:justtalking/features/servers/models/server_model.dart';
import 'package:justtalking/features/servers/models/server_role_model.dart';

class ServerMembersCard extends StatelessWidget {
  final bool isMobile;
  final bool isDark;
  final ServerModel server;
  final List<Map<String, dynamic>> members;
  final bool isLoading;
  final Color selectedAccentColor;

  const ServerMembersCard({
    super.key,
    this.isMobile = false,
    required this.isDark,
    required this.server,
    required this.members,
    required this.isLoading,
    required this.selectedAccentColor,
  });

  String _getMemberDisplayName(Map<String, dynamic> m) {
    final user = m['user'] as Map<String, dynamic>? ?? {};
    final name = (user['name'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    final username = (user['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;
    final directName = (m['name'] as String?)?.trim();
    if (directName != null && directName.isNotEmpty) return directName;
    final directUsername = (m['username'] as String?)?.trim();
    if (directUsername != null && directUsername.isNotEmpty) {
      return directUsername;
    }
    final email = (user['email'] as String?)?.trim();
    if (email != null && email.isNotEmpty) return email.split('@').first;
    return 'Membro';
  }

  String? _getMemberUsername(Map<String, dynamic> m) {
    final user = m['user'] as Map<String, dynamic>? ?? {};
    final username = (user['username'] as String?)?.trim();
    if (username != null && username.isNotEmpty) return username;
    final directUsername = (m['username'] as String?)?.trim();
    if (directUsername != null && directUsername.isNotEmpty) {
      return directUsername;
    }
    return null;
  }

  String? _getMemberAvatarUrl(Map<String, dynamic> m) {
    final user = m['user'] as Map<String, dynamic>? ?? {};
    final avatar =
        (user['avatar_url'] as String?)?.trim() ??
        (m['avatar_url'] as String?)?.trim();
    if (avatar != null && avatar.isNotEmpty) return avatar;
    return null;
  }

  Widget _buildRoleBadge(dynamic roleData) {
    String name = '';
    Color color = const Color(0xFFF5CBA7);

    if (roleData is Map) {
      name = roleData['name']?.toString() ?? '';
      final cVal = roleData['color'] as int?;
      if (cVal != null) color = Color(cVal);
    } else if (roleData is ServerRoleModel) {
      name = roleData.name;
      color = Color(roleData.color);
    }

    if (name.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        name,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.borderLg,
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
                child: Text(
                  'MEMBROS DO SERVIDOR',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${members.length} membros',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark
                      ? AppColors.darkTextMuted
                      : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (members.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Nenhum membro listado',
                  style: GoogleFonts.inter(
                    color: isDark
                        ? AppColors.darkTextMuted
                        : AppColors.lightTextMuted,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final m = members[index];
                final user = m['user'] as Map<String, dynamic>? ?? {};
                final userId =
                    m['user_id'] as String? ?? user['id'] as String? ?? '';
                final displayName = _getMemberDisplayName(m);
                final username = _getMemberUsername(m);
                final avatarUrl = _getMemberAvatarUrl(m);
                final isOwner = userId == server.ownerId;
                final rawRoles = m['roles'] as List<dynamic>? ?? [];

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF141520)
                        : const Color(0xFFF8FAFC),
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selectedAccentColor.withValues(alpha: 0.2),
                          border: Border.all(
                            color: selectedAccentColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: ClipOval(
                          child: avatarUrl != null
                              ? Image.network(
                                  avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Center(
                                    child: Text(
                                      displayName.isNotEmpty
                                          ? displayName[0].toUpperCase()
                                          : '?',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: selectedAccentColor,
                                      ),
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    displayName.isNotEmpty
                                        ? displayName[0].toUpperCase()
                                        : '?',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: selectedAccentColor,
                                      ),
                                    ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (username != null &&
                                username != displayName) ...[
                              const SizedBox(width: 6),
                              Text(
                                '@$username',
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  color: isDark
                                      ? AppColors.darkTextMuted
                                      : AppColors.lightTextMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5CBA7).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'DONO',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFF5CBA7),
                            ),
                          ),
                        ),
                      ],
                      for (final r in rawRoles) ...[
                        const SizedBox(width: 6),
                        _buildRoleBadge(r),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
