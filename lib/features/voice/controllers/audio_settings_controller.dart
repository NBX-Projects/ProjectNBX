// ignore_for_file: experimental_member_use
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioSettings {
  final bool echoCancellation;
  final bool noiseSuppression;
  final bool compressorEnabled;
  final bool highPassFilter;
  final bool typingNoiseDetection;
  final bool vadOptimization;

  // Noise Gate & Input Sensitivity
  final bool autoNoiseGate;
  final double noiseGateThreshold; // 0.0 (very sensitive) to 1.0 (least sensitive)
  final int noiseGateReleaseMs;
  // Volume & Profiles
  final double inputVolume; // 0.0 to 1.0
  final String inputProfile; // 'padrao', 'estudio', 'isolamento'

  // Push to Talk (PTT)
  final bool isPushToTalk;
  final int pttKeyId;
  final String pttKeyLabel;

  const AudioSettings({
    this.echoCancellation = true,
    this.noiseSuppression = true,
    this.compressorEnabled = true,
    this.highPassFilter = false,
    this.typingNoiseDetection = true,
    this.vadOptimization = true,
    this.autoNoiseGate = true,
    this.noiseGateThreshold = 0.15,
    this.noiseGateReleaseMs = 300,
    this.inputVolume = 0.85,
    this.inputProfile = 'padrao',
    this.isPushToTalk = false,
    this.pttKeyId = 0x100000104, // LogicalKeyboardKey.capsLock.keyId
    this.pttKeyLabel = 'Caps Lock',
  });

  AudioSettings copyWith({
    bool? echoCancellation,
    bool? noiseSuppression,
    bool? compressorEnabled,
    bool? highPassFilter,
    bool? typingNoiseDetection,
    bool? vadOptimization,
    bool? autoNoiseGate,
    double? noiseGateThreshold,
    int? noiseGateReleaseMs,
    double? inputVolume,
    String? inputProfile,
    bool? isPushToTalk,
    int? pttKeyId,
    String? pttKeyLabel,
  }) {
    return AudioSettings(
      echoCancellation: echoCancellation ?? this.echoCancellation,
      noiseSuppression: noiseSuppression ?? this.noiseSuppression,
      compressorEnabled: compressorEnabled ?? this.compressorEnabled,
      highPassFilter: highPassFilter ?? this.highPassFilter,
      typingNoiseDetection: typingNoiseDetection ?? this.typingNoiseDetection,
      vadOptimization: vadOptimization ?? this.vadOptimization,
      autoNoiseGate: autoNoiseGate ?? this.autoNoiseGate,
      noiseGateThreshold: noiseGateThreshold ?? this.noiseGateThreshold,
      noiseGateReleaseMs: noiseGateReleaseMs ?? this.noiseGateReleaseMs,
      inputVolume: inputVolume ?? this.inputVolume,
      inputProfile: inputProfile ?? this.inputProfile,
      isPushToTalk: isPushToTalk ?? this.isPushToTalk,
      pttKeyId: pttKeyId ?? this.pttKeyId,
      pttKeyLabel: pttKeyLabel ?? this.pttKeyLabel,
    );
  }

  /// Converte as preferências do usuário no modelo oficial de captura de áudio do LiveKit
  AudioCaptureOptions toAudioCaptureOptions({String? deviceId}) {
    // Normaliza deviceId do Windows (ex: SWD\MMDEVAPI\{...}) para o formato esperado pelo WebRTC nativo
    String? normalizedDeviceId = deviceId;
    if (normalizedDeviceId != null) {
      if (normalizedDeviceId.startsWith(r'SWD\MMDEVAPI\')) {
        normalizedDeviceId =
            normalizedDeviceId.substring(r'SWD\MMDEVAPI\'.length);
      }
      normalizedDeviceId = normalizedDeviceId.toLowerCase();
    }

    return AudioCaptureOptions(
      deviceId: normalizedDeviceId == 'default' ? null : normalizedDeviceId,
      echoCancellation: echoCancellation,
      noiseSuppression: noiseSuppression,
      autoGainControl: compressorEnabled,
      highPassFilter: highPassFilter,
      typingNoiseDetection: typingNoiseDetection,
      voiceIsolation: vadOptimization,
    );
  }

  /// Opções granulares de processamento WebRTC nativo
  AudioProcessingOptions toAudioProcessingOptions() {
    return AudioProcessingOptions(
      echoCancellation: echoCancellation,
      noiseSuppression: noiseSuppression,
      autoGainControl: false,
      highPassFilter: highPassFilter,
    );
  }
}

class AudioSettingsNotifier extends StateNotifier<AudioSettings> {
  final Ref? _ref;

  static const String _keyEchoCancellation = 'audio_echo_cancellation';
  static const String _keyNoiseSuppression = 'audio_noise_suppression';
  static const String _keyCompressor = 'audio_compressor_enabled';
  static const String _keyHighPassFilter = 'audio_high_pass_filter';
  static const String _keyTypingNoiseDetection = 'audio_typing_noise_detection';
  static const String _keyVadOptimization = 'audio_vad_optimization';
  static const String _keyAutoNoiseGate = 'audio_auto_noise_gate';
  static const String _keyNoiseGateThreshold = 'audio_noise_gate_threshold';
  static const String _keyNoiseGateReleaseMs = 'audio_noise_gate_release_ms';
  static const String _keyIsPushToTalk = 'audio_is_push_to_talk';
  static const String _keyPttKeyId = 'audio_ptt_key_id';
  static const String _keyPttKeyLabel = 'audio_ptt_key_label';

  AudioSettingsNotifier([this._ref]) : super(const AudioSettings()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedKeyId = prefs.getInt(_keyPttKeyId);
      final pttKeyId = (savedKeyId == null || savedKeyId == 0x00100000014)
          ? 0x100000104
          : savedKeyId;
      final isPushToTalk = prefs.getBool(_keyIsPushToTalk) ?? false;

      state = state.copyWith(
        echoCancellation: prefs.getBool(_keyEchoCancellation) ?? true,
        noiseSuppression: prefs.getBool(_keyNoiseSuppression) ?? true,
        compressorEnabled: prefs.getBool(_keyCompressor) ?? true,
        highPassFilter: prefs.getBool(_keyHighPassFilter) ?? false,
        typingNoiseDetection: prefs.getBool(_keyTypingNoiseDetection) ?? true,
        vadOptimization: prefs.getBool(_keyVadOptimization) ?? true,
        autoNoiseGate: prefs.getBool(_keyAutoNoiseGate) ?? true,
        noiseGateThreshold: prefs.getDouble(_keyNoiseGateThreshold) ?? 0.15,
        noiseGateReleaseMs: prefs.getInt(_keyNoiseGateReleaseMs) ?? 300,
        isPushToTalk: isPushToTalk,
        pttKeyId: pttKeyId,
        pttKeyLabel: prefs.getString(_keyPttKeyLabel) ?? 'Caps Lock',
      );

      if (isPushToTalk && _ref != null) {
        _ref.read(voiceStateProvider.notifier).setMicMuted(true);
      }
    } catch (_) {}
  }

  Future<void> setIsPushToTalk(bool enabled) async {
    state = state.copyWith(isPushToTalk: enabled);
    await _persistBool(_keyIsPushToTalk, enabled);
    if (_ref != null) {
      if (enabled) {
        _ref.read(voiceStateProvider.notifier).setMicMuted(true);
      } else {
        _ref.read(voiceStateProvider.notifier).setMicMuted(false);
      }
    }
  }

  Future<void> setPttKey(LogicalKeyboardKey key) async {
    final rawLabel = key.keyLabel.trim();
    final label = key == LogicalKeyboardKey.space
        ? 'Space'
        : (rawLabel.isNotEmpty
            ? rawLabel
            : 'Key 0x${key.keyId.toRadixString(16)}');
    state = state.copyWith(
      pttKeyId: key.keyId,
      pttKeyLabel: label,
    );
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyPttKeyId, key.keyId);
      await prefs.setString(_keyPttKeyLabel, label);
    } catch (_) {}
  }

  Future<void> setEchoCancellation(bool enabled) async {
    state = state.copyWith(echoCancellation: enabled);
    await _persistBool(_keyEchoCancellation, enabled);
  }

  Future<void> setNoiseSuppression(bool enabled) async {
    state = state.copyWith(noiseSuppression: enabled);
    await _persistBool(_keyNoiseSuppression, enabled);
  }

  Future<void> setCompressorEnabled(bool enabled) async {
    state = state.copyWith(compressorEnabled: enabled);
    await _persistBool(_keyCompressor, enabled);
  }

  Future<void> setHighPassFilter(bool enabled) async {
    state = state.copyWith(highPassFilter: enabled);
    await _persistBool(_keyHighPassFilter, enabled);
  }

  Future<void> setTypingNoiseDetection(bool enabled) async {
    state = state.copyWith(typingNoiseDetection: enabled);
    await _persistBool(_keyTypingNoiseDetection, enabled);
  }

  Future<void> setVadOptimization(bool enabled) async {
    state = state.copyWith(vadOptimization: enabled);
    await _persistBool(_keyVadOptimization, enabled);
  }

  Future<void> setAutoNoiseGate(bool enabled) async {
    state = state.copyWith(autoNoiseGate: enabled);
    await _persistBool(_keyAutoNoiseGate, enabled);
  }

  Future<void> setNoiseGateThreshold(double threshold) async {
    final clamped = threshold.clamp(0.0, 1.0);
    state = state.copyWith(noiseGateThreshold: clamped);
    await _persistDouble(_keyNoiseGateThreshold, clamped);
  }

  Future<void> setNoiseGateReleaseMs(int releaseMs) async {
    final clamped = releaseMs.clamp(50, 1000);
    state = state.copyWith(noiseGateReleaseMs: clamped);
    await _persistInt(_keyNoiseGateReleaseMs, clamped);
  }

  Future<void> setInputVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    state = state.copyWith(inputVolume: clamped);
    await _persistDouble('audio_input_volume', clamped);
  }

  Future<void> applyProfile(String profileKey) async {
    if (profileKey == 'estudio') {
      // Perfil Estúdio: Som puro sem filtros agressivos (resolve distorções e chiados de IA em microfones USB)
      state = state.copyWith(
        inputProfile: 'estudio',
        echoCancellation: false,
        noiseSuppression: false,
        compressorEnabled: false,
        highPassFilter: false,
        autoNoiseGate: false,
      );
    } else if (profileKey == 'isolamento') {
      // Perfil Isolamento Máximo: Supressão pesada + High Pass + Gate
      state = state.copyWith(
        inputProfile: 'isolamento',
        echoCancellation: true,
        noiseSuppression: true,
        compressorEnabled: true,
        highPassFilter: true,
        autoNoiseGate: true,
      );
    } else {
      // Perfil Padrão: Equilibrado
      state = state.copyWith(
        inputProfile: 'padrao',
        echoCancellation: true,
        noiseSuppression: true,
        compressorEnabled: true,
        highPassFilter: false,
        autoNoiseGate: true,
      );
    }
    await _persistBool(_keyEchoCancellation, state.echoCancellation);
    await _persistBool(_keyNoiseSuppression, state.noiseSuppression);
    await _persistBool(_keyCompressor, state.compressorEnabled);
    await _persistBool(_keyHighPassFilter, state.highPassFilter);
    await _persistBool(_keyAutoNoiseGate, state.autoNoiseGate);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('audio_input_profile', profileKey);
    } catch (_) {}
  }

  Future<void> _persistBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (_) {}
  }

  Future<void> _persistDouble(String key, double value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(key, value);
    } catch (_) {}
  }

  Future<void> _persistInt(String key, int value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, value);
    } catch (_) {}
  }
}

final audioSettingsProvider =
    StateNotifierProvider<AudioSettingsNotifier, AudioSettings>((ref) {
  return AudioSettingsNotifier(ref);
});
