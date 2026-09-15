import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/features/servers/controllers/servers_controller.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ServerModel & ChannelModel tests', () {
    test('ServerModel serialization and copyWith', () {
      const server = ServerModel(
        id: 'srv-1',
        name: 'Alpha Hub',
        ownerId: 'usr-1',
        iconUrl: 'https://example.com/icon.png',
        bannerPreset: 2,
        accentColor: 0xFF2D6A4F,
        category: 'Gaming',
        memberCount: 15,
        channels: [
          ChannelModel(
            id: 'ch-1',
            serverId: 'srv-1',
            name: 'geral',
            type: ChannelType.text,
          ),
        ],
      );

      final json = server.toJson();
      expect(json['id'], 'srv-1');
      expect(json['name'], 'Alpha Hub');
      expect(json['member_count'], 15);

      final restored = ServerModel.fromJson(json);
      expect(restored.id, 'srv-1');
      expect(restored.name, 'Alpha Hub');
      expect(restored.channels.length, 1);
      expect(restored.channels.first.name, 'geral');

      final updated = server.copyWith(name: 'Updated Alpha');
      expect(updated.name, 'Updated Alpha');
      expect(updated.id, 'srv-1');
    });

    test('ChannelModel serialization and copyWith', () {
      const channel = ChannelModel(
        id: 'ch-voice-1',
        serverId: 'srv-1',
        name: 'Voz 1',
        type: ChannelType.voice,
        position: 2,
        unreadCount: 3,
      );

      final json = channel.toJson();
      expect(json['id'], 'ch-voice-1');
      expect(json['type'], 'voice');

      final restored = ChannelModel.fromJson(json);
      expect(restored.id, 'ch-voice-1');
      expect(restored.type, ChannelType.voice);

      final updated = channel.copyWith(name: 'Voz Lounge', unreadCount: 0);
      expect(updated.name, 'Voz Lounge');
      expect(updated.unreadCount, 0);
    });
  });

  group('ServersNotifier state tests', () {
    test('Select server and channel updates state appropriately', () {
      const s1 = ServerModel(
        id: 's1',
        name: 'Server 1',
        ownerId: 'u1',
        channels: [
          ChannelModel(id: 'c1', serverId: 's1', name: 'chat', type: ChannelType.text),
          ChannelModel(id: 'c2', serverId: 's1', name: 'voice', type: ChannelType.voice),
        ],
      );
      const s2 = ServerModel(
        id: 's2',
        name: 'Server 2',
        ownerId: 'u1',
        channels: [
          ChannelModel(id: 'c3', serverId: 's2', name: 'general', type: ChannelType.text),
        ],
      );

      final notifier = ServersNotifier(ApiClient(), autoLoad: false);
      notifier.state = const ServersState(servers: [s1, s2], selectedServerId: 's1', selectedChannelId: 'c1');

      expect(notifier.state.selectedServer?.id, 's1');
      expect(notifier.state.selectedChannel?.id, 'c1');

      // Select channel
      notifier.selectChannel('c2');
      expect(notifier.state.selectedChannelId, 'c2');
      expect(notifier.state.selectedChannel?.name, 'voice');

      // Select server
      notifier.selectServer('s2');
      expect(notifier.state.selectedServerId, 's2');
      expect(notifier.state.selectedChannelId, 'c3');

      // CopyWith with clearError
      final stateWithError = notifier.state.copyWith(error: 'Some error');
      expect(stateWithError.error, 'Some error');

      final clearedState = stateWithError.copyWith(clearError: true);
      expect(clearedState.error, isNull);
    });

    test('updateServerCustomization persists to state and preferences', () async {
      const s1 = ServerModel(id: 's1', name: 'Server 1', ownerId: 'u1');
      final notifier = ServersNotifier(ApiClient(), autoLoad: false);
      notifier.state = const ServersState(servers: [s1]);

      await notifier.updateServerCustomization(
        's1',
        bannerPreset: 3,
        accentColor: 0xFFAABBCC,
        category: 'Tech',
      );

      final updated = notifier.state.servers.first;
      expect(updated.bannerPreset, 3);
      expect(updated.accentColor, 0xFFAABBCC);
      expect(updated.category, 'Tech');
    });

    test('loadServers populates state and applies cached customizations', () async {
      SharedPreferences.setMockInitialValues({
        'server_customization_s1': jsonEncode({
          'bannerPreset': 4,
          'accentColor': 0xFF112233,
          'category': 'DevOps',
        }),
      });

      final fakeApi = FakeServersApiClient();
      final notifier = ServersNotifier(fakeApi, autoLoad: false);
      await notifier.loadServers();

      expect(notifier.state.servers.length, 1);
      final s = notifier.state.servers.first;
      expect(s.id, 's1');
      expect(s.bannerPreset, 4);
      expect(s.accentColor, 0xFF112233);
      expect(s.category, 'DevOps');
      expect(notifier.state.selectedServerId, 's1');
    });

    test('createServer success and error handling', () async {
      final fakeApi = FakeServersApiClient();
      final notifier = ServersNotifier(fakeApi, autoLoad: false);

      final success = await notifier.createServer(
        'Novo Server',
        category: 'Gaming',
        bannerPreset: 1,
        accentColor: 0xFF556677,
      );
      expect(success, isTrue);
      expect(notifier.state.servers.length, 1);
      expect(notifier.state.servers.first.name, 'Novo Server');

      fakeApi.shouldFail = true;
      final failed = await notifier.createServer('Fail Server');
      expect(failed, isFalse);
      expect(notifier.state.error, isNotNull);
    });

    test('joinServer success and error handling', () async {
      final fakeApi = FakeServersApiClient();
      final notifier = ServersNotifier(fakeApi, autoLoad: false);

      final success = await notifier.joinServer('INV-999');
      expect(success, isTrue);
      expect(notifier.state.servers.length, 1);

      fakeApi.shouldFail = true;
      final failed = await notifier.joinServer('INV-FAIL');
      expect(failed, isFalse);
      expect(notifier.state.error, isNotNull);
    });
  });
}

class FakeServersApiClient extends ApiClient {
  bool shouldFail = false;

  @override
  Future<List<Map<String, dynamic>>> getServers() async {
    if (shouldFail) throw Exception('Erro ao listar servidores');
    return [
      {
        'id': 's1',
        'name': 'Servidor Carregado',
        'owner_id': 'u1',
        'channels': [
          {'id': 'c1', 'server_id': 's1', 'name': 'geral', 'type': 'text'}
        ],
      }
    ];
  }

  @override
  Future<Map<String, dynamic>?> createServer(String name, {String? iconUrl}) async {
    if (shouldFail) throw Exception('Falha ao criar servidor');
    return {
      'id': 's-created',
      'name': name,
      'owner_id': 'u1',
      'channels': <dynamic>[],
    };
  }

  @override
  Future<Map<String, dynamic>?> joinServer(String codeOrId) async {
    if (shouldFail) throw Exception('Falha ao entrar no servidor');
    return {
      'id': 's-joined',
      'name': 'Servidor Entrado',
      'owner_id': 'u2',
      'channels': <dynamic>[],
    };
  }
}
