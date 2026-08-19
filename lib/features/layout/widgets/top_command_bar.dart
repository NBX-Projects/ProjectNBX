import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../servers/providers/server_provider.dart';
import '../../voice/providers/voice_provider.dart';

class TopCommandBar extends ConsumerWidget {
  const TopCommandBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);
    final voiceState = ref.watch(voiceProvider);
    final voiceNotifier = ref.read(voiceProvider.notifier);

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Brand Logo & Title
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.cyanGlow,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset('assets/logo.png', fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'PROJECT',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontSize: 14,
                ),
              ),
              const Text(
                'NBX',
                style: TextStyle(
                  color: AppColors.neonCyan,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const SizedBox(width: 24),
          Container(width: 1, height: 24, color: AppColors.borderSubtle),
          const SizedBox(width: 20),

          // Workspaces Tabs / Hub Pills
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: serverState.servers.map((server) {
                  final isSelected = serverState.selectedServer.id == server.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () => ref.read(serverProvider.notifier).selectServer(server),
                      borderRadius: BorderRadius.circular(20),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.bgCard : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.neonCyan.withValues(alpha: 0.5) : Colors.transparent,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.cyanGlow.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.neonCyan : AppColors.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              server.name,
                              style: TextStyle(
                                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Live Telemetry Capsule
          if (voiceState.isConnected)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.radio, size: 14, color: AppColors.neonEmerald),
                  const SizedBox(width: 6),
                  Text(
                    '${voiceState.pingMs}ms • ${voiceState.codec}',
                    style: const TextStyle(
                      color: AppColors.neonEmerald,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          // Push-to-Talk HUD Indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.borderGlow),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.keyboard, size: 14, color: AppColors.neonViolet),
                SizedBox(width: 6),
                Text(
                  'PTT: ALT+V',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // User Mic & Status Controls
          Row(
            children: [
              _QuickActionIcon(
                icon: voiceState.isMuted ? LucideIcons.micOff : LucideIcons.mic,
                color: voiceState.isMuted ? AppColors.neonCoral : AppColors.neonCyan,
                tooltip: voiceState.isMuted ? 'Desmutar' : 'Mutar',
                onTap: () => voiceNotifier.toggleMute(),
              ),
              const SizedBox(width: 4),
              _QuickActionIcon(
                icon: voiceState.isDeafened ? LucideIcons.volumeX : LucideIcons.volume2,
                color: voiceState.isDeafened ? AppColors.neonCoral : AppColors.textSecondary,
                tooltip: voiceState.isDeafened ? 'Desensurdecer' : 'Ensurdecer',
                onTap: () => voiceNotifier.toggleDeafen(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _QuickActionIcon({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }
}
