import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/core/network/api_offline_exception.dart';
import 'package:projectnbx/core/network/api_status_controller.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';
import 'package:projectnbx/features/servers/models/channel_model.dart';
import 'package:projectnbx/features/servers/models/server_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ServersState {
  final List<ServerModel> servers;
  final String? selectedServerId;
  final String? selectedChannelId;
  final bool isLoading;
  final String? error;

  const ServersState({
    this.servers = const [],
    this.selectedServerId,
    this.selectedChannelId,
    this.isLoading = false,
    this.error,
  });

  ServerModel? get selectedServer {
    if (servers.isEmpty) return null;
    if (selectedServerId == null) return servers.first;
    return servers.firstWhere(
      (s) => s.id == selectedServerId,
      orElse: () => servers.first,
    );
  }

  ChannelModel? get selectedChannel {
    final server = selectedServer;
    if (server == null || server.channels.isEmpty) return null;
    if (selectedChannelId == null) return server.channels.first;
    return server.channels.firstWhere(
      (c) => c.id == selectedChannelId,
      orElse: () => server.channels.first,
    );
  }

  ServersState copyWith({
    List<ServerModel>? servers,
    String? selectedServerId,
    String? selectedChannelId,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ServersState(
      servers: servers ?? this.servers,
      selectedServerId: selectedServerId ?? this.selectedServerId,
      selectedChannelId: selectedChannelId ?? this.selectedChannelId,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ServersNotifier extends StateNotifier<ServersState> {
  final ApiClient _apiClient;
  final Ref? _ref;

  ServersNotifier(this._apiClient, {Ref? ref, bool autoLoad = true})
      : _ref = ref,
        super(const ServersState()) {
    if (autoLoad) {
      loadServers();
    }
  }

  Future<void> loadServers() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final rawList = await _apiClient.getServers();
      _ref?.read(apiStatusProvider.notifier).markOnline();
      final prefs = await SharedPreferences.getInstance();

      final parsed = rawList.map((s) {
        final server = ServerModel.fromJson(s);
        final customJson = prefs.getString('server_customization_${server.id}');
        if (customJson != null) {
          try {
            final customMap = Map<String, dynamic>.from(jsonDecode(customJson) as Map);
            return server.copyWith(
              bannerPreset: customMap['bannerPreset'] as int? ?? server.bannerPreset,
              accentColor: customMap['accentColor'] as int? ?? server.accentColor,
              category: customMap['category'] as String? ?? server.category,
            );
          } catch (_) {
            return server;
          }
        }
        return server;
      }).toList();

      state = state.copyWith(
        servers: parsed,
        selectedServerId: parsed.isNotEmpty
            ? (state.selectedServerId ?? parsed.first.id)
            : null,
        selectedChannelId: (parsed.isNotEmpty && parsed.first.channels.isNotEmpty)
            ? (state.selectedChannelId ?? parsed.first.channels.first.id)
            : null,
        isLoading: false,
      );
    } catch (e) {
      if (e is ApiOfflineException) {
        _ref?.read(apiStatusProvider.notifier).markOffline(
          message: e.message,
          statusCode: e.statusCode,
        );
      }
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void selectServer(String serverId) {
    final server = state.servers.firstWhere(
      (s) => s.id == serverId,
      orElse: () => state.servers.first,
    );
    state = state.copyWith(
      selectedServerId: serverId,
      selectedChannelId: server.channels.isNotEmpty
          ? server.channels.first.id
          : null,
    );
  }

  void selectChannel(String channelId) {
    state = state.copyWith(selectedChannelId: channelId);
  }

  Future<void> updateServerCustomization(
    String serverId, {
    int? bannerPreset,
    int? accentColor,
    String? category,
  }) async {
    final updatedServers = state.servers.map((s) {
      if (s.id == serverId) {
        return s.copyWith(
          bannerPreset: bannerPreset ?? s.bannerPreset,
          accentColor: accentColor ?? s.accentColor,
          category: category ?? s.category,
        );
      }
      return s;
    }).toList();

    state = state.copyWith(servers: updatedServers);

    try {
      final prefs = await SharedPreferences.getInstance();
      final customMap = <String, dynamic>{};
      if (bannerPreset != null) {
        customMap['bannerPreset'] = bannerPreset;
      }
      if (accentColor != null) {
        customMap['accentColor'] = accentColor;
      }
      if (category != null) {
        customMap['category'] = category;
      }

      final existingJson = prefs.getString('server_customization_$serverId');
      if (existingJson != null) {
        try {
          final existing = Map<String, dynamic>.from(jsonDecode(existingJson) as Map);
          existing.addAll(customMap);
          await prefs.setString('server_customization_$serverId', jsonEncode(existing));
          return;
        } catch (_) {}
      }
      await prefs.setString('server_customization_$serverId', jsonEncode(customMap));
    } catch (_) {}
  }

  Future<bool> createServer(
    String name, {
    String? iconUrl,
    String? category,
    int? bannerPreset,
    int? accentColor,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiClient.createServer(name, iconUrl: iconUrl);
      if (res != null) {
        var newServer = ServerModel.fromJson(res);
        if (category != null && category.isNotEmpty) {
          newServer = newServer.copyWith(category: category);
        }
        if (bannerPreset != null) {
          newServer = newServer.copyWith(bannerPreset: bannerPreset);
        }
        if (accentColor != null) {
          newServer = newServer.copyWith(accentColor: accentColor);
        }
        final updatedList = [...state.servers, newServer];
        state = state.copyWith(
          servers: updatedList,
          selectedServerId: newServer.id,
          selectedChannelId: newServer.channels.isNotEmpty
              ? newServer.channels.first.id
              : null,
          isLoading: false,
        );
        await updateServerCustomization(
          newServer.id,
          category: category,
          bannerPreset: bannerPreset,
          accentColor: accentColor,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Não foi possível criar o servidor. Tente novamente.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  Future<bool> joinServer(String serverId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiClient.joinServer(serverId.trim());
      if (res != null) {
        final server = ServerModel.fromJson(res);
        final existingIdx = state.servers.indexWhere((s) => s.id == server.id);
        List<ServerModel> updatedList;
        if (existingIdx >= 0) {
          updatedList = [...state.servers];
          updatedList[existingIdx] = server;
        } else {
          updatedList = [...state.servers, server];
        }

        state = state.copyWith(
          servers: updatedList,
          selectedServerId: server.id,
          selectedChannelId: server.channels.isNotEmpty
              ? server.channels.first.id
              : null,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Não foi possível entrar no servidor.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }
}

final serversControllerProvider =
    StateNotifierProvider<ServersNotifier, ServersState>((ref) {
      final apiClient = ref.watch(apiClientProvider);
      return ServersNotifier(apiClient, ref: ref);
    });

