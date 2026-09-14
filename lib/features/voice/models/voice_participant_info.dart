class VoiceParticipantInfo {
  final String sessionId;
  final String userId;
  final String username;
  final String serverId;
  final String channelId;
  final String device;
  final bool isInVoice;
  final bool isConnecting;
  final bool isTransmitting;
  final String? streamTitle;
  final String? previewType;
  final String? thumbnail;
  final bool isMuted;
  final bool isDeafened;
  final bool isSpeaking;
  final DateTime updatedAt;

  const VoiceParticipantInfo({
    required this.sessionId,
    required this.userId,
    required this.username,
    required this.serverId,
    required this.channelId,
    this.device = 'desktop',
    this.isInVoice = true,
    this.isConnecting = false,
    this.isTransmitting = false,
    this.streamTitle,
    this.previewType,
    this.thumbnail,
    this.isMuted = false,
    this.isDeafened = false,
    this.isSpeaking = false,
    required this.updatedAt,
  });

  String get key => sessionId.isNotEmpty ? sessionId : userId;

  factory VoiceParticipantInfo.fromJson(Map<String, dynamic> json) {
    return VoiceParticipantInfo(
      sessionId: (json['session_id'] ?? json['user_id'] ?? '').toString(),
      userId: (json['user_id'] ?? '').toString(),
      username: (json['username'] ?? 'Usuário').toString(),
      serverId: (json['server_id'] ?? '').toString(),
      channelId: (json['channel_id'] ?? '').toString(),
      device: (json['device'] ?? 'desktop').toString(),
      isInVoice: json['is_in_voice'] == true,
      isConnecting: json['is_connecting'] == true,
      isTransmitting: json['is_transmitting'] == true,
      streamTitle: json['stream_title']?.toString(),
      previewType: json['preview_type']?.toString(),
      thumbnail: json['thumbnail']?.toString(),
      isMuted: json['is_muted'] == true,
      isDeafened: json['is_deafened'] == true,
      isSpeaking: json['is_speaking'] == true,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_id': sessionId,
      'user_id': userId,
      'username': username,
      'server_id': serverId,
      'channel_id': channelId,
      'device': device,
      'is_in_voice': isInVoice,
      if (isConnecting) 'is_connecting': true,
      'is_transmitting': isTransmitting,
      if (streamTitle != null) 'stream_title': streamTitle,
      if (previewType != null) 'preview_type': previewType,
      if (thumbnail != null) 'thumbnail': thumbnail,
      'is_muted': isMuted,
      'is_deafened': isDeafened,
      'is_speaking': isSpeaking,
    };
  }

  VoiceParticipantInfo copyWith({
    String? sessionId,
    String? userId,
    String? username,
    String? serverId,
    String? channelId,
    String? device,
    bool? isInVoice,
    bool? isConnecting,
    bool? isTransmitting,
    String? streamTitle,
    String? previewType,
    String? thumbnail,
    bool? isMuted,
    bool? isDeafened,
    bool? isSpeaking,
    DateTime? updatedAt,
  }) {
    return VoiceParticipantInfo(
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      serverId: serverId ?? this.serverId,
      channelId: channelId ?? this.channelId,
      device: device ?? this.device,
      isInVoice: isInVoice ?? this.isInVoice,
      isConnecting: isConnecting ?? this.isConnecting,
      isTransmitting: isTransmitting ?? this.isTransmitting,
      streamTitle: streamTitle ?? this.streamTitle,
      previewType: previewType ?? this.previewType,
      thumbnail: thumbnail ?? this.thumbnail,
      isMuted: isMuted ?? this.isMuted,
      isDeafened: isDeafened ?? this.isDeafened,
      isSpeaking: isSpeaking ?? this.isSpeaking,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
