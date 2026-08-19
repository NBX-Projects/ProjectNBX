class VoiceParticipant {
  final String id;
  final String name;
  final String tag;
  final String avatar;
  final bool isSpeaking;
  final double audioLevel; // 0.0 to 1.0 for real-time waveform bars
  final bool isMuted;
  final bool isDeafened;
  final bool isScreenSharing;
  final bool isCameraOn;
  final String activity;

  const VoiceParticipant({
    required this.id,
    required this.name,
    required this.tag,
    required this.avatar,
    this.isSpeaking = false,
    this.audioLevel = 0.0,
    this.isMuted = false,
    this.isDeafened = false,
    this.isScreenSharing = false,
    this.isCameraOn = false,
    this.activity = 'Online',
  });

  VoiceParticipant copyWith({
    String? id,
    String? name,
    String? tag,
    String? avatar,
    bool? isSpeaking,
    double? audioLevel,
    bool? isMuted,
    bool? isDeafened,
    bool? isScreenSharing,
    bool? isCameraOn,
    String? activity,
  }) {
    return VoiceParticipant(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      avatar: avatar ?? this.avatar,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      audioLevel: audioLevel ?? this.audioLevel,
      isMuted: isMuted ?? this.isMuted,
      isDeafened: isDeafened ?? this.isDeafened,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      activity: activity ?? this.activity,
    );
  }
}

class VoiceRoomState {
  final bool isConnected;
  final String? roomId;
  final String? roomName;
  final String? serverName;
  final bool isMuted;
  final bool isDeafened;
  final bool isScreenSharing;
  final bool isCameraOn;
  final List<VoiceParticipant> participants;
  final int pingMs;
  final String codec;
  final int bitrateKbps;

  const VoiceRoomState({
    this.isConnected = false,
    this.roomId,
    this.roomName,
    this.serverName,
    this.isMuted = false,
    this.isDeafened = false,
    this.isScreenSharing = false,
    this.isCameraOn = false,
    this.participants = const [],
    this.pingMs = 12,
    this.codec = 'Opus DTX',
    this.bitrateKbps = 48,
  });

  VoiceRoomState copyWith({
    bool? isConnected,
    String? roomId,
    String? roomName,
    String? serverName,
    bool? isMuted,
    bool? isDeafened,
    bool? isScreenSharing,
    bool? isCameraOn,
    List<VoiceParticipant>? participants,
    int? pingMs,
    String? codec,
    int? bitrateKbps,
  }) {
    return VoiceRoomState(
      isConnected: isConnected ?? this.isConnected,
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      serverName: serverName ?? this.serverName,
      isMuted: isMuted ?? this.isMuted,
      isDeafened: isDeafened ?? this.isDeafened,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      isCameraOn: isCameraOn ?? this.isCameraOn,
      participants: participants ?? this.participants,
      pingMs: pingMs ?? this.pingMs,
      codec: codec ?? this.codec,
      bitrateKbps: bitrateKbps ?? this.bitrateKbps,
    );
  }
}
