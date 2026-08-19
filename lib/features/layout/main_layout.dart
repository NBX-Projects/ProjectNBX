import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../servers/providers/server_provider.dart';
import '../servers/models/server_model.dart';
import 'widgets/server_sidebar.dart';
import 'widgets/channel_sidebar.dart';
import '../chat/widgets/chat_view.dart';
import '../voice/widgets/voice_room_view.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);
    final selectedChannel = serverState.selectedChannel;

    return Scaffold(
      backgroundColor: AppColors.bgChat,
      body: Row(
        children: [
          // 1. Leftmost Server Rail (72px)
          const ServerSidebar(),

          // 2. Channel Sidebar (240px)
          const ChannelSidebar(),

          // 3. Main Dynamic Area (Chat or Voice)
          Expanded(
            child: selectedChannel.type == ChannelType.voice
                ? const VoiceRoomView()
                : const ChatView(),
          ),
        ],
      ),
    );
  }
}
