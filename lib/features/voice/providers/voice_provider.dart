import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/voice_state.dart';

class VoiceNotifier extends StateNotifier<VoiceRoomState> {
  Timer? _speakingSimulationTimer;

  VoiceNotifier() : super(const VoiceRoomState());

  void joinVoiceChannel(String roomId, String roomName) {
    // If already connected to the same room, do nothing
    if (state.isConnected && state.roomId == roomId) return;

    state = VoiceRoomState(
      isConnected: true,
      roomId: roomId,
      roomName: roomName,
      isMuted: false,
      isDeafened: false,
      isScreenSharing: false,
      isCameraOn: false,
      pingMs: 14,
      participants: [
        const VoiceParticipant(
          id: 'p1',
          name: 'Taui (Você)',
          avatar: 'TL',
          isSpeaking: false,
        ),
        const VoiceParticipant(
          id: 'p2',
          name: 'Lucas Dev',
          avatar: 'LD',
          isSpeaking: true,
        ),
        const VoiceParticipant(
          id: 'p3',
          name: 'Gabriel',
          avatar: 'GB',
          isSpeaking: false,
        ),
      ],
    );

    _startSpeakingSimulation();
  }

  void leaveVoiceChannel() {
    _speakingSimulationTimer?.cancel();
    state = const VoiceRoomState(isConnected: false);
  }

  void toggleMute() {
    if (!state.isConnected) return;
    final newMute = !state.isMuted;
    state = state.copyWith(
      isMuted: newMute,
      participants: state.participants.map((p) {
        if (p.id == 'p1') {
          return p.copyWith(isMuted: newMute, isSpeaking: newMute ? false : p.isSpeaking);
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

  void _startSpeakingSimulation() {
    _speakingSimulationTimer?.cancel();
    int tick = 0;
    _speakingSimulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!state.isConnected) {
        timer.cancel();
        return;
      }
      tick++;
      final isLucasSpeaking = tick % 2 == 0;
      final isGabrielSpeaking = tick % 3 == 0;

      state = state.copyWith(
        participants: state.participants.map((p) {
          if (p.id == 'p2') return p.copyWith(isSpeaking: isLucasSpeaking);
          if (p.id == 'p3') return p.copyWith(isSpeaking: isGabrielSpeaking);
          return p;
        }).toList(),
      );
    });
  }

  @override
  void dispose() {
    _speakingSimulationTimer?.cancel();
    super.dispose();
  }
}

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceRoomState>((ref) {
  return VoiceNotifier();
});
