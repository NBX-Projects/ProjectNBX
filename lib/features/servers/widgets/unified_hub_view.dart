import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/server_model.dart';
import '../providers/server_provider.dart';
import '../../voice/providers/voice_provider.dart';
import '../../voice/models/voice_state.dart';

class UnifiedHubView extends ConsumerStatefulWidget {
  const UnifiedHubView({super.key});

  @override
  ConsumerState<UnifiedHubView> createState() => _UnifiedHubViewState();
}

class _UnifiedHubViewState extends ConsumerState<UnifiedHubView> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showCodeSnippetInput = false;
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    _codeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text;
    final code = _showCodeSnippetInput ? _codeController.text : null;
    if (text.trim().isEmpty && (code == null || code.trim().isEmpty)) return;

    ref.read(serverProvider.notifier).sendMessage(
          text,
          codeSnippet: code,
          codeLang: 'dart',
        );

    _messageController.clear();
    _codeController.clear();
    setState(() => _showCodeSnippetInput = false);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final serverNotifier = ref.read(serverProvider.notifier);
    final voiceState = ref.watch(voiceProvider);
    final voiceNotifier = ref.read(voiceProvider.notifier);

    final selectedServer = serverState.selectedServer;
    final selectedChannel = serverState.selectedChannel;
    final messages = serverState.channelMessages[selectedChannel.id] ?? [];

    return Scaffold(
      backgroundColor: AppColors.bgOnyx,
      body: Row(
        children: [
          // 1. Left Compact Topic Sidebar
          _CompactTopicSidebar(
            server: selectedServer,
            selectedChannel: selectedChannel,
            voiceState: voiceState,
            onSelectChannel: (channel) {
              serverNotifier.selectChannel(channel);
            },
            onBackToDashboard: () {
              serverNotifier.navigateTo(ViewMode.homeDashboard);
            },
          ),

          // 2. Main Center Stage (Unified Voice & Text Feed + PiP)
          Expanded(
            child: Stack(
              children: [
                Column(
                  children: [
                    // Top Horizontal Audio-Presence Bar (In-Call Mode)
                    _TopAudioPresenceBar(
                      selectedChannel: selectedChannel,
                      voiceState: voiceState,
                      onJoinVoice: () {
                        voiceNotifier.joinVoiceChannel(
                          selectedChannel.id,
                          '🔊 ${selectedChannel.name}',
                          serverName: selectedServer.name,
                        );
                      },
                      onLeaveVoice: () => voiceNotifier.leaveVoiceChannel(),
                      onToggleMute: () => voiceNotifier.toggleMute(),
                      onToggleDeafen: () => voiceNotifier.toggleDeafen(),
                    ),

                    // Main Unified Stage Area: Chat stream + Pinned PiP (if pinned)
                    Expanded(
                      child: Row(
                        children: [
                          // Full-Height Continuous Chat Stream
                          Expanded(
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(24, 16, 24, 110), // bottom space for floating dock
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                return _UnifiedChatMessageTile(
                                  message: msg,
                                  onReaction: (emoji) {
                                    serverNotifier.addReaction(selectedChannel.id, msg.id, emoji);
                                  },
                                );
                              },
                            ),
                          ),

                          // Pinned PiP Media View (Docked on the right side so text is never obscured)
                          if (serverState.isScreenSharePiPVisible &&
                              serverState.isScreenSharePiPPinned &&
                              (voiceState.isScreenSharing || selectedChannel.hasActiveScreenShare))
                            _PinnedScreenShareContainer(
                              isExpanded: serverState.isScreenSharePiPExpanded,
                              onTogglePinned: () => serverNotifier.toggleScreenSharePiPPinned(),
                              onToggleExpanded: () => serverNotifier.toggleScreenSharePiPExpanded(),
                              onClose: () => serverNotifier.toggleScreenSharePiPVisible(),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Floating PiP Media View (When unpinned, floats gracefully without hiding message focus)
                if (serverState.isScreenSharePiPVisible &&
                    !serverState.isScreenSharePiPPinned &&
                    (voiceState.isScreenSharing || selectedChannel.hasActiveScreenShare))
                  Positioned(
                    top: 60,
                    right: 24,
                    child: _FloatingScreenShareContainer(
                      isExpanded: serverState.isScreenSharePiPExpanded,
                      onTogglePinned: () => serverNotifier.toggleScreenSharePiPPinned(),
                      onToggleExpanded: () => serverNotifier.toggleScreenSharePiPExpanded(),
                      onClose: () => serverNotifier.toggleScreenSharePiPVisible(),
                    ),
                  ),

                // Bottom Floating Frosted-Glass Control Dock
                Positioned(
                  left: 24,
                  right: 24,
                  bottom: 20,
                  child: _FloatingFrostedControlDock(
                    selectedChannel: selectedChannel,
                    voiceState: voiceState,
                    showCodeInput: _showCodeSnippetInput,
                    messageController: _messageController,
                    codeController: _codeController,
                    onToggleCode: () => setState(() => _showCodeSnippetInput = !_showCodeSnippetInput),
                    onSendMessage: _sendMessage,
                    onToggleMute: () => voiceNotifier.toggleMute(),
                    onToggleDeafen: () => voiceNotifier.toggleDeafen(),
                    onToggleScreenShare: () => voiceNotifier.toggleScreenShare(),
                    onToggleCamera: () => voiceNotifier.toggleCamera(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// COMPONENT 1: LEFT COMPACT TOPIC SIDEBAR (Categorized by Tags)
// -------------------------------------------------------------
class _CompactTopicSidebar extends StatelessWidget {
  final Server server;
  final Channel selectedChannel;
  final VoiceRoomState voiceState;
  final ValueChanged<Channel> onSelectChannel;
  final VoidCallback onBackToDashboard;

  const _CompactTopicSidebar({
    required this.server,
    required this.selectedChannel,
    required this.voiceState,
    required this.onSelectChannel,
    required this.onBackToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    // Group channels by tag
    final Map<String, List<Channel>> groupedChannels = {};
    for (final ch in server.channels) {
      groupedChannels.putIfAbsent(ch.tag, () => []).add(ch);
    }

    return Container(
      width: 260,
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(right: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      child: Column(
        children: [
          // Hub Header & Back Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: onBackToDashboard,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: const Icon(LucideIcons.arrowLeft, size: 16, color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        server.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.neonEmerald,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${server.onlineCount} online',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Categorized Topic List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              children: groupedChannels.entries.map((entry) {
                final tag = entry.key;
                final channels = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            tag,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...channels.map((channel) {
                      final isSelected = selectedChannel.id == channel.id;
                      final isVoiceLiveHere = (voiceState.isConnected && voiceState.roomId == channel.id) ||
                          channel.activeVoiceCount > 0;

                      return _TopicItemTile(
                        channel: channel,
                        isSelected: isSelected,
                        isVoiceLive: isVoiceLiveHere,
                        onTap: () => onSelectChannel(channel),
                      );
                    }),
                    const SizedBox(height: 10),
                  ],
                );
              }).toList(),
            ),
          ),

          // Bottom Hub Quick Info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: AppColors.bgInput,
              border: Border(top: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.shieldCheck, size: 14, color: AppColors.neonCyan),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'E2E Encrypted Audio/Data',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('SFU', style: TextStyle(color: AppColors.neonCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopicItemTile extends StatelessWidget {
  final Channel channel;
  final bool isSelected;
  final bool isVoiceLive;
  final VoidCallback onTap;

  const _TopicItemTile({
    required this.channel,
    required this.isSelected,
    required this.isVoiceLive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    IconData iconData = LucideIcons.hash;
    if (channel.hasActiveScreenShare) {
      iconData = LucideIcons.screenShare;
    } else if (isVoiceLive) {
      iconData = LucideIcons.audioWaveform;
    } else if (channel.tag == 'DEVELOPMENT') {
      iconData = LucideIcons.code;
    } else if (channel.tag == 'MEDIA') {
      iconData = LucideIcons.tv;
    } else if (channel.tag == 'GAMING') {
      iconData = LucideIcons.gamepad2;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.bgCardHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.neonCyan.withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                iconData,
                size: 15,
                color: isSelected
                    ? AppColors.neonCyan
                    : (isVoiceLive ? AppColors.neonEmerald : AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  channel.name,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isVoiceLive) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neonEmerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: const BoxDecoration(
                          color: AppColors.neonEmerald,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${channel.activeVoiceCount > 0 ? channel.activeVoiceCount : 1}',
                        style: const TextStyle(color: AppColors.neonEmerald, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
              if (channel.unreadCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.neonCoral,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${channel.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// COMPONENT 2: TOP HORIZONTAL AUDIO-PRESENCE BAR (In-Call Mode)
// -------------------------------------------------------------------
class _TopAudioPresenceBar extends StatelessWidget {
  final Channel selectedChannel;
  final VoiceRoomState voiceState;
  final VoidCallback onJoinVoice;
  final VoidCallback onLeaveVoice;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleDeafen;

  const _TopAudioPresenceBar({
    required this.selectedChannel,
    required this.voiceState,
    required this.onJoinVoice,
    required this.onLeaveVoice,
    required this.onToggleMute,
    required this.onToggleDeafen,
  });

  @override
  Widget build(BuildContext context) {
    final bool inCall = voiceState.isConnected;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
      ),
      child: Row(
        children: [
          // Topic Name
          Row(
            children: [
              const Icon(LucideIcons.terminal, size: 16, color: AppColors.neonCyan),
              const SizedBox(width: 8),
              Text(
                '#${selectedChannel.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              Container(width: 1, height: 16, color: AppColors.borderSubtle),
              const SizedBox(width: 12),
            ],
          ),

          // Horizontal Presence Bar with Pulsing Waveform Avatars
          if (inCall)
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...voiceState.participants.map((p) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _AudioPresencePill(participant: p),
                      );
                    }),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Text(
                selectedChannel.description.isNotEmpty
                    ? selectedChannel.description
                    : 'Unified chat and real-time audio presence channel',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // In-Call Telemetry & Action Buttons
          if (inCall) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.radio, size: 12, color: AppColors.neonEmerald),
                  const SizedBox(width: 6),
                  Text(
                    '${voiceState.pingMs}ms • 48kHz',
                    style: const TextStyle(color: AppColors.neonEmerald, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              icon: Icon(
                voiceState.isMuted ? LucideIcons.micOff : LucideIcons.mic,
                color: voiceState.isMuted ? AppColors.neonCoral : AppColors.neonCyan,
                size: 16,
              ),
              tooltip: voiceState.isMuted ? 'Unmute' : 'Mute',
              onPressed: onToggleMute,
            ),
            IconButton(
              icon: const Icon(LucideIcons.phoneOff, color: AppColors.neonCoral, size: 16),
              tooltip: 'Leave Audio Mesh',
              onPressed: onLeaveVoice,
            ),
          ] else
            ElevatedButton.icon(
              onPressed: onJoinVoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonCyan.withValues(alpha: 0.15),
                foregroundColor: AppColors.neonCyan,
                side: const BorderSide(color: AppColors.neonCyan),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              icon: const Icon(LucideIcons.headphones, size: 14),
              label: const Text(
                'JOIN TOPIC AUDIO',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _AudioPresencePill extends StatelessWidget {
  final VoiceParticipant participant;
  const _AudioPresencePill({required this.participant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: participant.isSpeaking ? AppColors.neonEmerald : AppColors.borderSubtle,
          width: participant.isSpeaking ? 1.5 : 1,
        ),
        boxShadow: participant.isSpeaking
            ? [
                const BoxShadow(color: AppColors.emeraldGlow, blurRadius: 8),
              ]
            : [],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              gradient: AppColors.cyanVioletGradient,
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Text(
              participant.tag,
              style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            participant.name,
            style: TextStyle(
              color: participant.isSpeaking ? Colors.white : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),

          // Subtle Waveform Bars for Active Speaking
          if (participant.isSpeaking && !participant.isMuted)
            _MicroWaveform(level: participant.audioLevel)
          else if (participant.isMuted)
            const Icon(LucideIcons.micOff, size: 10, color: AppColors.neonCoral)
          else
            Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppColors.textMuted,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}

class _MicroWaveform extends StatelessWidget {
  final double level;
  const _MicroWaveform({required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 10,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(4, (index) {
          final barHeight = 3.0 + (level * 7.0) * ((index % 2 == 0) ? 1.0 : 0.6);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1),
            width: 2,
            height: barHeight,
            decoration: BoxDecoration(
              color: AppColors.neonEmerald,
              borderRadius: BorderRadius.circular(1),
            ),
          );
        }),
      ),
    );
  }
}

// -------------------------------------------------------------------
// COMPONENT 3: PINNED & FLOATING SCREEN SHARE PiP CONTAINERS
// -------------------------------------------------------------------
class _PinnedScreenShareContainer extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTogglePinned;
  final VoidCallback onToggleExpanded;
  final VoidCallback onClose;

  const _PinnedScreenShareContainer({
    required this.isExpanded,
    required this.onTogglePinned,
    required this.onToggleExpanded,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final width = isExpanded ? 460.0 : 340.0;

    return Container(
      width: width,
      margin: const EdgeInsets.fromLTRB(0, 16, 20, 110),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonViolet.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.violetGlow.withValues(alpha: 0.2),
            blurRadius: 16,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _ScreenShareViewport(
          isPinned: true,
          isExpanded: isExpanded,
          onTogglePinned: onTogglePinned,
          onToggleExpanded: onToggleExpanded,
          onClose: onClose,
        ),
      ),
    );
  }
}

class _FloatingScreenShareContainer extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTogglePinned;
  final VoidCallback onToggleExpanded;
  final VoidCallback onClose;

  const _FloatingScreenShareContainer({
    required this.isExpanded,
    required this.onTogglePinned,
    required this.onToggleExpanded,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final width = isExpanded ? 480.0 : 360.0;
    final height = isExpanded ? 300.0 : 225.0;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neonViolet, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.violetGlow.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _ScreenShareViewport(
          isPinned: false,
          isExpanded: isExpanded,
          onTogglePinned: onTogglePinned,
          onToggleExpanded: onToggleExpanded,
          onClose: onClose,
        ),
      ),
    );
  }
}

class _ScreenShareViewport extends StatelessWidget {
  final bool isPinned;
  final bool isExpanded;
  final VoidCallback onTogglePinned;
  final VoidCallback onToggleExpanded;
  final VoidCallback onClose;

  const _ScreenShareViewport({
    required this.isPinned,
    required this.isExpanded,
    required this.onTogglePinned,
    required this.onToggleExpanded,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // High-Tech Cyber Screen Feed Simulation
        Container(
          color: const Color(0xFF0A0E17),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neonViolet.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonViolet.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(LucideIcons.screenShare, color: AppColors.neonViolet, size: 28),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Lucas Dev's Screen",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Visual Studio Code • livekit_sfu.rs",
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ),

        // CRT Subtle Grid Overlay Line
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.neonCyan.withValues(alpha: 0.03),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Top Control Bar Overlay
        Positioned(
          top: 8,
          left: 10,
          right: 10,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.radio, size: 10, color: AppColors.neonEmerald),
                    SizedBox(width: 4),
                    Text(
                      '1080p 60FPS',
                      style: TextStyle(color: AppColors.neonEmerald, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Spacer(),

              // Action Buttons (Pin / Expand / Close)
              _PiPHeaderButton(
                icon: isPinned ? LucideIcons.pinOff : LucideIcons.pin,
                tooltip: isPinned ? 'Unpin to Float' : 'Pin to Sidebar',
                onTap: onTogglePinned,
              ),
              const SizedBox(width: 4),
              _PiPHeaderButton(
                icon: isExpanded ? LucideIcons.minimize2 : LucideIcons.maximize2,
                tooltip: isExpanded ? 'Compact View' : 'Expand View',
                onTap: onToggleExpanded,
              ),
              const SizedBox(width: 4),
              _PiPHeaderButton(
                icon: LucideIcons.x,
                tooltip: 'Hide Screen Share',
                onTap: onClose,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PiPHeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _PiPHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon, color: Colors.white, size: 13),
        ),
      ),
    );
  }
}

// -------------------------------------------------------------------
// COMPONENT 4: UNIFIED CHAT MESSAGE TILE (Rich Markdown & Reactions)
// -------------------------------------------------------------------
class _UnifiedChatMessageTile extends StatelessWidget {
  final ChatMessage message;
  final ValueChanged<String> onReaction;

  const _UnifiedChatMessageTile({
    required this.message,
    required this.onReaction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Avatar
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: message.isCurrentUser ? AppColors.cyanVioletGradient : null,
              color: message.isCurrentUser ? null : AppColors.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: message.isCurrentUser ? AppColors.neonCyan.withValues(alpha: 0.5) : AppColors.borderSubtle,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              message.authorAvatar,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),

          // Message Card
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: message.isCurrentUser ? AppColors.neonCyan.withValues(alpha: 0.25) : AppColors.borderSubtle,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author Info Row
                  Row(
                    children: [
                      Text(
                        message.authorName,
                        style: TextStyle(
                          color: message.isCurrentUser ? AppColors.neonCyan : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.bgOnyx,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: Text(
                          message.authorRole,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Message Text
                  Text(
                    message.content,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  // Code Snippet Block (if present)
                  if (message.codeSnippet != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.borderGlow),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(color: AppColors.neonCyan, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                (message.codeLang ?? 'code').toUpperCase(),
                                style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            message.codeSnippet!,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              color: AppColors.textPrimary,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Reactions Row
                  if (message.reactions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      children: message.reactions.entries.map((entry) {
                        return InkWell(
                          onTap: () => onReaction(entry.key),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.bgInput,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(entry.key, style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 4),
                                Text(
                                  '${entry.value}',
                                  style: const TextStyle(color: AppColors.neonCyan, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------------
// COMPONENT 5: BOTTOM FLOATING FROSTED-GLASS CONTROL DOCK
// -------------------------------------------------------------------
class _FloatingFrostedControlDock extends StatelessWidget {
  final Channel selectedChannel;
  final VoiceRoomState voiceState;
  final bool showCodeInput;
  final TextEditingController messageController;
  final TextEditingController codeController;
  final VoidCallback onToggleCode;
  final VoidCallback onSendMessage;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleDeafen;
  final VoidCallback onToggleScreenShare;
  final VoidCallback onToggleCamera;

  const _FloatingFrostedControlDock({
    required this.selectedChannel,
    required this.voiceState,
    required this.showCodeInput,
    required this.messageController,
    required this.codeController,
    required this.onToggleCode,
    required this.onSendMessage,
    required this.onToggleMute,
    required this.onToggleDeafen,
    required this.onToggleScreenShare,
    required this.onToggleCamera,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgGlassFloating,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderGlow.withValues(alpha: 0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Expandable Code Snippet Input Area
              if (showCodeInput)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.neonViolet.withValues(alpha: 0.4)),
                  ),
                  child: TextField(
                    controller: codeController,
                    maxLines: 4,
                    style: const TextStyle(
                      fontFamily: 'Courier',
                      color: AppColors.neonCyan,
                      fontSize: 12,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Paste code snippet here...',
                      hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),

              // Main Dock Bar Row: Voice Controls + Text Input + Send
              Row(
                children: [
                  // Voice Controls Group
                  _DockIconButton(
                    icon: voiceState.isMuted ? LucideIcons.micOff : LucideIcons.mic,
                    color: voiceState.isMuted ? AppColors.neonCoral : AppColors.neonCyan,
                    activeGlow: voiceState.isMuted ? AppColors.coralGlow : AppColors.cyanGlow,
                    tooltip: voiceState.isMuted ? 'Unmute [ALT+V]' : 'Mute [ALT+V]',
                    onTap: onToggleMute,
                  ),
                  const SizedBox(width: 6),
                  _DockIconButton(
                    icon: voiceState.isDeafened ? LucideIcons.volumeX : LucideIcons.volume2,
                    color: voiceState.isDeafened ? AppColors.neonCoral : AppColors.textSecondary,
                    activeGlow: AppColors.coralGlow,
                    tooltip: voiceState.isDeafened ? 'Undeafen' : 'Deafen',
                    onTap: onToggleDeafen,
                  ),
                  const SizedBox(width: 6),
                  _DockIconButton(
                    icon: LucideIcons.screenShare,
                    color: voiceState.isScreenSharing ? AppColors.neonViolet : AppColors.textSecondary,
                    activeGlow: AppColors.violetGlow,
                    tooltip: voiceState.isScreenSharing ? 'Stop Screen Share' : 'Share Screen (60fps)',
                    onTap: onToggleScreenShare,
                  ),
                  const SizedBox(width: 6),
                  _DockIconButton(
                    icon: voiceState.isCameraOn ? LucideIcons.video : LucideIcons.videoOff,
                    color: voiceState.isCameraOn ? AppColors.neonEmerald : AppColors.textSecondary,
                    activeGlow: AppColors.emeraldGlow,
                    tooltip: voiceState.isCameraOn ? 'Turn Camera Off' : 'Turn Camera On',
                    onTap: onToggleCamera,
                  ),

                  const SizedBox(width: 10),
                  Container(width: 1, height: 26, color: AppColors.borderSubtle),
                  const SizedBox(width: 10),

                  // Code Snippet Trigger
                  _DockIconButton(
                    icon: LucideIcons.code2,
                    color: showCodeInput ? AppColors.neonViolet : AppColors.textSecondary,
                    activeGlow: AppColors.violetGlow,
                    tooltip: 'Insert Code Block',
                    onTap: onToggleCode,
                  ),
                  const SizedBox(width: 6),

                  // Integrated Text Input Box
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.bgInput,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: TextField(
                        controller: messageController,
                        onSubmitted: (_) => onSendMessage(),
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Transmit in #${selectedChannel.name}...',
                          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Send Button
                  InkWell(
                    onTap: onSendMessage,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: AppColors.cyanVioletGradient,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(color: AppColors.cyanGlow, blurRadius: 10),
                        ],
                      ),
                      child: const Icon(LucideIcons.send, color: Colors.black, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DockIconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color activeGlow;
  final String tooltip;
  final VoidCallback onTap;

  const _DockIconButton({
    required this.icon,
    required this.color,
    required this.activeGlow,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}
