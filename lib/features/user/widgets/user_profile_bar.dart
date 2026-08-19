import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../voice/providers/voice_provider.dart';

class UserProfileBar extends ConsumerWidget {
  const UserProfileBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceProvider);
    final voiceNotifier = ref.read(voiceProvider.notifier);

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.bgUserPanel,
      child: Row(
        children: [
          // User Avatar with Online Dot
          Stack(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text(
                  'TL',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: AppColors.speakingGreen,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.bgUserPanel,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),

          // User Info
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Taui',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '#dev-online',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action Buttons: Mic, Deafen, Settings
          _IconButton(
            icon: voiceState.isMuted ? LucideIcons.micOff : LucideIcons.mic,
            color: voiceState.isMuted ? AppColors.dangerRed : AppColors.textInteractive,
            tooltip: voiceState.isMuted ? 'Desmutar' : 'Silenciar',
            onTap: () => voiceNotifier.toggleMute(),
          ),
          _IconButton(
            icon: voiceState.isDeafened ? LucideIcons.headphones : LucideIcons.headphones,
            color: voiceState.isDeafened ? AppColors.dangerRed : AppColors.textInteractive,
            tooltip: voiceState.isDeafened ? 'Desensurdecer' : 'Ensurdecer',
            onTap: () => voiceNotifier.toggleDeafen(),
          ),
          _IconButton(
            icon: LucideIcons.settings,
            color: AppColors.textInteractive,
            tooltip: 'Configurações de Usuário',
            onTap: () {
              _showSettingsDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Row(
          children: [
            Icon(LucideIcons.settings, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Configurações do ProjectNBX', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dispositivo de Áudio:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Entrada: Microfone Padrão (WebRTC DTX 48kbps)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            SizedBox(height: 12),
            Text('Atalho de Push-to-Talk:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Tecla configurada: Alt + V (Global)', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            SizedBox(height: 12),
            Text('Servidor LiveKit:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Host: wss://livekit.nbx.local:7880', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  const _IconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(5),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }
}
