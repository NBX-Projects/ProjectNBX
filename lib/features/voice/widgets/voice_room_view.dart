import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/voice_provider.dart';
import '../models/voice_state.dart';

class VoiceRoomView extends ConsumerWidget {
  const VoiceRoomView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceProvider);
    final voiceNotifier = ref.read(voiceProvider.notifier);

    if (!voiceState.isConnected) {
      return Container(
        color: AppColors.bgChat,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.volume2, size: 56, color: AppColors.textMuted),
              const SizedBox(height: 16),
              const Text(
                'Nenhum canal de voz ativo',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Clique em um canal de voz na barra lateral para se conectar.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(LucideIcons.radio, size: 18),
                label: const Text('Conectar ao Lounge Geral'),
                onPressed: () {
                  voiceNotifier.joinVoiceChannel('v1', '🔊 Lounge Geral');
                },
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: AppColors.bgChat,
      child: Column(
        children: [
          // Room Header
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.volume2, color: AppColors.speakingGreen, size: 20),
                const SizedBox(width: 8),
                Text(
                  voiceState.roomName ?? 'Sala de Voz',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.signal, size: 14, color: AppColors.speakingGreen),
                      const SizedBox(width: 6),
                      Text(
                        'RTC: ${voiceState.pingMs}ms',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Participants Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxisCount = constraints.maxWidth > 800 ? 3 : (constraints.maxWidth > 500 ? 2 : 1);
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.4,
                    ),
                    itemCount: voiceState.participants.length,
                    itemBuilder: (context, index) {
                      final participant = voiceState.participants[index];
                      return _ParticipantTile(participant: participant);
                    },
                  );
                },
              ),
            ),
          ),

          // Floating Call Controls Bar
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.bgUserPanel,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CallControlButton(
                  icon: voiceState.isMuted ? LucideIcons.micOff : LucideIcons.mic,
                  color: voiceState.isMuted ? AppColors.dangerRed : Colors.white,
                  backgroundColor: voiceState.isMuted ? AppColors.dangerRed.withValues(alpha: 0.2) : AppColors.bgCard,
                  tooltip: voiceState.isMuted ? 'Desmutar Microfone' : 'Mutar Microfone',
                  onTap: () => voiceNotifier.toggleMute(),
                ),
                const SizedBox(width: 8),
                _CallControlButton(
                  icon: voiceState.isCameraOn ? LucideIcons.video : LucideIcons.videoOff,
                  color: voiceState.isCameraOn ? AppColors.speakingGreen : Colors.white,
                  backgroundColor: AppColors.bgCard,
                  tooltip: voiceState.isCameraOn ? 'Desativar Câmera' : 'Ativar Câmera',
                  onTap: () => voiceNotifier.toggleCamera(),
                ),
                const SizedBox(width: 8),
                _CallControlButton(
                  icon: LucideIcons.monitorUp,
                  color: voiceState.isScreenSharing ? AppColors.speakingGreen : Colors.white,
                  backgroundColor: voiceState.isScreenSharing ? AppColors.speakingGreen.withValues(alpha: 0.2) : AppColors.bgCard,
                  tooltip: voiceState.isScreenSharing ? 'Parar Compartilhamento' : 'Compartilhar Tela',
                  onTap: () => voiceNotifier.toggleScreenShare(),
                ),
                const SizedBox(width: 8),
                _CallControlButton(
                  icon: LucideIcons.phoneOff,
                  color: Colors.white,
                  backgroundColor: AppColors.dangerRed,
                  tooltip: 'Desconectar da Chamada',
                  onTap: () => voiceNotifier.leaveVoiceChannel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final VoiceParticipant participant;

  const _ParticipantTile({required this.participant});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: participant.isSpeaking ? AppColors.speakingGreen : AppColors.border,
          width: participant.isSpeaking ? 2.5 : 1,
        ),
        boxShadow: participant.isSpeaking
            ? [
                BoxShadow(
                  color: AppColors.speakingGreen.withValues(alpha: 0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
      child: Stack(
        children: [
          // Center Avatar / Video Placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    participant.avatar,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (participant.isScreenSharing) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'AO VIVO • TELA',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Name and Status at bottom left
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    participant.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  if (participant.isMuted) ...[
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.micOff, size: 12, color: AppColors.dangerRed),
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

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final String tooltip;
  final VoidCallback onTap;

  const _CallControlButton({
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(icon, color: color, size: 20),
          ),
        ),
      ),
    );
  }
}
