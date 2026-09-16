// ignore_for_file: experimental_member_use
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
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
  final int noiseGateReleaseMs; // Hangover time in ms before cutting transmission

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
    );
  }

  AudioCaptureOptions toAudioCaptureOptions({String? deviceId}) {
    final effectiveDeviceId = (deviceId != null && deviceId != 'default' && deviceId.isNotEmpty)
        ? deviceId
        : null;

    return AudioCaptureOptions(
      deviceId: effectiveDeviceId,
      echoCancellation: echoCancellation,
      noiseSuppression: noiseSuppression,
      autoGainControl: compressorEnabled,
      highPassFilter: highPassFilter,
      typingNoiseDetection: typingNoiseDetection,
      voiceIsolation: noiseSuppression,
    );
  }

  AudioProcessingOptions toAudioProcessingOptions() {
    return AudioProcessingOptions(
      echoCancellation: echoCancellation,
      noiseSuppression: noiseSuppression,
      autoGainControl: compressorEnabled,
      highPassFilter: highPassFilter,
    );
  }
}

class AudioSettingsNotifier extends StateNotifier<AudioSettings> {
  static const String _keyEchoCancellation = 'audio_echo_cancellation';
  static const String _keyNoiseSuppression = 'audio_noise_suppression';
  static const String _keyCompressor = 'audio_compressor_enabled';
  static const String _keyHighPassFilter = 'audio_high_pass_filter';
  static const String _keyTypingNoiseDetection = 'audio_typing_noise_detection';
  static const String _keyVadOptimization = 'audio_vad_optimization';
  static const String _keyAutoNoiseGate = 'audio_auto_noise_gate';
  static const String _keyNoiseGateThreshold = 'audio_noise_gate_threshold';
  static const String _keyNoiseGateReleaseMs = 'audio_noise_gate_release_ms';

  AudioSettingsNotifier() : super(const AudioSettings()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
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
      );
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
  return AudioSettingsNotifier();
});
