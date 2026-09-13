import 'package:flutter/material.dart';

enum ChannelType {
  hybrid,
  text,
  voice,
  announcement,
  media,
  files;

  static ChannelType fromString(String? val) {
    if (val == null) return ChannelType.hybrid;
    switch (val.toLowerCase()) {
      case 'voice':
        return ChannelType.voice;
      case 'announcement':
      case 'anuncios':
        return ChannelType.announcement;
      case 'media':
      case 'imagens':
        return ChannelType.media;
      case 'files':
      case 'arquivos':
        return ChannelType.files;
      case 'text':
        return ChannelType.text;
      case 'hybrid':
      default:
        return ChannelType.hybrid;
    }
  }
}

class ChannelMember {
  final String id;
  final String name;
  final String initials;
  final Color avatarColor;
  final bool isLive;
  final String? liveGame;
  final bool isSpeaking;
  final bool isMuted;

  const ChannelMember({
    required this.id,
    required this.name,
    required this.initials,
    required this.avatarColor,
    this.isLive = false,
    this.liveGame,
    this.isSpeaking = false,
    this.isMuted = false,
  });
}

class ChannelModel {
  final String id;
  final String serverId;
  final String name;
  final ChannelType type;
  final int position;
  final int unreadCount;
  final List<ChannelMember> activeMembers;

  const ChannelModel({
    required this.id,
    required this.serverId,
    required this.name,
    required this.type,
    this.position = 0,
    this.unreadCount = 0,
    this.activeMembers = const [],
  });

  factory ChannelModel.fromJson(Map<String, dynamic> json) {
    return ChannelModel(
      id: json['id'] as String? ?? '',
      serverId: json['server_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: ChannelType.fromString(json['type'] as String?),
      position: json['position'] as int? ?? 0,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'name': name,
      'type': type.name,
      'position': position,
      'unread_count': unreadCount,
    };
  }

  ChannelModel copyWith({
    String? id,
    String? serverId,
    String? name,
    ChannelType? type,
    int? position,
    int? unreadCount,
    List<ChannelMember>? activeMembers,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      type: type ?? this.type,
      position: position ?? this.position,
      unreadCount: unreadCount ?? this.unreadCount,
      activeMembers: activeMembers ?? this.activeMembers,
    );
  }
}

