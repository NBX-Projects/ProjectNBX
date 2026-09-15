import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/core/theme/app_colors.dart';
import 'package:projectnbx/features/chat/utils/chat_helpers.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:projectnbx/features/voice/models/voice_participant_info.dart';

class ServerHomeView extends StatelessWidget {
  final ServerModel server;
  final bool isDark;
  final String username;
  final List<ChannelModel> channels;
  final bool isTransmitting;
  final int selectedBannerPreset;
  final ValueChanged<int> onSelectBannerPreset;
  final Color selectedAccentColor;
  final ValueChanged<Color> onSelectAccentColor;
  final bool isCustomizingBanner;
  final VoidCallback onToggleCustomizeBanner;
  final Future<void> Function() onSaveCustomization;
  final List<List<Color>> bannerPresets;
  final List<Color> accentPalette;
  final ValueChanged<ChannelModel> onOpenChannel;
  final Map<String, Map<String, VoiceParticipantInfo>> voiceParticipants;
  final String? clientSessionId;
  final String? connectedVoiceChannelId;
  final ValueChanged<ChannelModel>? onJoinVoice;
  final ValueChanged<VoiceParticipantInfo>? onWatchStream;

  const ServerHomeView({
    super.key,
    required this.server,
    required this.isDark,
    required this.username,
    required this.channels,
    required this.isTransmitting,
    required this.selectedBannerPreset,
    required this.onSelectBannerPreset,
    required this.selectedAccentColor,
    required this.onSelectAccentColor,
    required this.isCustomizingBanner,
    required this.onToggleCustomizeBanner,
    required this.onSaveCustomization,
    this.bannerPresets = AppColors.bannerPresets,
    this.accentPalette = AppColors.serverAccentPalette,
    required this.onOpenChannel,
    this.voiceParticipants = const {},
    this.clientSessionId,
    this.connectedVoiceChannelId,
    this.onJoinVoice,
    this.onWatchStream,
  });

  List<VoiceParticipantInfo> _getChannelVoiceParticipants(String channelId) {
    final map = voiceParticipants[channelId];
    if (map == null) return [];
    return map.values.where((p) => p.isInVoice).toList();
  }

  int get totalMembersInCall {
    return voiceParticipants.values.fold<int>(
      0,
      (sum, m) => sum + m.values.where((p) => p.isInVoice).length,
    );
  }

  List<VoiceParticipantInfo> get allActiveVoiceParticipants {
    final list = <VoiceParticipantInfo>[];
    for (final chMap in voiceParticipants.values) {
      for (final p in chMap.values) {
        if (p.isInVoice) list.add(p);
      }
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final memberCount = server.memberCount < 1 ? 1 : server.memberCount;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      color: isDark ? AppColors.darkCanvas : AppColors.lightCanvas,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 14 : 24,
          isMobile ? 14 : 20,
          isMobile ? 14 : 24,
          isMobile ? (bottomInset > 0 ? bottomInset + 20.0 : 24.0) : 20.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Hero Banner
            _buildServerHeroBanner(context, isMobile: isMobile),

            const SizedBox(height: 16),

            // Active Call Banner (destaque quando há pessoas em chamada)
            if (totalMembersInCall > 0) ...[
              _buildActiveCallBanner(context, isMobile: isMobile),
              const SizedBox(height: 16),
            ],

            // Canais do Servidor (visão direta com participantes em voz)
            _buildChannelsSection(isMobile: isMobile),

            const SizedBox(height: 16),

            // Activity + Media Listening Section
            if (isMobile) ...[
              _buildActivityCard(channels, isMobile: true),
              const SizedBox(height: 16),
              _buildMediaListeningCard(),
              const SizedBox(height: 16),
              _buildCommunitySummaryCard(memberCount),
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildActivityCard(channels, isMobile: false),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 2,
                    child: Column(
                      children: [
                        _buildMediaListeningCard(),
                        const SizedBox(height: 16),
                        _buildCommunitySummaryCard(memberCount),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 20),

            // Announcements and Server Details
            _buildAnnouncementsAndRulesSection(isMobile: isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildServerHeroBanner(BuildContext context, {bool isMobile = false}) {
    final currentGradient = bannerPresets[selectedBannerPreset];
    final memberCount = server.memberCount < 1 ? 1 : server.memberCount;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selectedAccentColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: selectedAccentColor.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: isMobile ? 120 : 140,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                top: const Radius.circular(15),
                bottom: isCustomizingBanner
                    ? Radius.zero
                    : const Radius.circular(15),
              ),
              gradient: LinearGradient(
                colors: currentGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    LucideIcons.gamepad2,
                    size: isMobile ? 90 : 130,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isMobile ? 14 : 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: isMobile ? 46 : 60,
                        height: isMobile ? 46 : 60,
                        decoration: BoxDecoration(
                          color: selectedAccentColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.gamepad2,
                            size: isMobile ? 22 : 30,
                            color: selectedAccentColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server.name,
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${server.category} · $memberCount ${memberCount == 1 ? "membro" : "membros"}',
                              style: GoogleFonts.inter(
                                fontSize: isMobile ? 11 : 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isMobile)
                        IconButton(
                          onPressed: onToggleCustomizeBanner,
                          icon: Icon(
                            isCustomizingBanner
                                ? LucideIcons.x
                                : LucideIcons.slidersHorizontal,
                            size: 16,
                            color: Colors.white,
                          ),
                          tooltip:
                              isCustomizingBanner ? 'Fechar' : 'Personalizar',
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF181926)
                                .withValues(alpha: 0.85),
                            padding: const EdgeInsets.all(8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: onToggleCustomizeBanner,
                          icon: Icon(
                            isCustomizingBanner
                                ? LucideIcons.x
                                : LucideIcons.slidersHorizontal,
                            size: 14,
                          ),
                          label: Text(
                            isCustomizingBanner ? 'Fechar' : 'Personalizar',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF181926)
                                .withValues(alpha: 0.85),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Customization Drawer
          if (isCustomizingBanner)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF141520),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(15),
                ),
                border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.1)),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Text(
                      'Banner',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ...List.generate(bannerPresets.length, (idx) {
                      final preset = bannerPresets[idx];
                      final isSelected = selectedBannerPreset == idx;
                      return InkWell(
                        onTap: () => onSelectBannerPreset(idx),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          width: 30,
                          height: 20,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: LinearGradient(
                              colors: preset,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 14),
                    Text(
                      'Cor',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ...accentPalette.map((color) {
                      final isSelected =
                          selectedAccentColor.toARGB32() == color.toARGB32();
                      return InkWell(
                        onTap: () => onSelectAccentColor(color),
                        mouseCursor: SystemMouseCursors.click,
                        borderRadius: BorderRadius.circular(9999),
                        child: Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 14),
                    ElevatedButton(
                      onPressed: onSaveCustomization,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedAccentColor,
                        foregroundColor:
                            selectedAccentColor.computeLuminance() > 0.5
                                ? Colors.black
                                : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Salvar',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveCallBanner(BuildContext context, {bool isMobile = false}) {
    ChannelModel? callChannel;
    List<VoiceParticipantInfo> activeCallParticipants = [];
    for (final ch in channels) {
      final pList = _getChannelVoiceParticipants(ch.id);
      if (pList.isNotEmpty) {
        callChannel = ch;
        activeCallParticipants = pList;
        break;
      }
    }
    if (callChannel == null && channels.isNotEmpty) {
      callChannel = channels.first;
      activeCallParticipants = _getChannelVoiceParticipants(callChannel.id);
    }
    if (callChannel == null || activeCallParticipants.isEmpty) {
      return const SizedBox.shrink();
    }
    final channel = callChannel;

    final isUserInThisCall = activeCallParticipants.any(
      (p) => clientSessionId != null
          ? p.sessionId == clientSessionId
          : p.username == username,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF132219) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF22C55E).withValues(alpha: isDark ? 0.6 : 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22C55E).withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF22C55E),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CHAMADA DE VOZ AO VIVO',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: const Color(0xFF22C55E),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.volume2,
                        size: 12, color: Color(0xFF22C55E)),
                    const SizedBox(width: 5),
                    Text(
                      '${activeCallParticipants.length} ${activeCallParticipants.length == 1 ? "na sala" : "na sala"}',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: isMobile ? 38 : 44,
                height: isMobile ? 38 : 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.phoneCall,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '# ${channel.name}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sala de voz ativa com áudio em tempo real',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF475569),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  onOpenChannel(channel);
                  if (!isUserInThisCall && onJoinVoice != null) {
                    onJoinVoice!(channel);
                  }
                },
                icon: Icon(
                  isUserInThisCall
                      ? LucideIcons.check
                      : LucideIcons.phoneCall,
                  size: 13,
                ),
                label: Text(
                  isUserInThisCall ? 'Conectado' : 'Entrar na Voz',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 12 : 16,
                    vertical: isMobile ? 8 : 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Participantes conectados com avatar e dispositivo
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: activeCallParticipants.map((p) {
              final isMe = clientSessionId != null
                  ? p.sessionId == clientSessionId
                  : p.username == username;
              final devLabel = p.device == 'mobile'
                  ? ' (Celular)'
                  : p.device == 'desktop'
                      ? ' (Desktop)'
                      : '';
              final displayName =
                  '${p.username}$devLabel${isMe ? " (Você)" : ""}';
              final color = resolveAuthorColor(p.username, isDark);

              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2F24)
                      : const Color(0xFFE2FBE8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: color, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          getAuthorInitials(p.username),
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      displayName,
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (p.isDeafened) ...[
                      const SizedBox(width: 5),
                      Tooltip(
                        message: 'Áudio desativado',
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            LucideIcons.headphones,
                            size: 10.5,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ] else if (p.isMuted) ...[
                      const SizedBox(width: 5),
                      Tooltip(
                        message: 'Microfone mutado',
                        child: Container(
                          padding: const EdgeInsets.all(2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            LucideIcons.micOff,
                            size: 10.5,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                    if (p.isTransmitting) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9333EA).withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'LIVE',
                          style: TextStyle(
                            fontSize: 7.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFC084FC),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsSection({bool isMobile = false}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
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
              Text(
                'Canais do Servidor',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: isMobile ? 14.5 : 16,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: selectedAccentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${channels.length} ${channels.length == 1 ? "canal" : "canais"}',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: selectedAccentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...channels.map((ch) {
            final chParticipants = _getChannelVoiceParticipants(ch.id);
            final hasParticipants = chParticipants.isNotEmpty;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF161724)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasParticipants
                      ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                      : (isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder),
                  width: hasParticipants ? 1.5 : 1,
                ),
              ),
              child: InkWell(
                onTap: () => onOpenChannel(ch),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            hasParticipants
                                ? LucideIcons.volume2
                                : LucideIcons.hash,
                            size: 16,
                            color: hasParticipants
                                ? const Color(0xFF22C55E)
                                : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ch.name,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          if (hasParticipants) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF22C55E)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(LucideIcons.headphones,
                                      size: 11, color: Color(0xFF22C55E)),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${chParticipants.length} em call',
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF22C55E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Icon(
                            LucideIcons.chevronRight,
                            size: 16,
                            color: isDark
                                ? Colors.white38
                                : Colors.black38,
                          ),
                        ],
                      ),
                      if (hasParticipants) ...[
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 24),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: chParticipants.map((p) {
                              final isMe = clientSessionId != null
                                  ? p.sessionId == clientSessionId
                                  : p.username == username;
                              final devLabel = p.device == 'mobile'
                                  ? ' (Celular)'
                                  : p.device == 'desktop'
                                      ? ' (Desktop)'
                                      : '';
                              final pColor =
                                  resolveAuthorColor(p.username, isDark);
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 16,
                                    height: 16,
                                    decoration: BoxDecoration(
                                      color:
                                          pColor.withValues(alpha: 0.3),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        getAuthorInitials(p.username),
                                        style: TextStyle(
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.bold,
                                          color: pColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${p.username}$devLabel${isMe ? " (Você)" : ""}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: const Color(0xFF22C55E),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (p.isDeafened) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Icon(
                                        LucideIcons.headphones,
                                        size: 9.5,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ] else if (p.isMuted) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: const Icon(
                                        LucideIcons.micOff,
                                        size: 9.5,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActivityCard(List<ChannelModel> channels,
      {bool isMobile = false}) {
    final firstChannel = channels.isNotEmpty ? channels.first : null;
    final chParticipants = firstChannel != null
        ? _getChannelVoiceParticipants(firstChannel.id)
        : <VoiceParticipantInfo>[];
    final hasVoice = chParticipants.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
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
                      'Acontecendo no servidor',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: isMobile ? 14.5 : 16,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.darkTextPrimary
                            : AppColors.lightTextPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Novidades recentes da comunidade',
                      style: GoogleFonts.inter(
                        fontSize: isMobile ? 11 : 12,
                        color: isDark
                            ? AppColors.darkTextMuted
                            : AppColors.lightTextMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (channels.isNotEmpty)
                ElevatedButton(
                  onPressed: () => onOpenChannel(channels.first),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedAccentColor,
                    foregroundColor:
                        selectedAccentColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 14,
                      vertical: isMobile ? 6 : 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Abrir',
                    style: TextStyle(
                      fontSize: isMobile ? 11 : 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: LucideIcons.bell,
            title: 'Boas-vindas ao servidor ${server.name}!',
            subtitle: 'Comunidade pronta · Canais híbridos integrados',
            time: 'Hoje',
          ),
          const SizedBox(height: 10),
          _buildActivityItem(
            icon: hasVoice ? LucideIcons.volume2 : LucideIcons.headphones,
            title: hasVoice
                ? 'Canal #${firstChannel?.name ?? "geral"} · ${chParticipants.length} em chamada'
                : 'Canal #${firstChannel?.name ?? "geral"} pronto',
            subtitle: hasVoice
                ? '${chParticipants.map((p) => p.username).join(", ")} conversando na sala'
                : (isTransmitting
                    ? 'Transmissão de tela ativa no canal'
                    : 'Conecte-se para conversar por texto, voz ou transmitir sua tela'),
            time: hasVoice
                ? 'Ao Vivo'
                : (isTransmitting ? 'Ao Vivo' : 'Ativo'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161724) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.darkSurfaceElevated
                  : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: selectedAccentColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
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
          const SizedBox(width: 8),
          Text(
            time,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              color: isDark
                  ? AppColors.darkTextMuted
                  : AppColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaListeningCard() {
    final hasActiveVoice = allActiveVoiceParticipants.isNotEmpty;
    final names = allActiveVoiceParticipants.map((p) => p.username).join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasActiveVoice
            ? (isDark ? const Color(0xFF132A1C) : const Color(0xFFDCFCE7))
            : (isDark ? const Color(0xFF10281C) : const Color(0xFFECFDF5)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasActiveVoice
              ? const Color(0xFF22C55E).withValues(alpha: 0.5)
              : const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasActiveVoice ? LucideIcons.volume2 : LucideIcons.radio,
                size: 14,
                color: hasActiveVoice
                    ? const Color(0xFF22C55E)
                    : const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hasActiveVoice
                      ? 'CHAMADA DE VOZ ATIVA (${allActiveVoiceParticipants.length})'
                      : 'CANAL HÍBRIDO',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: hasActiveVoice
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF10B981),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasActiveVoice
                      ? const Color(0xFF22C55E)
                      : const Color(0xFF10B981),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    hasActiveVoice
                        ? LucideIcons.phoneCall
                        : (isTransmitting
                            ? LucideIcons.screenShare
                            : LucideIcons.headphones),
                    size: 18,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasActiveVoice
                          ? 'Voz em Andamento'
                          : (isTransmitting
                              ? 'Transmissão Ativa'
                              : 'Sala de Áudio e Texto'),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      hasActiveVoice
                          ? '$names em chamada'
                          : (isTransmitting
                              ? 'Transmissão de tela ao vivo'
                              : 'Pronto para conversas e transmissões'),
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitySummaryCard(int memberCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo da comunidade',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
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
                      '$memberCount',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: selectedAccentColor,
                      ),
                    ),
                    Text(
                      memberCount == 1 ? 'membro' : 'membros',
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${channels.length}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    Text(
                      channels.length == 1 ? 'canal' : 'canais',
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
              if (totalMembersInCall > 0)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$totalMembersInCall',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF22C55E),
                        ),
                      ),
                      Text(
                        'em chamada',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF22C55E),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsAndRulesSection({bool isMobile = false}) {
    final rulesWidget = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.shieldCheck,
                size: 14,
                color: selectedAccentColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Diretrizes da Comunidade',
                  style: GoogleFonts.inter(
                    fontSize: 13,
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
          const SizedBox(height: 8),
          Text(
            'Respeite os membros, mantenha as discussões produtivas e utilize os canais apropriados para código, jogos e bate-papo.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );

    final hybridInfoWidget = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                LucideIcons.sparkles,
                size: 14,
                color: selectedAccentColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Canais Híbridos',
                  style: GoogleFonts.inter(
                    fontSize: 13,
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
          const SizedBox(height: 8),
          Text(
            'Cada canal combina chat de texto, chamada de áudio e transmissão de tela no mesmo ambiente integrado.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informações do servidor',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (isMobile) ...[
          rulesWidget,
          const SizedBox(height: 12),
          hybridInfoWidget,
        ] else ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: rulesWidget),
              const SizedBox(width: 14),
              Expanded(child: hybridInfoWidget),
            ],
          ),
        ],
      ],
    );
  }
}
