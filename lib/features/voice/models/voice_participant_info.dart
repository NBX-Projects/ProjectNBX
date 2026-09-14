class VoiceParticipantInfo {
  final String sessionId;
  final String userId;
  final String username;
  final String serverId;
  final String channelId;
  final String device;
  final bool isInVoice;
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
      'is_transmitting': isTransmitting,
      if (streamTitle != null) 'stream_title': streamTitle,
      if (previewType != null) 'preview_type': previewType,
      if (thumbnail != null) 'thumbnail': thumbnail,
      'is_muted': isMuted,
      'is_deafened': isDeafened,
      'is_speaking': isSpeaking,
    };
  }
}
