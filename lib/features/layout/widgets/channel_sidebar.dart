import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../servers/providers/server_provider.dart';
import '../../servers/models/server_model.dart';
import '../../voice/providers/voice_provider.dart';
import '../../user/widgets/user_profile_bar.dart';

class ChannelSidebar extends ConsumerWidget {
  const ChannelSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);
    final voiceState = ref.watch(voiceProvider);
    final selectedServer = serverState.selectedServer;
    final selectedChannel = serverState.selectedChannel;

    final textChannels = selectedServer.channels
        .where((c) => c.type == ChannelType.text)
        .toList();
    final voiceChannels = selectedServer.channels
        .where((c) => c.type == ChannelType.voice)
        .toList();

    return Container(
      width: 240,
      color: AppColors.bgChannelSidebar,
      child: Column(
        children: [
          // Server Header
          InkWell(
            onTap: () {},
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      selectedServer.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    LucideIcons.chevronDown,
                    color: AppColors.textInteractive,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),

          // Channels List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: [
                // Text Channels Category
                _CategoryHeader(title: 'CANAIS DE TEXTO'),
                ...textChannels.map((channel) {
                  final isSelected = selectedChannel.id == channel.id;
                  return _ChannelTile(
                    channel: channel,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(serverProvider.notifier).selectChannel(channel);
                    },
                  );
                }),

                const SizedBox(height: 16),

                // Voice Channels Category
                _CategoryHeader(title: 'CANAIS DE VOZ'),
                ...voiceChannels.map((channel) {
                  final isConnectedToThis =
                      voiceState.isConnected && voiceState.roomId == channel.id;
                  return Column(
                    children: [
                      _ChannelTile(
                        channel: channel,
                        isSelected: isConnectedToThis,
                        isVoice: true,
                        onTap: () {
                          ref
                              .read(voiceProvider.notifier)
                              .joinVoiceChannel(channel.id, channel.name);
                        },
                      ),
                      // If connected or has active members, show participants indented
                      if (isConnectedToThis)
                        Padding(
                          padding: const EdgeInsets.only(left: 28, top: 4, bottom: 6),
                          child: Column(
                            children: voiceState.participants.map((p) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        border: p.isSpeaking
                                            ? Border.all(
                                                color: AppColors.speakingGreen,
                                                width: 2,
                                              )
                                            : null,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        p.avatar,
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        p.name,
                                        style: TextStyle(
                                          color: p.isSpeaking
                                              ? AppColors.speakingGreen
                                              : AppColors.textSecondary,
                                          fontSize: 13,
                                          fontWeight: p.isSpeaking
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (p.isMuted)
                                      const Icon(
                                        LucideIcons.micOff,
                                        size: 14,
                                        color: AppColors.dangerRed,
                                      ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),

          // Active Voice Status Banner (If Connected)
          if (voiceState.isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2024),
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.radio,
                    color: AppColors.speakingGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voz Conectada',
                          style: TextStyle(
                            color: AppColors.speakingGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${voiceState.roomName ?? "Voz"} / ${voiceState.pingMs}ms',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.phoneOff, size: 16),
                    color: AppColors.dangerRed,
                    tooltip: 'Desconectar da Call',
                    onPressed: () {
                      ref.read(voiceProvider.notifier).leaveVoiceChannel();
                    },
                  ),
                ],
              ),
            ),

          // User Profile Bar at bottom
          const UserProfileBar(),
        ],
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  const _CategoryHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 12, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final bool isSelected;
  final bool isVoice;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    required this.isSelected,
    this.isVoice = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.bgActive : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
        leading: Icon(
          isVoice ? LucideIcons.volume2 : LucideIcons.hash,
          size: 18,
          color: isSelected ? Colors.white : AppColors.textSecondary,
        ),
        title: Text(
          channel.name,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }
}
