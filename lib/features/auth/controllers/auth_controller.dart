import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';
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
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';

  AuthNotifier(this._apiClient, {bool restore = true})
      : super(const AuthState()) {
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
      final msg = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(isLoading: false, errorMessage: msg);
      return false;
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiClient.register(username, email, password);
      _apiClient.setAuthToken(res.token);

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
  return AuthNotifier(apiClient);
});
