class VoiceParticipant {
  final String id;
  final String name;
  final String avatar;
  final bool isSpeaking;
  final bool isMuted;
  final bool isDeafened;
  final bool isScreenSharing;
  final bool isCameraOn;

  const VoiceParticipant({
    required this.id,
    required this.name,
    required this.avatar,
    this.isSpeaking = false,
    this.isMuted = false,
    this.isDeafened = false,
    this.isScreenSharing = false,
    this.isCameraOn = false,
  });

  VoiceParticipant copyWith({
    String? id,
    String? name,
    String? avatar,
    bool? isSpeaking,
    bool? isMuted,
    bool? isDeafened,
    bool? isScreenSharing,
    bool? isCameraOn,
  }) {
    return VoiceParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      isMuted: isMuted ?? this.isMuted,
      isDeafened: isDeafened ?? this.isDeafened,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isCameraOn: isCameraOn ?? this.isCameraOn,
    );
  }
}

class VoiceRoomState {
  final bool isConnected;
  final String? roomId;
  final String? roomName;
  final bool isMuted;
  final bool isDeafened;
  final bool isScreenSharing;
  final bool isCameraOn;
  final List<VoiceParticipant> participants;
  final int pingMs;

  const VoiceRoomState({
    this.isConnected = false,
    this.roomId,
    this.roomName,
    this.isMuted = false,
    this.isDeafened = false,
    this.isScreenSharing = false,
    this.isCameraOn = false,
    this.participants = const [],
    this.pingMs = 18,
  });

  VoiceRoomState copyWith({
    bool? isConnected,
    String? roomId,
    String? roomName,
    bool? isMuted,
    bool? isDeafened,
    bool? isScreenSharing,
    bool? isCameraOn,
    List<VoiceParticipant>? participants,
    int? pingMs,
  }) {
    return VoiceRoomState(
      isConnected: isConnected ?? this.isConnected,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      isMuted: isMuted ?? this.isMuted,
      isDeafened: isDeafened ?? this.isDeafened,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      participants: participants ?? this.participants,
      pingMs: pingMs ?? this.pingMs,
    );
  }
}
