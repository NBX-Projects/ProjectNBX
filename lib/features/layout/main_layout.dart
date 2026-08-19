import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../servers/providers/server_provider.dart';
import '../servers/models/server_model.dart';
import 'widgets/top_command_bar.dart';
import 'widgets/squad_dock.dart';
import '../chat/widgets/cyber_chat_view.dart';
import '../voice/widgets/squad_voice_hud.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);
    final selectedChannel = serverState.selectedChannel;

    return Scaffold(
      backgroundColor: AppColors.bgOnyx,
      body: Column(
        children: [
          // 1. Top Cyber Command Bar
          const TopCommandBar(),

          // 2. Main Workspace Body
          Expanded(
            child: Row(
              children: [
                // Left Navigation & Channel Dock
                const SquadDock(),

                // Central Workspace Deck (Holographic Voice HUD or Cyber Chat)
                Expanded(
                  child: selectedChannel.type == ChannelType.voice
                      ? const SquadVoiceHUD()
                      : const CyberChatView(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
