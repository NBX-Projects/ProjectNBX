import 'package:projectnbx/features/servers/models/channel_model.dart';

class ServerModel {
  final String id;
  final String name;
  final String? iconUrl;
  final String ownerId;
  final List<ChannelModel> channels;
  final int memberCount;
  final String category;
  final int bannerPreset;
  final int accentColor;

  const ServerModel({
    required this.id,
    required this.name,
    this.iconUrl,
    required this.ownerId,
    this.channels = const [],
    this.memberCount = 1,
    this.category = 'Comunidade Geral',
    this.bannerPreset = 0,
    this.accentColor = 0xFFF5CBA7,
  });

  factory ServerModel.fromJson(Map<String, dynamic> json) {
    final rawChannels = json['channels'] as List<dynamic>? ?? [];
    final rawCount = json['member_count'] as int? ?? 1;
    final rawPreset = json['banner_preset'] ?? json['bannerPreset'];
    final rawAccent = json['accent_color'] ?? json['accentColor'];

    return ServerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      iconUrl: json['icon_url'] as String?,
      ownerId: json['owner_id'] as String? ?? '',
      channels: rawChannels
          .map((c) => ChannelModel.fromJson(c as Map<String, dynamic>))
          .toList(),
      memberCount: rawCount < 1 ? 1 : rawCount,
      category: json['category'] as String? ?? 'Comunidade Geral',
      bannerPreset: rawPreset is int ? rawPreset : 0,
      accentColor: rawAccent is int ? rawAccent : 0xFFF5CBA7,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon_url': iconUrl,
      'owner_id': ownerId,
      'channels': channels.map((c) => c.toJson()).toList(),
      'member_count': memberCount,
      'category': category,
      'banner_preset': bannerPreset,
      'accent_color': accentColor,
    };
  }

  ServerModel copyWith({
    String? id,
    String? name,
    String? iconUrl,
    String? ownerId,
    List<ChannelModel>? channels,
    int? memberCount,
    String? category,
    int? bannerPreset,
    int? accentColor,
  }) {
    return ServerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      iconUrl: iconUrl ?? this.iconUrl,
      ownerId: ownerId ?? this.ownerId,
      channels: channels ?? this.channels,
      memberCount: memberCount ?? this.memberCount,
      category: category ?? this.category,
      bannerPreset: bannerPreset ?? this.bannerPreset,
      accentColor: accentColor ?? this.accentColor,
    );
  }
}
