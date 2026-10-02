import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:justtalking/core/network/api_client.dart';
import 'package:justtalking/core/network/api_offline_exception.dart';
import 'package:justtalking/core/network/api_status_controller.dart';
import 'package:justtalking/core/network/websocket_client.dart';
import 'package:justtalking/features/auth/models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class AuthState {
  final UserModel? user;
  final String? token;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.user,
    this.token,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null && token != null;

  AuthState copyWith({
    UserModel? user,
    String? token,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      user: user ?? this.user,
      token: token ?? this.token,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final Ref? _ref;
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  AuthNotifier(this._apiClient, {Ref? ref, bool restore = true})
      : _ref = ref,
        super(const AuthState()) {
    if (restore) {
      restoreSession();
    }
  }

  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_keyToken);
      final userStr = prefs.getString(_keyUser);

      if (token != null && userStr != null) {
        final userJson = jsonDecode(userStr) as Map<String, dynamic>;
        final user = UserModel.fromJson(userJson);
        _apiClient.setAuthToken(token);
        state = state.copyWith(user: user, token: token);
      }
    } catch (_) {
      // Ignora erro de leitura local
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiClient.login(email, password);
      _apiClient.setAuthToken(res.token);
      _ref?.read(apiStatusProvider.notifier).markOnline();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, res.token);
      await prefs.setString(_keyUser, jsonEncode(res.user.toJson()));

      state = state.copyWith(
        isLoading: false,
        user: res.user,
        token: res.token,
      );
      return true;
    } catch (e) {
      if (e is ApiOfflineException) {
        _ref?.read(apiStatusProvider.notifier).markOffline(
          message: e.message,
          statusCode: e.statusCode,
        );
      }
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> register(
    String username,
    String email,
    String password, {
    String? name,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiClient.register(
        username,
        email,
        password,
        name: name,
      );
      _apiClient.setAuthToken(res.token);
      _ref?.read(apiStatusProvider.notifier).markOnline();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyToken, res.token);
      await prefs.setString(_keyUser, jsonEncode(res.user.toJson()));

      state = state.copyWith(
        isLoading: false,
        user: res.user,
        token: res.token,
      );
      return true;
    } catch (e) {
      if (e is ApiOfflineException) {
        _ref?.read(apiStatusProvider.notifier).markOffline(
          message: e.message,
          statusCode: e.statusCode,
        );
      }
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> updateStatus(String status) async {
    final cleanStatus = status.trim().toLowerCase();
    final user = state.user;
    if (user == null) return false;

    // Atualização otimista imediata no estado
    final updatedUser = user.copyWith(status: cleanStatus);
    state = state.copyWith(user: updatedUser);

    // Persiste imediatamente no SharedPreferences local para nunca resetar
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(updatedUser.toJson()));
    } catch (_) {}

    // Notifica em tempo real via WebSocket para todos os participantes
    try {
      _ref?.read(websocketClientProvider).sendPresence(cleanStatus);
    } catch (_) {}

    // Persiste no backend de forma assíncrona
    try {
      final res = await _apiClient.updateStatus(cleanStatus);
      final syncedUser = res.copyWith(status: cleanStatus);
      state = state.copyWith(user: syncedUser);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(syncedUser.toJson()));
      return true;
    } catch (_) {
      // O estado local e SharedPreferences permanecem válidos mesmo offline
      return false;
    }
  }

  Future<bool> updateProfile({
    String? name,
    String? username,
    String? email,
    String? avatarUrl,
    String? bannerUrl,
    String? bio,
    String? customStatus,
    String? status,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await _apiClient.updateProfile(
        name: name,
        username: username,
        email: email,
        avatarUrl: avatarUrl,
        bannerUrl: bannerUrl,
        bio: bio,
        customStatus: customStatus,
        status: status,
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyUser, jsonEncode(updatedUser.toJson()));

      if (status != null && status.isNotEmpty) {
        try {
          _ref?.read(websocketClientProvider).sendPresence(status);
        } catch (_) {}
      }

      state = state.copyWith(
        isLoading: false,
        user: updatedUser,
      );
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _apiClient.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<void> logout() async {
    _apiClient.setAuthToken(null);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyToken);
      await prefs.remove(_keyUser);
    } catch (_) {}
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient, ref: ref);
});
