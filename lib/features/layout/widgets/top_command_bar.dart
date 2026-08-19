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
    final serverNotifier = ref.read(serverProvider.notifier);
    final voiceState = ref.watch(voiceProvider);
    final voiceNotifier = ref.read(voiceProvider.notifier);

    final isDashboard = serverState.viewMode == ViewMode.homeDashboard;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Brand Logo & Home Navigation Trigger
          InkWell(
            onTap: () => serverNotifier.navigateTo(ViewMode.homeDashboard),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cyanGlow,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
                      fontSize: 13,
                    ),
                  ),
                  const Text(
                    'NBX',
                    style: TextStyle(
                      color: AppColors.neonCyan,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),
          Container(width: 1, height: 22, color: AppColors.borderSubtle),
          const SizedBox(width: 16),

          // Home Dashboard Pill
          InkWell(
            onTap: () => serverNotifier.navigateTo(ViewMode.homeDashboard),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDashboard ? AppColors.neonCyan.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDashboard ? AppColors.neonCyan : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.layoutGrid,
                    size: 14,
                    color: isDashboard ? AppColors.neonCyan : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Hubs',
                    style: TextStyle(
                      color: isDashboard ? Colors.white : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: isDashboard ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Global Search Bar (Cmd+K Style Trigger)
          Expanded(
            child: Center(
              child: InkWell(
                onTap: () => serverNotifier.toggleCommandPalette(true),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.bgInput,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.borderGlow),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.search, size: 14, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Search Hubs, Topics, or type a command...',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.borderSubtle),
                        ),
                        child: const Text(
                          '⌘K',
                          style: TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(width: 12),

          // Direct Messages Shortcut
          Tooltip(
            message: 'Direct Messages',
            child: InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.bgSurface,
                    content: const Text(
                      'Direct Messages panel opened',
                      style: TextStyle(color: AppColors.neonCyan),
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.neonCyan),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(LucideIcons.messageCircle, size: 16, color: AppColors.textSecondary),
                    Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.neonCoral,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Telemetry Capsule (When In-Call)
          if (voiceState.isConnected) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.radio, size: 12, color: AppColors.neonEmerald),
                  const SizedBox(width: 6),
                  Text(
                    '${voiceState.pingMs}ms • SFU',
                    style: const TextStyle(
                      color: AppColors.neonEmerald,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Quick Audio Controls
          _QuickActionIcon(
            icon: voiceState.isMuted ? LucideIcons.micOff : LucideIcons.mic,
            color: voiceState.isMuted ? AppColors.neonCoral : AppColors.neonCyan,
            tooltip: voiceState.isMuted ? 'Unmute [ALT+V]' : 'Mute [ALT+V]',
            onTap: () => voiceNotifier.toggleMute(),
          ),
          const SizedBox(width: 6),
          _QuickActionIcon(
            icon: voiceState.isDeafened ? LucideIcons.volumeX : LucideIcons.volume2,
            color: voiceState.isDeafened ? AppColors.neonCoral : AppColors.textSecondary,
            tooltip: voiceState.isDeafened ? 'Undeafen' : 'Deafen',
            onTap: () => voiceNotifier.toggleDeafen(),
          ),

          const SizedBox(width: 14),
          Container(width: 1, height: 22, color: AppColors.borderSubtle),
          const SizedBox(width: 14),

          // User Profile Avatar & Online Status Indicator
          InkWell(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.bgSurface,
                  content: const Text(
                    'Taui • Status: Online (ProjectNBX Lead)',
                    style: TextStyle(color: AppColors.neonCyan),
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: AppColors.borderGlow),
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            borderRadius: BorderRadius.circular(20),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: AppColors.cyanVioletGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'TL',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.neonEmerald,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.bgSurface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Taui',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'Online',
                      style: TextStyle(
                        color: AppColors.neonEmerald,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
          child: Icon(icon, color: color, size: 15),
        ),
      ),
    );
  }
}
