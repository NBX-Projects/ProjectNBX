import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/voice_provider.dart';
import '../models/voice_state.dart';

class SquadVoiceHUD extends ConsumerWidget {
  const SquadVoiceHUD({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceProvider);
    final voiceNotifier = ref.read(voiceProvider.notifier);

    if (!voiceState.isConnected) {
      return Container(
        color: AppColors.bgOnyx,
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: AppColors.darkCardGradient,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderGlow),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.neonCyan.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4)),
                  ),
                  child: const Icon(LucideIcons.radio, size: 36, color: AppColors.neonCyan),
                ),
                const SizedBox(height: 16),
                const Text(
                  'SQUAD VOICE MESH DISCONNECTED',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Conecte-se a uma sala de áudio de alta fidelidade para iniciar a transmissão.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(LucideIcons.zap, size: 18),
                  label: const Text(
                    'CONECTAR AO LOUNGE GERAL',
                    style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1),
                  ),
                  onPressed: () {
                    voiceNotifier.joinVoiceChannel('v1', '🔊 Lounge Geral');
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      color: AppColors.bgOnyx,
      child: Column(
        children: [
          // Cyber HUD Top Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.bgSurface,
              border: Border(bottom: BorderSide(color: AppColors.borderSubtle)),
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.audioWaveform, color: AppColors.neonEmerald, size: 20),
                const SizedBox(width: 10),
                Text(
                  voiceState.roomName?.toUpperCase() ?? 'SALA DE VOZ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.neonEmerald.withValues(alpha: 0.3)),
                  ),
                  child: Row(
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
                        'SFU LIVE: ${voiceState.pingMs}ms • ${voiceState.bitrateKbps}kbps',
                        style: const TextStyle(
                          color: AppColors.neonEmerald,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Holographic Squad Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  int crossAxis = constraints.maxWidth > 900 ? 3 : (constraints.maxWidth > 550 ? 2 : 1);
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxis,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.35,
                    ),
                    itemCount: voiceState.participants.length,
                    itemBuilder: (context, index) {
                      final participant = voiceState.participants[index];
                      return _HoloParticipantCard(participant: participant);
                    },
                  );
                },
              ),
            ),
          ),

          // Cyberpunk Floating Control Deck
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.borderGlow),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CyberDeckButton(
                  icon: voiceState.isMuted ? LucideIcons.micOff : LucideIcons.mic,
                  color: voiceState.isMuted ? AppColors.neonCoral : AppColors.neonCyan,
                  activeBg: voiceState.isMuted ? AppColors.coralGlow : AppColors.cyanGlow,
                  tooltip: voiceState.isMuted ? 'Desmutar [ALT+V]' : 'Mutar [ALT+V]',
                  onTap: () => voiceNotifier.toggleMute(),
                ),
                const SizedBox(width: 12),
                _CyberDeckButton(
                  icon: voiceState.isCameraOn ? LucideIcons.video : LucideIcons.videoOff,
                  color: voiceState.isCameraOn ? AppColors.neonEmerald : Colors.white,
                  activeBg: AppColors.emeraldGlow,
                  tooltip: voiceState.isCameraOn ? 'Desligar Câmera' : 'Ligar Câmera',
                  onTap: () => voiceNotifier.toggleCamera(),
                ),
                const SizedBox(width: 12),
                _CyberDeckButton(
                  icon: LucideIcons.screenShare,
                  color: voiceState.isScreenSharing ? AppColors.neonViolet : Colors.white,
                  activeBg: AppColors.violetGlow,
                  tooltip: voiceState.isScreenSharing ? 'Parar Transmissão' : 'Compartilhar Tela 60fps',
                  onTap: () => voiceNotifier.toggleScreenShare(),
                ),
                const SizedBox(width: 12),
                Container(width: 1, height: 28, color: AppColors.borderSubtle),
                const SizedBox(width: 12),
                _CyberDeckButton(
                  icon: LucideIcons.phoneOff,
                  color: Colors.white,
                  activeBg: AppColors.neonCoral,
                  isDestructive: true,
                  tooltip: 'Desconectar da Mesh de Voz',
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

class _HoloParticipantCard extends StatelessWidget {
  final VoiceParticipant participant;

  const _HoloParticipantCard({required this.participant});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        gradient: AppColors.darkCardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: participant.isSpeaking ? AppColors.neonEmerald : AppColors.borderSubtle,
          width: participant.isSpeaking ? 2 : 1,
        ),
        boxShadow: participant.isSpeaking
            ? [
                const BoxShadow(
                  color: AppColors.emeraldGlow,
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Stack(
        children: [
          // Center Avatar / Waveform
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: AppColors.cyanVioletGradient,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    participant.tag,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Dynamic Audio Waveform Bars
                if (participant.isSpeaking && !participant.isMuted)
                  _WaveformBars(level: participant.audioLevel)
                else
                  const SizedBox(height: 16),
              ],
            ),
          ),

          // User Info & Activity Pill (Top Left)
          Positioned(
            left: 12,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.bgOnyx,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text(
                    participant.activity,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Mute / Deafened badge (Top Right)
          if (participant.isMuted)
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.neonCoral.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.neonCoral),
                ),
                child: const Icon(LucideIcons.micOff, size: 12, color: AppColors.neonCoral),
              ),
            ),

          // Screen Share Pill (Bottom Right)
          if (participant.isScreenSharing)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.neonViolet,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SCREEN 60FPS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _WaveformBars extends StatelessWidget {
  final double level;
  const _WaveformBars({required this.level});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final height = 4.0 + (level * 12.0) * ((index % 2 == 0) ? 1.0 : 0.6);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: AppColors.neonEmerald,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

class _CyberDeckButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color activeBg;
  final String tooltip;
  final bool isDestructive;
  final VoidCallback onTap;

  const _CyberDeckButton({
    required this.icon,
    required this.color,
    required this.activeBg,
    required this.tooltip,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive ? AppColors.neonCoral : activeBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }
}
