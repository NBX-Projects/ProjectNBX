import 'package:flutter_test/flutter_test.dart';
import 'package:projectnbx/features/voice/controllers/audio_settings_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AudioSettings unit tests', () {
    test('Default values are correctly set', () {
      const settings = AudioSettings();
      expect(settings.echoCancellation, isTrue);
      expect(settings.noiseSuppression, isTrue);
      expect(settings.compressorEnabled, isTrue);
      expect(settings.highPassFilter, isFalse);
      expect(settings.typingNoiseDetection, isTrue);
      expect(settings.vadOptimization, isTrue);
      expect(settings.autoNoiseGate, isTrue);
      expect(settings.noiseGateThreshold, 0.15);
      expect(settings.noiseGateReleaseMs, 300);
    });

    test('copyWith works properly including noise gate properties', () {
      const settings = AudioSettings();
      final updated = settings.copyWith(
        echoCancellation: false,
        compressorEnabled: false,
        highPassFilter: true,
        autoNoiseGate: false,
        noiseGateThreshold: 0.35,
        noiseGateReleaseMs: 450,
      );

      expect(updated.echoCancellation, isFalse);
      expect(updated.noiseSuppression, isTrue);
      expect(updated.compressorEnabled, isFalse);
      expect(updated.highPassFilter, isTrue);
      expect(updated.typingNoiseDetection, isTrue);
      expect(updated.vadOptimization, isTrue);
      expect(updated.autoNoiseGate, isFalse);
      expect(updated.noiseGateThreshold, 0.35);
      expect(updated.noiseGateReleaseMs, 450);
    });

    test('toAudioCaptureOptions converts settings accurately', () {
      const settings = AudioSettings(
        echoCancellation: false,
        noiseSuppression: true,
        compressorEnabled: true,
        highPassFilter: true,
        typingNoiseDetection: false,
      );

      final captureDefault = settings.toAudioCaptureOptions(deviceId: 'default');
      expect(captureDefault.deviceId, isNull);
      expect(captureDefault.echoCancellation, isFalse);
      expect(captureDefault.noiseSuppression, isTrue);
      expect(captureDefault.autoGainControl, isTrue);
      expect(captureDefault.highPassFilter, isTrue);
      expect(captureDefault.typingNoiseDetection, isFalse);
      expect(captureDefault.voiceIsolation, isTrue);

      final captureCustom = settings.toAudioCaptureOptions(deviceId: 'usb-mic-123');
      expect(captureCustom.deviceId, 'usb-mic-123');
    });

    // ignore: experimental_member_use
    test('toAudioProcessingOptions converts settings accurately', () {
      const settings = AudioSettings(
        echoCancellation: true,
        noiseSuppression: false,
        compressorEnabled: false,
        highPassFilter: true,
      );

      // ignore: experimental_member_use
      final processing = settings.toAudioProcessingOptions();
      expect(processing.echoCancellation, isTrue);
      expect(processing.noiseSuppression, isFalse);
      expect(processing.autoGainControl, isFalse);
      expect(processing.highPassFilter, isTrue);
    });
  });

  group('AudioSettingsNotifier tests', () {
    test('Toggling settings updates state and saves to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = AudioSettingsNotifier();

      // Wait for initial load
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.echoCancellation, isTrue);
      expect(notifier.state.compressorEnabled, isTrue);
      expect(notifier.state.autoNoiseGate, isTrue);
      expect(notifier.state.noiseGateThreshold, 0.15);

      // Toggle compressor
      await notifier.setCompressorEnabled(false);
      expect(notifier.state.compressorEnabled, isFalse);

      // Toggle echo cancellation
      await notifier.setEchoCancellation(false);
      expect(notifier.state.echoCancellation, isFalse);

      // Toggle noise suppression
      await notifier.setNoiseSuppression(false);
      expect(notifier.state.noiseSuppression, isFalse);

      // Toggle high pass filter
      await notifier.setHighPassFilter(true);
      expect(notifier.state.highPassFilter, isTrue);

      // Toggle typing noise detection
      await notifier.setTypingNoiseDetection(false);
      expect(notifier.state.typingNoiseDetection, isFalse);

      // Toggle VAD optimization
      await notifier.setVadOptimization(false);
      expect(notifier.state.vadOptimization, isFalse);

      // Configure Noise Gate
      await notifier.setAutoNoiseGate(false);
      expect(notifier.state.autoNoiseGate, isFalse);

      await notifier.setNoiseGateThreshold(0.25);
      expect(notifier.state.noiseGateThreshold, 0.25);

      await notifier.setNoiseGateReleaseMs(350);
      expect(notifier.state.noiseGateReleaseMs, 350);

      // Verify SharedPreferences persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('audio_compressor_enabled'), isFalse);
      expect(prefs.getBool('audio_echo_cancellation'), isFalse);
      expect(prefs.getBool('audio_noise_suppression'), isFalse);
      expect(prefs.getBool('audio_high_pass_filter'), isTrue);
      expect(prefs.getBool('audio_typing_noise_detection'), isFalse);
      expect(prefs.getBool('audio_vad_optimization'), isFalse);
      expect(prefs.getBool('audio_auto_noise_gate'), isFalse);
      expect(prefs.getDouble('audio_noise_gate_threshold'), 0.25);
      expect(prefs.getInt('audio_noise_gate_release_ms'), 350);
    });

    test('Noise Gate clamping safeguards values', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = AudioSettingsNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      // Test threshold clamping
      await notifier.setNoiseGateThreshold(-0.5);
      expect(notifier.state.noiseGateThreshold, 0.0);

      await notifier.setNoiseGateThreshold(1.8);
      expect(notifier.state.noiseGateThreshold, 1.0);

      // Test release clamping
      await notifier.setNoiseGateReleaseMs(10);
      expect(notifier.state.noiseGateReleaseMs, 50);

      await notifier.setNoiseGateReleaseMs(2000);
      expect(notifier.state.noiseGateReleaseMs, 1000);
    });
  });
}
