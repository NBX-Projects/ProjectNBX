import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum ChannelType { text, voice, unified }

class Channel {
  final String id;
  final String name;
  final String tag;
  final ChannelType type;
  final String description;
  final int unreadCount;
  final List<String> activeMembers;
  final int activeVoiceCount;
  final bool hasActiveScreenShare;

  const Channel({
    required this.id,
    required this.name,
    this.tag = 'GENERAL',
    this.type = ChannelType.unified,
    this.description = '',
    this.unreadCount = 0,
    this.activeMembers = const [],
    this.activeVoiceCount = 0,
    this.hasActiveScreenShare = false,
  });

  Channel copyWith({
    String? id,
    String? name,
    String? tag,
    ChannelType? type,
    String? description,
    int? unreadCount,
    List<String>? activeMembers,
    int? activeVoiceCount,
    bool? hasActiveScreenShare,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      tag: tag ?? this.tag,
      type: type ?? this.type,
      description: description ?? this.description,
      unreadCount: unreadCount ?? this.unreadCount,
      activeMembers: activeMembers ?? this.activeMembers,
      activeVoiceCount: activeVoiceCount ?? this.activeVoiceCount,
      hasActiveScreenShare: hasActiveScreenShare ?? this.hasActiveScreenShare,
    );
  }
}

class Server {
  final String id;
  final String name;
  final String acronym;
  final String description;
  final String category;
  final String? iconUrl;
  final LinearGradient bannerGradient;
  final Color accentColor;
  final int memberCount;
  final int onlineCount;
  final int unreadCount;
  final String? activeVoiceTopic;
  final List<String> activeVoiceMembers;
  final List<String> tags;
  final bool isFavorite;
  final bool isTrending;
  final List<Channel> channels;

  const Server({
    required this.id,
    required this.name,
    required this.acronym,
    this.description = '',
    this.category = 'Community',
    this.iconUrl,
    this.bannerGradient = AppColors.darkCardGradient,
    this.accentColor = AppColors.neonCyan,
    this.memberCount = 100,
    this.onlineCount = 20,
    this.unreadCount = 0,
    this.activeVoiceTopic,
    this.activeVoiceMembers = const [],
    this.tags = const [],
    this.isFavorite = false,
    this.isTrending = false,
    required this.channels,
  });
}

class ChatMessage {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String authorRole;
  final String content;
  final DateTime timestamp;
  final bool isCurrentUser;
  final String? codeSnippet;
  final String? codeLang;
  final Map<String, int> reactions;

  const ChatMessage({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    this.authorRole = 'Member',
    required this.content,
    required this.timestamp,
    this.isCurrentUser = false,
    this.codeSnippet,
    this.codeLang,
    this.reactions = const {},
  });

  ChatMessage copyWith({
    String? id,
    String? authorName,
    String? authorAvatar,
    String? authorRole,
    String? content,
    DateTime? timestamp,
    bool? isCurrentUser,
    String? codeSnippet,
    String? codeLang,
    Map<String, int>? reactions,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      authorRole: authorRole ?? this.authorRole,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
      codeSnippet: codeSnippet ?? this.codeSnippet,
      codeLang: codeLang ?? this.codeLang,
      reactions: reactions ?? this.reactions,
    );
  }
}
