import 'package:flutter_riverpod/flutter_riverpod.dart';

class VoiceState {
  final bool isMicMuted;
  final bool isDeafened;
  final bool isConnected;
  final String? connectedChannelId;
  final String? connectedServerId;

  const VoiceState({
    this.isMicMuted = false,
    this.isDeafened = false,
    this.isConnected = false,
    this.connectedChannelId,
    this.connectedServerId,
  });

  VoiceState copyWith({
    bool? isMicMuted,
    bool? isDeafened,
    bool? isConnected,
    String? connectedChannelId,
    String? connectedServerId,
    bool clearChannel = false,
  }) {
    return VoiceState(
      isMicMuted: isMicMuted ?? this.isMicMuted,
      isDeafened: isDeafened ?? this.isDeafened,
      isConnected: isConnected ?? this.isConnected,
      connectedChannelId:
          clearChannel ? null : (connectedChannelId ?? this.connectedChannelId),
      connectedServerId:
          clearChannel ? null : (connectedServerId ?? this.connectedServerId),
    );
  }
}

class VoiceStateNotifier extends StateNotifier<VoiceState> {
  VoiceStateNotifier() : super(const VoiceState());

  void toggleMic() {
    final nextMuted = !state.isMicMuted;
    if (!nextMuted && state.isDeafened) {
      // Ao desmutar o microfone estando ensurdecido, também reativa o áudio
      state = state.copyWith(isMicMuted: false, isDeafened: false);
    } else {
      state = state.copyWith(isMicMuted: nextMuted);
    }
  }

  void toggleDeafened() {
    final nextDeafened = !state.isDeafened;
    if (nextDeafened) {
      // Ao desativar o áudio, também muta o microfone automaticamente
      state = state.copyWith(
        isDeafened: true,
        isMicMuted: true,
      );
    } else {
      state = state.copyWith(
        isDeafened: false,
      );
    }
  }

  void setMicMuted(bool muted) {
    state = state.copyWith(isMicMuted: muted);
  }

  void setDeafened(bool deafened) {
    if (deafened) {
      state = state.copyWith(isDeafened: true, isMicMuted: true);
    } else {
      state = state.copyWith(isDeafened: false);
    }
  }

  void connectVoice(String serverId, String channelId) {
    state = state.copyWith(
      isConnected: true,
      connectedServerId: serverId,
      connectedChannelId: channelId,
    );
  }

  void disconnectVoice() {
    state = state.copyWith(
      isConnected: false,
      clearChannel: true,
    );
  }
}

final voiceStateProvider =
    StateNotifierProvider<VoiceStateNotifier, VoiceState>((ref) {
  return VoiceStateNotifier();
});
