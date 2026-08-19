import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../servers/providers/server_provider.dart';
import '../../voice/providers/voice_provider.dart';

class CommandPaletteModal extends ConsumerStatefulWidget {
  const CommandPaletteModal({super.key});

  @override
  ConsumerState<CommandPaletteModal> createState() => _CommandPaletteModalState();
}

class _CommandPaletteModalState extends ConsumerState<CommandPaletteModal> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final serverNotifier = ref.read(serverProvider.notifier);
    final voiceState = ref.watch(voiceProvider);
    final voiceNotifier = ref.read(voiceProvider.notifier);

    final filteredServers = serverState.servers.where((s) {
      return s.name.toLowerCase().contains(_query.toLowerCase()) ||
          s.tags.any((t) => t.toLowerCase().contains(_query.toLowerCase()));
    }).toList();

    return Material(
      color: Colors.black.withValues(alpha: 0.75),
      child: Stack(
        children: [
          // Dismiss on backdrop tap
          Positioned.fill(
            child: GestureDetector(
              onTap: () => serverNotifier.toggleCommandPalette(false),
              child: Container(color: Colors.transparent),
            ),
          ),

          // Central Command Palette Box
          Center(
            child: Container(
              width: 640,
              margin: const EdgeInsets.symmetric(horizontal: 24),
              constraints: const BoxConstraints(maxHeight: 520),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.cyanGlow.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.8),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search, color: AppColors.neonCyan, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            onChanged: (val) => setState(() => _query = val),
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Type a command, hub name, or tag...',
                              hintStyle: TextStyle(color: AppColors.textMuted, fontSize: 15),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.borderSubtle),
                          ),
                          child: const Text(
                            'ESC to close',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Results List
                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shrinkWrap: true,
                      children: [
                        // Quick Actions Section
                        if (_query.isEmpty || 'quick actions commands mute deafen'.contains(_query.toLowerCase())) ...[
                          const _SectionHeader(title: 'QUICK SYSTEM ACTIONS'),
                          _CommandPaletteItem(
                            icon: LucideIcons.layoutGrid,
                            title: 'Go to Home Dashboard',
                            subtitle: 'Explore active Bento hubs and telemetry',
                            badge: 'Home',
                            accentColor: AppColors.neonCyan,
                            onTap: () {
                              serverNotifier.navigateTo(ViewMode.homeDashboard);
                              serverNotifier.toggleCommandPalette(false);
                            },
                          ),
                          _CommandPaletteItem(
                            icon: voiceState.isMuted ? LucideIcons.mic : LucideIcons.micOff,
                            title: voiceState.isMuted ? 'Unmute Microphone' : 'Mute Microphone',
                            subtitle: 'Toggle global microphone state [ALT+V]',
                            badge: 'Voice',
                            accentColor: voiceState.isMuted ? AppColors.neonEmerald : AppColors.neonCoral,
                            onTap: () {
                              voiceNotifier.toggleMute();
                              serverNotifier.toggleCommandPalette(false);
                            },
                          ),
                          _CommandPaletteItem(
                            icon: LucideIcons.screenShare,
                            title: voiceState.isScreenSharing ? 'Stop Screen Sharing' : 'Start Screen Share 60FPS',
                            subtitle: 'Ultra low latency stream with WebRTC SFU',
                            badge: 'Video',
                            accentColor: AppColors.neonViolet,
                            onTap: () {
                              voiceNotifier.toggleScreenShare();
                              serverNotifier.toggleCommandPalette(false);
                            },
                          ),
                        ],

                        // Hubs Section
                        const _SectionHeader(title: 'COMMUNITY HUBS'),
                        if (filteredServers.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(
                              child: Text(
                                'No matching hubs found.',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ),
                          )
                        else
                          ...filteredServers.map((server) {
                            return _CommandPaletteItem(
                              icon: LucideIcons.server,
                              title: server.name,
                              subtitle: '${server.onlineCount} online • ${server.description}',
                              badge: server.category,
                              accentColor: server.accentColor,
                              onTap: () {
                                serverNotifier.selectServer(server);
                                serverNotifier.toggleCommandPalette(false);
                              },
                            );
                          }),
                      ],
                    ),
                  ),

                  // Bottom Keyboard hint
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: const BoxDecoration(
                      color: AppColors.bgInput,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      border: Border(top: BorderSide(color: AppColors.borderSubtle)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Navigation: Click or Enter to execute',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                        Text(
                          'ProjectNBX Fast Indexer v1.0',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                      ],
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
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _CommandPaletteItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color accentColor;
  final VoidCallback onTap;

  const _CommandPaletteItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, size: 16, color: accentColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
