import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/features/auth/models/user_model.dart';

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

  AuthNotifier(this._apiClient) : super(const AuthState());

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final res = await _apiClient.login(email, password);
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

  void logout() {
    _apiClient.setAuthToken(null);
    state = const AuthState();
  }
}

final authControllerProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
