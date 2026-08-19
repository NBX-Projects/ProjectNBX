import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voice_state.dart';

class VoiceNotifier extends StateNotifier<VoiceRoomState> {
  Timer? _waveformTimer;
  final Random _random = Random();

  VoiceNotifier() : super(const VoiceRoomState());

  void joinVoiceChannel(String roomId, String roomName, {String serverName = 'NBX Cyber-HQ'}) {
    if (state.isConnected && state.roomId == roomId) return;

    state = VoiceRoomState(
      isConnected: true,
      roomId: roomId,
      roomName: roomName,
      serverName: serverName,
      isMuted: false,
      isDeafened: false,
      isScreenSharing: false,
      isCameraOn: false,
      pingMs: 11,
      codec: 'Opus 48kHz (DTX)',
      bitrateKbps: 48,
      participants: [
        const VoiceParticipant(
          id: 'p1',
          name: 'Taui',
          tag: 'TL',
          avatar: 'assets/logo.png',
          activity: 'Flutter / Windows Engine',
          isSpeaking: false,
          audioLevel: 0.0,
        ),
        const VoiceParticipant(
          id: 'p2',
          name: 'Lucas Dev',
          tag: 'LD',
          avatar: 'LD',
          activity: 'LiveKit Rust SFU',
          isSpeaking: true,
          audioLevel: 0.75,
        ),
        const VoiceParticipant(
          id: 'p3',
          name: 'Gabriel',
          tag: 'GB',
          avatar: 'GB',
          activity: 'Counter-Strike 2',
          isSpeaking: false,
          audioLevel: 0.0,
        ),
        const VoiceParticipant(
          id: 'p4',
          name: 'CyberBot 01',
          tag: 'AI',
          avatar: '🤖',
          activity: 'Synthesizing Audio',
          isSpeaking: false,
          audioLevel: 0.0,
        ),
      ],
    );

    _startWaveformSimulation();
  }

  void leaveVoiceChannel() {
    _waveformTimer?.cancel();
    state = const VoiceRoomState(isConnected: false);
  }

  void toggleMute() {
    if (!state.isConnected) return;
    final newMute = !state.isMuted;
    state = state.copyWith(
      isMuted: newMute,
      participants: state.participants.map((p) {
        if (p.id == 'p1') {
          return p.copyWith(
            isMuted: newMute,
            isSpeaking: newMute ? false : p.isSpeaking,
            audioLevel: newMute ? 0.0 : p.audioLevel,
          );
        }
        return p;
      }).toList(),
    );
  }

  void toggleDeafen() {
    if (!state.isConnected) return;
    final newDeafen = !state.isDeafened;
    state = state.copyWith(
      isDeafened: newDeafen,
      isMuted: newDeafen ? true : state.isMuted,
      participants: state.participants.map((p) {
        if (p.id == 'p1') {
          return p.copyWith(
            isDeafened: newDeafen,
            isMuted: newDeafen ? true : state.isMuted,
            isSpeaking: false,
            audioLevel: 0.0,
          );
        }
        return p;
      }).toList(),
    );
  }

  void toggleScreenShare() {
    if (!state.isConnected) return;
    final newScreenShare = !state.isScreenSharing;
    state = state.copyWith(
      isScreenSharing: newScreenShare,
      participants: state.participants.map((p) {
        if (p.id == 'p1') {
          return p.copyWith(isScreenSharing: newScreenShare);
        }
        return p;
      }).toList(),
    );
  }

  void toggleCamera() {
    if (!state.isConnected) return;
    final newCamera = !state.isCameraOn;
    state = state.copyWith(
      isCameraOn: newCamera,
      participants: state.participants.map((p) {
        if (p.id == 'p1') {
          return p.copyWith(isCameraOn: newCamera);
        }
        return p;
      }).toList(),
    );
  }

  void _startWaveformSimulation() {
    _waveformTimer?.cancel();
    int tick = 0;
    _waveformTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
      if (!state.isConnected) {
        timer.cancel();
        return;
      }
      tick++;

      final lucasSpeaking = (tick ~/ 15) % 2 == 0;
      final gabrielSpeaking = (tick ~/ 20) % 3 == 1;

      state = state.copyWith(
        participants: state.participants.map((p) {
          if (p.id == 'p2') {
            return p.copyWith(
              isSpeaking: lucasSpeaking,
              audioLevel: lucasSpeaking ? 0.3 + _random.nextDouble() * 0.7 : 0.0,
            );
          }
          if (p.id == 'p3') {
            return p.copyWith(
              isSpeaking: gabrielSpeaking,
              audioLevel: gabrielSpeaking ? 0.2 + _random.nextDouble() * 0.8 : 0.0,
            );
          }
          return p;
        }).toList(),
      );
    });
  }

  @override
  void dispose() {
    _waveformTimer?.cancel();
    super.dispose();
  }
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceRoomState>((ref) {
  return VoiceNotifier();
});
