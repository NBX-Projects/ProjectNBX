import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../servers/widgets/hub_screen.dart';
import '../servers/widgets/server_view.dart';
import '../voice/providers/voice_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  String _currentView = "hub"; // "hub" or "server"
  String _currentServerId = "1";
  Map<String, dynamic>? _activeCall;

  void _goToServer(String serverId) {
    setState(() {
      _currentView = "server";
      _currentServerId = serverId;
    });
  }

  void _switchServer(String serverId) {
    setState(() {
      _currentServerId = serverId;
    });
  }

  void _goToHub() {
    setState(() {
      _currentView = "hub";
    });
  }

  void _handleCallChange(Map<String, dynamic>? call) {
    setState(() {
      _activeCall = call;
    });
    if (call != null) {
      ref.read(voiceProvider.notifier).joinVoiceChannel(
            call['channelName'] ?? 'chn_voice_general',
            call['channelName'] ?? 'Sala de Voz',
            serverName: call['serverName'] ?? 'ProjectNBX',
          );
    } else {
      ref.read(voiceProvider.notifier).leaveVoiceChannel();
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceState = ref.watch(voiceProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _currentView == "hub"
            ? HubScreen(
                key: const ValueKey('HubScreen'),
                onEnterServer: _goToServer,
                activeCall: _activeCall,
                isMuted: voiceState.isMuted,
                isDeafened: voiceState.isDeafened,
                onToggleMute: () => ref.read(voiceProvider.notifier).toggleMute(),
                onToggleDeafen: () => ref.read(voiceProvider.notifier).toggleDeafen(),
                onDisconnectCall: () => _handleCallChange(null),
              )
            : ServerView(
                key: ValueKey('ServerView_$_currentServerId'),
                serverId: _currentServerId,
                onBack: _goToHub,
                onSwitchServer: _switchServer,
                onCallChange: _handleCallChange,
                isMuted: voiceState.isMuted,
                isDeafened: voiceState.isDeafened,
                onToggleMute: () => ref.read(voiceProvider.notifier).toggleMute(),
                onToggleDeafen: () => ref.read(voiceProvider.notifier).toggleDeafen(),
                onDisconnectCall: () => _handleCallChange(null),
              ),
      ),
    );
  }
}
