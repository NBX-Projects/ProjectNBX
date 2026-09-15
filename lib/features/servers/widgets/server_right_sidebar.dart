import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/features/chat/utils/chat_helpers.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/servers/models/server_workspace_enums.dart';
import 'package:projectnbx/features/servers/widgets/docked_voice_footer.dart';
import 'package:projectnbx/features/servers/widgets/invite_member_dialog.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
import 'package:projectnbx/features/voice/models/voice_participant_info.dart';

/// Barra lateral direita do workspace do servidor: Canais, Membros e Resumo estatístico
class ServerRightSidebar extends StatefulWidget {
  final bool isDark;
  final ServerModel server;
  final List<ChannelModel> channels;
  final ChannelModel? activeChannel;
  final String username;
  final Color accentColor;
  final String? clientSessionId;
  final Map<String, Map<String, VoiceParticipantInfo>> voiceParticipants;
  final List<Map<String, dynamic>> serverMembers;
  final VoiceState voiceState;
  final VoiceStateNotifier voiceNotifier;
  final ValueChanged<ChannelModel> onChannelSelected;
  final ValueChanged<VoiceParticipantInfo>? onWatchStream;
  final VoidCallback onLeaveVoice;
  final VoidCallback? onMembersUpdated;
  final String? connectedVoiceChannelId;
  final ServerSidebarTab initialTab;

  const ServerRightSidebar({
    super.key,
    required this.isDark,
    required this.server,
    required this.channels,
    this.activeChannel,
    required this.username,
    required this.accentColor,
    this.clientSessionId,
    required this.voiceParticipants,
    required this.serverMembers,
    required this.voiceState,
    required this.voiceNotifier,
    required this.onChannelSelected,
    this.onWatchStream,
    required this.onLeaveVoice,
    this.onMembersUpdated,
    this.connectedVoiceChannelId,
    this.initialTab = ServerSidebarTab.canais,
  });

  @override
  State<ServerRightSidebar> createState() => _ServerRightSidebarState();
}

class _ServerRightSidebarState extends State<ServerRightSidebar> {
  late ServerSidebarTab _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  List<VoiceParticipantInfo> _getChannelVoiceParticipants(String channelId) {
    final map = widget.voiceParticipants[channelId];
    if (map == null) return [];
    return map.values.where((p) => p.isInVoice).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final activeCh = widget.activeChannel ??
        (widget.channels.isNotEmpty ? widget.channels.first : null);

    final channelName = widget.connectedVoiceChannelId != null && activeCh != null
        ? activeCh.name
        : 'geral';

    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141522) : const Color(0xFFFAF9F6),
        border: Border(
          left: BorderSide(
            color: isDark ? const Color(0xFF202234) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        children: [
          // Header Tabs: Canais | Membros | Resumo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF202234)
                      : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                _buildTabButton(
                  title: 'Canais',
                  tab: ServerSidebarTab.canais,
                  icon: LucideIcons.volume2,
                ),
                _buildTabButton(
                  title: 'Membros',
                  tab: ServerSidebarTab.membros,
                  icon: LucideIcons.users,
                ),
                _buildTabButton(
                  title: 'Resumo',
                  tab: ServerSidebarTab.resumo,
                  icon: LucideIcons.barChart2,
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(child: _buildTabContent(activeCh)),

          // Bottom Voice Connection Status (Docked Footer)
          DockedVoiceFooter(
            isDark: isDark,
            channelName: channelName,
            serverName: widget.server.name,
            voiceState: widget.voiceState,
            voiceNotifier: widget.voiceNotifier,
            onLeaveVoice: widget.onLeaveVoice,
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required ServerSidebarTab tab,
    required IconData icon,
  }) {
    final isSelected = _activeTab == tab;
    final isDark = widget.isDark;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _activeTab = tab),
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? const Color(0xFF25283E) : const Color(0xFFE2E8F0))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected
                    ? (isDark ? widget.accentColor : const Color(0xFF0F172A))
                    : (isDark
                          ? AppColors.darkTextMuted
                          : AppColors.lightTextMuted),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (isDark
                              ? AppColors.darkTextPrimary
                              : const Color(0xFF0F172A))
                        : (isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ChannelModel? activeCh) {
    final isDark = widget.isDark;
    final channels = widget.channels;
    final otherChannels = activeCh != null
        ? channels.where((c) => c.id != activeCh.id).toList()
        : channels;

    switch (_activeTab) {
      case ServerSidebarTab.canais:
        final activeParticipants = activeCh != null
            ? _getChannelVoiceParticipants(activeCh.id)
            : <VoiceParticipantInfo>[];
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          children: [
            // 1. Active Channel Highlighted Card
            if (activeCh != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2034)
                      : const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF333758)
                        : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Channel Header
                    InkWell(
                      onTap: () => widget.onChannelSelected(activeCh),
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              LucideIcons.volume2,
                              size: 15,
                              color: Color(0xFF22C55E),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activeCh.name,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (activeParticipants.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF14532D,
                                  ).withValues(alpha: isDark ? 0.6 : 0.15),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  activeParticipants.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    // Real Connected Participants list
                    if (activeParticipants.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 12,
                          right: 10,
                          bottom: 8,
                        ),
                        child: Column(
                          children: activeParticipants.map((p) {
                            final isMe = p.sessionId == widget.clientSessionId;
                            final devLabel = p.device == 'mobile'
                                ? ' (Celular)'
                                : p.device == 'desktop'
                                    ? ' (Desktop)'
                                    : '';
                            final displayName =
                                '${p.username}$devLabel${isMe ? " (Você)" : ""}';
                            return InkWell(
                              onTap: () {
                                if (p.isTransmitting && !isMe) {
                                  widget.onWatchStream?.call(p);
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: _buildNestedMemberRow(
                                initials: getAuthorInitials(p.username),
                                name: displayName,
                                color: resolveAuthorColor(p.username, isDark),
                                isConnecting: p.isConnecting,
                                isLive: p.isTransmitting,
                                isDark: isDark,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              ),

            // 2. Real Other Channels from Server
            ...otherChannels.map((c) {
              final chParticipants = _getChannelVoiceParticipants(c.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 2),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => widget.onChannelSelected(c),
                      mouseCursor: SystemMouseCursors.click,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              chParticipants.isNotEmpty
                                  ? LucideIcons.volume2
                                  : LucideIcons.hash,
                              size: 14,
                              color: chParticipants.isNotEmpty
                                  ? const Color(0xFF22C55E)
                                  : (isDark
                                      ? Colors.white54
                                      : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                c.name,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                            if (chParticipants.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF14532D)
                                      .withValues(alpha: isDark ? 0.6 : 0.15),
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                                child: Text(
                                  chParticipants.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF22C55E),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (chParticipants.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 24,
                          right: 10,
                          bottom: 4,
                        ),
                        child: Column(
                          children: chParticipants.map((p) {
                            final isMe = p.sessionId == widget.clientSessionId;
                            final devLabel = p.device == 'mobile'
                                ? ' (Celular)'
                                : p.device == 'desktop'
                                    ? ' (Desktop)'
                                    : '';
                            return InkWell(
                              onTap: () {
                                if (p.isTransmitting && !isMe) {
                                  widget.onChannelSelected(c);
                                  widget.onWatchStream?.call(p);
                                }
                              },
                              borderRadius: BorderRadius.circular(6),
                              child: _buildNestedMemberRow(
                                initials: getAuthorInitials(p.username),
                                name:
                                    '${p.username}$devLabel${isMe ? " (Você)" : ""}',
                                color: resolveAuthorColor(p.username, isDark),
                                isConnecting: p.isConnecting,
                                isLive: p.isTransmitting,
                                isDark: isDark,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ],
        );

      case ServerSidebarTab.membros:
        final membersList = widget.serverMembers.isNotEmpty
            ? widget.serverMembers
            : [
                {
                  'user': {
                    'username': widget.username.isNotEmpty
                        ? widget.username
                        : 'Você'
                  },
                  'role': 'owner',
                },
              ];

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          children: [
            // Quick Invite Button
            InkWell(
              onTap: () => InviteMemberDialog.show(
                context,
                widget.server,
                onMembersUpdated: widget.onMembersUpdated,
              ),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: widget.accentColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.userPlus,
                      size: 14,
                      color: widget.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Convidar Pessoas',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
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
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                'MEMBROS — ${membersList.length}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: const Color(0xFF22C55E),
                ),
              ),
            ),

            ...membersList.map((m) {
              final user = m['user'] as Map<String, dynamic>? ?? {};
              final uName = user['username'] ?? m['username'] ?? widget.username;
              final role = m['role'] ?? 'member';
              final isOwner = role == 'owner';

              return _buildSidebarMemberRow(
                uName.toString(),
                isOwner ? '👑 Dono & Criador' : 'Membro',
                isOwner
                    ? widget.accentColor
                    : (isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B)),
                isDark,
              );
            }),
          ],
        );

      case ServerSidebarTab.resumo:
        final allParticipants = widget.voiceParticipants.values.expand((m) => m.values);
        final membersInCall = widget.voiceParticipants.values.fold<int>(
          0,
          (sum, m) => sum + m.values.where((p) => p.isInVoice).length,
        );
        final isBroadcasting = allParticipants.any(
          (p) => p.isInVoice && p.isTransmitting,
        );

        return Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estatísticas do Canal',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '• Canais Híbridos: ${channels.length}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Membros em Chamada: $membersInCall',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '• Transmissão: ${isBroadcasting ? "Ao Vivo (Transmitindo tela)" : "Inativa"}',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildNestedMemberRow({
    required String initials,
    required String name,
    required Color color,
    bool isConnecting = false,
    required bool isLive,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.6), width: 1),
            ),
            child: Center(
              child: Text(
                initials,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
          if (isConnecting)
            Tooltip(
              message: 'Conectando ao canal de voz...',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1.5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 7,
                      height: 7,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'CONECTANDO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isLive)
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : const Color(0xFF1E293B),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'AO VIVO',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: Color(0xFFC084FC),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSidebarMemberRow(
    String name,
    String role,
    Color color,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : 'U',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.jetBrainsMono(fontSize: 9, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
