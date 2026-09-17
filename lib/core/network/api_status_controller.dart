import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/features/auth/controllers/auth_controller.dart';

class ApiStatusState {
  final bool isOffline;
  final bool isChecking;
  final int? statusCode;
  final String? errorMessage;
  final DateTime? lastChecked;
  final bool isApiOffline;
  final bool isWsOffline;
  final bool isLiveKitOffline;

  const ApiStatusState({
    this.isOffline = false,
    this.isChecking = false,
    this.statusCode,
    this.errorMessage,
    this.lastChecked,
    this.isApiOffline = false,
    this.isWsOffline = false,
    this.isLiveKitOffline = false,
  });

  String get apiStatusText {
    if (statusCode != null) {
      return '$statusCode Bad Gateway';
    }
    return isOffline ? 'Offline' : 'Operacional';
  }

  String get wsStatusText {
    return isOffline ? 'Desconectado' : 'Conectado';
  }

  String get liveKitStatusText {
    return isOffline ? 'Indisponível' : 'Operacional';
  }

  ApiStatusState copyWith({
    bool? isOffline,
    bool? isChecking,
    int? statusCode,
    String? errorMessage,
    DateTime? lastChecked,
    bool? isApiOffline,
    bool? isWsOffline,
    bool? isLiveKitOffline,
    bool clearError = false,
  }) {
    final offline = isOffline ?? this.isOffline;
    return ApiStatusState(
      isOffline: offline,
      isChecking: isChecking ?? this.isChecking,
      statusCode: clearError ? null : (statusCode ?? this.statusCode),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      lastChecked: lastChecked ?? this.lastChecked,
      isApiOffline: isApiOffline ?? (offline ? true : this.isApiOffline),
      isWsOffline: isWsOffline ?? (offline ? true : this.isWsOffline),
      isLiveKitOffline:
          isLiveKitOffline ?? (offline ? true : this.isLiveKitOffline),
    );
  }
}

class ApiStatusNotifier extends StateNotifier<ApiStatusState> {
  final ApiClient _apiClient;

  ApiStatusNotifier(this._apiClient, {bool autoCheck = true})
      : super(const ApiStatusState()) {
    if (autoCheck &&
        (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST'))) {
      checkStatus();
    }
  }

  void markOffline({String? message, int? statusCode}) {
    if (state.isOffline && state.statusCode == statusCode) return;
    state = state.copyWith(
      isOffline: true,
      isChecking: false,
      statusCode: statusCode,
      errorMessage:
          message ?? 'O servidor da API está temporariamente offline.',
      lastChecked: DateTime.now(),
    );
  }

  void markOnline() {
    if (!state.isOffline && !state.isChecking) return;
    state = state.copyWith(
      isOffline: false,
      isChecking: false,
      clearError: true,
      lastChecked: DateTime.now(),
    );
  }

  Future<bool> checkStatus() async {
    state = state.copyWith(isChecking: true);
    final isHealthy = await _apiClient.checkHealth();
    if (isHealthy) {
      state = state.copyWith(
        isOffline: false,
        isChecking: false,
        clearError: true,
        lastChecked: DateTime.now(),
      );
      return true;
    } else {
      state = state.copyWith(
        isOffline: true,
        isChecking: false,
        errorMessage: 'Não foi possível conectar ao servidor backend.',
        lastChecked: DateTime.now(),
      );
      return false;
    }
  }
}

final apiStatusProvider =
    StateNotifierProvider<ApiStatusNotifier, ApiStatusState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ApiStatusNotifier(apiClient);
});
