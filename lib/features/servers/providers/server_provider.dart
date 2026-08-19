import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/server_model.dart';

class ServerState {
  final List<Server> servers;
  final Server selectedServer;
  final Channel selectedChannel;
  final Map<String, List<ChatMessage>> channelMessages;

  const ServerState({
    required this.servers,
    required this.selectedServer,
    required this.selectedChannel,
    required this.channelMessages,
  });

  ServerState copyWith({
    List<Server>? servers,
    Server? selectedServer,
    Channel? selectedChannel,
    Map<String, List<ChatMessage>>? channelMessages,
  }) {
    return ServerState(
      servers: servers ?? this.servers,
      selectedServer: selectedServer ?? this.selectedServer,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      channelMessages: channelMessages ?? this.channelMessages,
    );
  }
}

final defaultServers = [
  Server(
    id: 'nbx-devs',
    name: 'NBX Developers & Gaming',
    acronym: 'NBX',
    channels: [
      const Channel(id: 'c1', name: 'boas-vindas', type: ChannelType.text),
      const Channel(id: 'c2', name: 'geral-dev', type: ChannelType.text),
      const Channel(id: 'c3', name: 'setup-e-hardware', type: ChannelType.text),
      const Channel(id: 'c4', name: 'jogatinas', type: ChannelType.text),
      const Channel(id: 'v1', name: '🔊 Lounge Geral', type: ChannelType.voice, activeMembers: ['Taui (Você)', 'Lucas Dev', 'Gabriel']),
      const Channel(id: 'v2', name: '🔊 Squad Gaming', type: ChannelType.voice),
      const Channel(id: 'v3', name: '🔊 Pareamento / Code', type: ChannelType.voice),
    ],
  ),
  Server(
    id: 'flutter-brasil',
    name: 'Flutter & Dart Brasil',
    acronym: 'FLT',
    channels: [
      const Channel(id: 'f1', name: 'duvidas-gerais', type: ChannelType.text),
      const Channel(id: 'f2', name: 'showcase-projetos', type: ChannelType.text),
      const Channel(id: 'fv1', name: '🔊 Dev Talk', type: ChannelType.voice),
    ],
  ),
  Server(
    id: 'rust-lab',
    name: 'Rust & WebRTC Lab',
    acronym: 'RST',
    channels: [
      const Channel(id: 'r1', name: 'livekit-sfu', type: ChannelType.text),
      const Channel(id: 'r2', name: 'webrtc-benchmarks', type: ChannelType.text),
      const Channel(id: 'rv1', name: '🔊 Lab Room', type: ChannelType.voice),
    ],
  ),
];

final initialMessages = <String, List<ChatMessage>>{
  'c2': [
    ChatMessage(
      id: 'm1',
      authorName: 'Lucas Dev',
      authorAvatar: 'LD',
      content: 'E aí pessoal! Já subiram a instância do LiveKit no servidor local?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    ChatMessage(
      id: 'm2',
      authorName: 'Gabriel',
      authorAvatar: 'GB',
      content: 'Sim! Latência tá batendo 15ms aqui no estado. Qualidade do codec Opus em 48kbps tá absurda.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 18)),
    ),
    ChatMessage(
      id: 'm3',
      authorName: 'Taui (Você)',
      authorAvatar: 'TL',
      content: 'Perfeito! O app Desktop em Flutter ficou ultra responsivo e gastando menos de 60MB de RAM.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isCurrentUser: true,
    ),
  ],
  'c1': [
    ChatMessage(
      id: 'w1',
      authorName: 'System Bot',
      authorAvatar: '🤖',
      content: 'Bem-vindo ao ProjectNBX! Entre em um canal de voz para testar o áudio WebRTC.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ],
};

class ServerNotifier extends StateNotifier<ServerState> {
  ServerNotifier()
      : super(
          ServerState(
            servers: defaultServers,
            selectedServer: defaultServers[0],
            selectedChannel: defaultServers[0].channels[1], // 'geral-dev'
            channelMessages: initialMessages,
          ),
        );

  void selectServer(Server server) {
    state = state.copyWith(
      selectedServer: server,
      selectedChannel: server.channels.first,
    );
  }

  void selectChannel(Channel channel) {
    state = state.copyWith(selectedChannel: channel);
  }

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final channelId = state.selectedChannel.id;
    final currentMsgs = state.channelMessages[channelId] ?? [];

    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: 'Taui (Você)',
      authorAvatar: 'TL',
      content: text.trim(),
      timestamp: DateTime.now(),
      isCurrentUser: true,
    );

    final updatedMap = Map<String, List<ChatMessage>>.from(state.channelMessages);
    updatedMap[channelId] = [...currentMsgs, newMsg];

    state = state.copyWith(channelMessages: updatedMap);
  }
}

final serverProvider = StateNotifierProvider<ServerNotifier, ServerState>((ref) {
  return ServerNotifier();
});
