import 'package:flutter/material.dart';

class ServerData {
  final String id;
  final String name;
  final String banner;
  final int voiceCount;
  final int memberCount;
  final String category;
  final Color accentColor;
  final int unread;
  final String activeChannel;
  final String description;

  const ServerData({
    required this.id,
    required this.name,
    required this.banner,
    required this.voiceCount,
    required this.memberCount,
    required this.category,
    required this.accentColor,
    required this.unread,
    required this.activeChannel,
    this.description = '',
  });
}

class VoiceUserData {
  final String id;
  final String name;
  final String initials;
  final Color color;
  final bool speaking;
  final bool muted;
  final bool isStreaming;
  final String avatar;

  const VoiceUserData({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    this.speaking = false,
    this.muted = false,
    this.isStreaming = false,
    this.avatar = '',
  });

  VoiceUserData copyWith({
    bool? speaking,
    bool? muted,
    bool? isStreaming,
  }) {
    return VoiceUserData(
      id: id,
      name: name,
      initials: initials,
      color: color,
      speaking: speaking ?? this.speaking,
      muted: muted ?? this.muted,
      isStreaming: isStreaming ?? this.isStreaming,
      avatar: avatar,
    );
  }
}

enum ChannelKind { textVoice, text, images, files }

class ChannelData {
  final String id;
  final String name;
  final ChannelKind type;
  final int unread;
  final List<VoiceUserData> users;
  final String description;

  const ChannelData({
    required this.id,
    required this.name,
    required this.type,
    this.unread = 0,
    this.users = const [],
    this.description = '',
  });
}

class MemberData {
  final String id;
  final String name;
  final String initials;
  final Color color;
  final String status; // online, streaming, idle, dnd, offline
  final String role; // Admin, Mod, VIP, Membro
  final Color roleColor;
  final String playing;

  const MemberData({
    required this.id,
    required this.name,
    required this.initials,
    required this.color,
    required this.status,
    required this.role,
    required this.roleColor,
    this.playing = '',
  });
}

class ChatMessageData {
  final String id;
  final String author;
  final String initials;
  final Color color;
  final String time;
  final String content;
  final bool isMe;
  final String? codeSnippet;
  final String? codeLang;
  final Map<String, int> reactions;

  const ChatMessageData({
    required this.id,
    required this.author,
    required this.initials,
    required this.color,
    required this.time,
    required this.content,
    required this.isMe,
    this.codeSnippet,
    this.codeLang,
    this.reactions = const {},
  });

  ChatMessageData copyWith({
    Map<String, int>? reactions,
  }) {
    return ChatMessageData(
      id: id,
      author: author,
      initials: initials,
      color: color,
      time: time,
      content: content,
      isMe: isMe,
      codeSnippet: codeSnippet,
      codeLang: codeLang,
      reactions: reactions ?? this.reactions,
    );
  }
}

class ActivityData {
  final String id;
  final String initials;
  final String user;
  final String action;
  final String server;
  final String serverId;
  final String time;
  final String type; // voice, stream, group, clip
  final Color color;

  const ActivityData({
    required this.id,
    required this.initials,
    required this.user,
    required this.action,
    required this.server,
    required this.serverId,
    required this.time,
    required this.type,
    required this.color,
  });
}

class MentionData {
  final String id;
  final String server;
  final String channel;
  final String user;
  final String preview;
  final String time;

  const MentionData({
    required this.id,
    required this.server,
    required this.channel,
    required this.user,
    required this.preview,
    required this.time,
  });
}

class BoardData {
  final String id;
  final String type; // announcement, event, reminder
  final String title;
  final String content;
  final String date;
  final String author;
  final bool pinned;

  const BoardData({
    required this.id,
    required this.type,
    required this.title,
    required this.content,
    required this.date,
    required this.author,
    required this.pinned,
  });
}

class ImageGalleryItem {
  final String id;
  final String title;
  final String author;
  final String src;

  const ImageGalleryItem({
    required this.id,
    required this.title,
    required this.author,
    required this.src,
  });
}

class FileExplorerItem {
  final String id;
  final String name;
  final String kind; // folder, file
  final String detail;
  final String updated;

  const FileExplorerItem({
    required this.id,
    required this.name,
    required this.kind,
    required this.detail,
    required this.updated,
  });
}
