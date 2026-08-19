import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../models/server_model.dart';

enum ViewMode { homeDashboard, hubWorkspace, directMessages }

class ServerState {
  final List<Server> servers;
  final Server selectedServer;
  final Channel selectedChannel;
  final Map<String, List<ChatMessage>> channelMessages;
  final ViewMode viewMode;
  final String searchQuery;
  final String selectedCategoryFilter;
  final bool showCommandPalette;
  final bool isScreenSharePiPPinned;
  final bool isScreenSharePiPExpanded;
  final bool isScreenSharePiPVisible;

  const ServerState({
    required this.servers,
    required this.selectedServer,
    required this.selectedChannel,
    required this.channelMessages,
    this.viewMode = ViewMode.homeDashboard,
    this.searchQuery = '',
    this.selectedCategoryFilter = 'ALL',
    this.showCommandPalette = false,
    this.isScreenSharePiPPinned = true,
    this.isScreenSharePiPExpanded = false,
    this.isScreenSharePiPVisible = true,
  });

  ServerState copyWith({
    List<Server>? servers,
    Server? selectedServer,
    Channel? selectedChannel,
    Map<String, List<ChatMessage>>? channelMessages,
    ViewMode? viewMode,
    String? searchQuery,
    String? selectedCategoryFilter,
    bool? showCommandPalette,
    bool? isScreenSharePiPPinned,
    bool? isScreenSharePiPExpanded,
    bool? isScreenSharePiPVisible,
  }) {
    return ServerState(
      servers: servers ?? this.servers,
      selectedServer: selectedServer ?? this.selectedServer,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      channelMessages: channelMessages ?? this.channelMessages,
      viewMode: viewMode ?? this.viewMode,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoryFilter: selectedCategoryFilter ?? this.selectedCategoryFilter,
      showCommandPalette: showCommandPalette ?? this.showCommandPalette,
      isScreenSharePiPPinned: isScreenSharePiPPinned ?? this.isScreenSharePiPPinned,
      isScreenSharePiPExpanded: isScreenSharePiPExpanded ?? this.isScreenSharePiPExpanded,
      isScreenSharePiPVisible: isScreenSharePiPVisible ?? this.isScreenSharePiPVisible,
    );
  }
}

final richDefaultServers = [
  Server(
    id: 'nbx-devs',
    name: 'NBX Core Engineering',
    acronym: 'NBX',
    description: 'High-concurrency WebRTC SFU, Flutter Desktop client & ultra low latency audio mesh.',
    category: 'DEV',
    bannerGradient: const LinearGradient(
      colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: AppColors.neonCyan,
    memberCount: 3840,
    onlineCount: 412,
    unreadCount: 3,
    activeVoiceTopic: '#live-showcase',
    activeVoiceMembers: ['Taui', 'Lucas Dev', 'Gabriel', 'CyberBot'],
    tags: ['#flutter', '#webrtc', '#opus', '#desktop'],
    isFavorite: true,
    isTrending: true,
    channels: [
      const Channel(
        id: 'nbx-announcements',
        name: 'announcements',
        tag: 'ANNOUNCEMENTS',
        description: 'Official releases, benchmarks and architecture changes.',
        unreadCount: 1,
      ),
      const Channel(
        id: 'nbx-general-dev',
        name: 'general-dev',
        tag: 'DEVELOPMENT',
        description: 'Core discussion, pull requests, performance benchmarks and bug hunts.',
        unreadCount: 2,
        activeMembers: ['Taui', 'Lucas Dev', 'Gabriel'],
      ),
      const Channel(
        id: 'nbx-live-showcase',
        name: 'live-showcase',
        tag: 'MEDIA',
        description: 'Interactive 60fps screen shares, pair programming and live code telemetry.',
        activeVoiceCount: 4,
        hasActiveScreenShare: true,
      ),
      const Channel(
        id: 'nbx-webrtc-sfu',
        name: 'webrtc-sfu-mesh',
        tag: 'DEVELOPMENT',
        description: 'LiveKit SFU cascading, DTX, Opus 48kHz tuning and audio packet loss resilience.',
        activeVoiceCount: 2,
      ),
      const Channel(
        id: 'nbx-gaming-lounge',
        name: 'squad-gaming',
        tag: 'GAMING',
        description: 'After-hours gaming, Counter-Strike 2 scrims and setup flex.',
      ),
    ],
  ),
  Server(
    id: 'rust-lab',
    name: 'Rust WebRTC & Systems Lab',
    acronym: 'RST',
    description: 'Memory-safe real-time networking, Tokio asynchronous runtime & SIMD audio processors.',
    category: 'DEV',
    bannerGradient: const LinearGradient(
      colors: [Color(0xFF2B0938), Color(0xFF4A154B), Color(0xFF190624)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: AppColors.neonViolet,
    memberCount: 1920,
    onlineCount: 215,
    unreadCount: 7,
    activeVoiceTopic: '#simd-dsp-voice',
    activeVoiceMembers: ['Klaus', 'Aria_Rust', 'Zero_Cost'],
    tags: ['#rust', '#tokio', '#simd', '#webrtc'],
    isFavorite: true,
    isTrending: false,
    channels: [
      const Channel(
        id: 'rst-general',
        name: 'rust-core',
        tag: 'DEVELOPMENT',
        description: 'Async rust patterns, unsafe reviews and zero-cost abstractions.',
      ),
      const Channel(
        id: 'rst-simd',
        name: 'simd-dsp-voice',
        tag: 'DEVELOPMENT',
        description: 'Fast Fourier Transform audio filtering and noise suppression.',
        activeVoiceCount: 3,
      ),
      const Channel(
        id: 'rst-benchmarks',
        name: 'latency-benchmarks',
        tag: 'MEDIA',
        description: 'Flamegraphs, p99 latency stats and memory footprint reports.',
      ),
    ],
  ),
  Server(
    id: 'cyber-gaming',
    name: 'NeoCyber Competitive Squad',
    acronym: 'CS2',
    description: 'Pro scrims, tactical comms with ultra-low latency audio, and replay analysis.',
    category: 'GAMING',
    bannerGradient: const LinearGradient(
      colors: [Color(0xFF3A0007), Color(0xFF6B0F1A), Color(0xFF1E0105)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: AppColors.neonCoral,
    memberCount: 2450,
    onlineCount: 580,
    unreadCount: 12,
    activeVoiceTopic: '#match-tactics',
    activeVoiceMembers: ['Viper_01', 'GhostRecon', 'Nova', 'Flash'],
    tags: ['#cs2', '#valorant', '#scrims', '#esports'],
    isFavorite: false,
    isTrending: true,
    channels: [
      const Channel(
        id: 'cs-match-tactics',
        name: 'match-tactics',
        tag: 'GAMING',
        description: 'Live tournament comms with sub-20ms audio latency.',
        activeVoiceCount: 5,
        hasActiveScreenShare: true,
      ),
      const Channel(
        id: 'cs-replays',
        name: 'demo-analysis',
        tag: 'MEDIA',
        description: 'Match demos and grenade line-ups.',
      ),
    ],
  ),
  Server(
    id: 'ai-synth-lab',
    name: 'Neural Audio & AI Synth',
    acronym: 'SYN',
    description: 'Real-time AI voice generation, generative noise cancellation and spatial acoustic models.',
    category: 'AI',
    bannerGradient: const LinearGradient(
      colors: [Color(0xFF032B1E), Color(0xFF0A5C43), Color(0xFF021710)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: AppColors.neonEmerald,
    memberCount: 1640,
    onlineCount: 178,
    unreadCount: 0,
    activeVoiceTopic: '#acoustic-tuning',
    activeVoiceMembers: ['DrSynth', 'NeuroWave'],
    tags: ['#ai-voice', '#deep-learning', '#spatial-audio'],
    isFavorite: false,
    isTrending: false,
    channels: [
      const Channel(
        id: 'ai-general',
        name: 'model-checkpoints',
        tag: 'AI',
        description: 'Transformer architecture checkpoints and ONNX runtime integration.',
      ),
      const Channel(
        id: 'ai-voice-test',
        name: 'acoustic-tuning',
        tag: 'DEVELOPMENT',
        description: 'Live spatial sound positioning and reverberation testing.',
        activeVoiceCount: 2,
      ),
    ],
  ),
  Server(
    id: 'flutter-brasil',
    name: 'Flutter & Dart Matrix',
    acronym: 'FLT',
    description: 'Cross-platform native engineering with custom shaders, Impeller, and FFI bindings.',
    category: 'DEV',
    bannerGradient: const LinearGradient(
      colors: [Color(0xFF001A3A), Color(0xFF003F7A), Color(0xFF001124)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    accentColor: AppColors.neonCyan,
    memberCount: 5120,
    onlineCount: 684,
    unreadCount: 5,
    activeVoiceTopic: '#impeller-shaders',
    activeVoiceMembers: ['Matheus', 'Julia Dev', 'Renan'],
    tags: ['#flutter', '#dart', '#impeller', '#desktop'],
    isFavorite: true,
    isTrending: true,
    channels: [
      const Channel(
        id: 'flt-showcase',
        name: 'impeller-shaders',
        tag: 'DEVELOPMENT',
        description: 'Custom GLSL/SkSL shaders and 120hz frame rendering demos.',
        activeVoiceCount: 3,
        hasActiveScreenShare: true,
      ),
      const Channel(
        id: 'flt-help',
        name: 'architecture-help',
        tag: 'DEVELOPMENT',
        description: 'Riverpod 2.0, clean architecture, and platform channel bindings.',
      ),
    ],
  ),
];

final defaultChannelMessages = <String, List<ChatMessage>>{
  'nbx-general-dev': [
    ChatMessage(
      id: 'm1',
      authorName: 'Lucas Dev',
      authorAvatar: 'LD',
      authorRole: 'Core Dev',
      content: 'E aí squad! Subi a nova pipeline do LiveKit SFU com suporte total a Opus DTX e VAD. A telemetria tá impecável!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 32)),
      reactions: {'⚡': 4, '🔥': 3},
    ),
    ChatMessage(
      id: 'm2',
      authorName: 'Gabriel',
      authorAvatar: 'GB',
      authorRole: 'Systems Lead',
      content: 'Fiz os benchmarks de latência no Windows 11 e macOS. Média de 14.8ms com zero jitter. Dá uma olhada no trecho da conexão:',
      timestamp: DateTime.now().subtract(const Duration(minutes: 24)),
      codeLang: 'dart',
      codeSnippet: '''// LiveKit Fast Connect with Adaptive Bitrate
final room = await LiveKitClient.connect(
  url: 'wss://sfu.projectnbx.dev',
  token: jwtToken,
  roomOptions: RoomOptions(
    defaultAudioPublishOptions: AudioPublishOptions(
      dtx: true,
      audioBitrate: 48000,
    ),
  ),
);''',
      reactions: {'🚀': 6, '💻': 5},
    ),
    ChatMessage(
      id: 'm3',
      authorName: 'Taui (Você)',
      authorAvatar: 'TL',
      authorRole: 'Founder / Lead UI',
      content: 'Excelente! Atualizei a interface com o novo Bento-Grid no Dashboard e o Center Stage unificado sem silos de voz/texto. A janela PiP do screenshare já está acoplada e com 60FPS estável!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 8)),
      isCurrentUser: true,
      reactions: {'❤️': 5, '✨': 4},
    ),
  ],
  'nbx-live-showcase': [
    ChatMessage(
      id: 'ls1',
      authorName: 'Lucas Dev',
      authorAvatar: 'LD',
      authorRole: 'Core Dev',
      content: 'Transmitindo a tela com a depuração do renderer de áudio e visualização de pacotes WebRTC!',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ],
  'nbx-announcements': [
    ChatMessage(
      id: 'a1',
      authorName: 'ProjectNBX Bot',
      authorAvatar: '🤖',
      authorRole: 'System',
      content: '🚀 ProjectNBX v1.0 Preview Build liberada! Desfrute de consumo menor que 60MB em Desktop e áudio em tempo real com qualidade de estúdio.',
      timestamp: DateTime.now().subtract(const Duration(hours: 3)),
      reactions: {'🎉': 12, '💎': 8},
    ),
  ],
};

class ServerNotifier extends StateNotifier<ServerState> {
  ServerNotifier()
      : super(
          ServerState(
            servers: richDefaultServers,
            selectedServer: richDefaultServers[0],
            selectedChannel: richDefaultServers[0].channels[1], // 'general-dev'
            channelMessages: defaultChannelMessages,
            viewMode: ViewMode.homeDashboard,
          ),
        );

  void navigateTo(ViewMode mode) {
    state = state.copyWith(viewMode: mode);
  }

  void selectServer(Server server) {
    final firstChannel = server.channels.isNotEmpty ? server.channels.first : state.selectedChannel;
    state = state.copyWith(
      selectedServer: server,
      selectedChannel: firstChannel,
      viewMode: ViewMode.hubWorkspace,
    );
  }

  void selectChannel(Channel channel) {
    state = state.copyWith(selectedChannel: channel);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setCategoryFilter(String category) {
    state = state.copyWith(selectedCategoryFilter: category);
  }

  void toggleCommandPalette([bool? open]) {
    state = state.copyWith(
      showCommandPalette: open ?? !state.showCommandPalette,
    );
  }

  void toggleScreenSharePiPPinned() {
    state = state.copyWith(isScreenSharePiPPinned: !state.isScreenSharePiPPinned);
  }

  void toggleScreenSharePiPExpanded() {
    state = state.copyWith(isScreenSharePiPExpanded: !state.isScreenSharePiPExpanded);
  }

  void toggleScreenSharePiPVisible() {
    state = state.copyWith(isScreenSharePiPVisible: !state.isScreenSharePiPVisible);
  }

  void addReaction(String channelId, String messageId, String emoji) {
    final currentMsgs = state.channelMessages[channelId] ?? [];
    final updatedList = currentMsgs.map((msg) {
      if (msg.id == messageId) {
        final currentReactions = Map<String, int>.from(msg.reactions);
        currentReactions[emoji] = (currentReactions[emoji] ?? 0) + 1;
        return msg.copyWith(reactions: currentReactions);
      }
      return msg;
    }).toList();

    final updatedMap = Map<String, List<ChatMessage>>.from(state.channelMessages);
    updatedMap[channelId] = updatedList;
    state = state.copyWith(channelMessages: updatedMap);
  }

  void sendMessage(String text, {String? codeSnippet, String? codeLang}) {
    if (text.trim().isEmpty && (codeSnippet == null || codeSnippet.trim().isEmpty)) return;

    final channelId = state.selectedChannel.id;
    final currentMsgs = state.channelMessages[channelId] ?? [];

    final newMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorName: 'Taui (Você)',
      authorAvatar: 'TL',
      authorRole: 'Founder / Lead UI',
      content: text.trim(),
      timestamp: DateTime.now(),
      isCurrentUser: true,
      codeSnippet: codeSnippet,
      codeLang: codeLang,
      reactions: {},
    );

    final updatedMap = Map<String, List<ChatMessage>>.from(state.channelMessages);
    updatedMap[channelId] = [...currentMsgs, newMsg];

    state = state.copyWith(channelMessages: updatedMap);
  }
}

final serverProvider = StateNotifierProvider<ServerNotifier, ServerState>((ref) {
  return ServerNotifier();
});
