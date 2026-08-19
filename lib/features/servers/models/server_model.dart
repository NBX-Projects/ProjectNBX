enum ChannelType { text, voice }

class Channel {
  final String id;
  final String name;
  final ChannelType type;
  final int unreadCount;
  final List<String> activeMembers;

  const Channel({
    required this.id,
    required this.name,
    required this.type,
    this.unreadCount = 0,
    this.activeMembers = const [],
  });

  Channel copyWith({
    String? id,
    String? name,
    ChannelType? type,
    int? unreadCount,
    List<String>? activeMembers,
  }) {
    return Channel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      unreadCount: unreadCount ?? this.unreadCount,
      activeMembers: activeMembers ?? this.activeMembers,
    );
  }
}

class Server {
  final String id;
  final String name;
  final String? iconUrl;
  final String acronym;
  final List<Channel> channels;

  const Server({
    required this.id,
    required this.name,
    this.iconUrl,
    required this.acronym,
    required this.channels,
  });
}

class ChatMessage {
  final String id;
  final String authorName;
  final String authorAvatar;
  final String content;
  final DateTime timestamp;
  final bool isCurrentUser;

  const ChatMessage({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.content,
    required this.timestamp,
    this.isCurrentUser = false,
  });
}
