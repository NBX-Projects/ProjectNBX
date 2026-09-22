import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:projectnbx/features/voice/controllers/audio_settings_controller.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
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
      expect(settings.isPushToTalk, isFalse);
      expect(settings.pttKeyId, LogicalKeyboardKey.capsLock.keyId);
      expect(settings.pttKeyLabel, 'Caps Lock');
    });

    test('copyWith works properly including noise gate properties and PTT', () {
      const settings = AudioSettings();
      final updated = settings.copyWith(
        echoCancellation: false,
        compressorEnabled: false,
        highPassFilter: true,
        autoNoiseGate: false,
        noiseGateThreshold: 0.35,
        noiseGateReleaseMs: 450,
        isPushToTalk: true,
        pttKeyId: LogicalKeyboardKey.space.keyId,
        pttKeyLabel: 'Space',
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
      expect(updated.isPushToTalk, isTrue);
      expect(updated.pttKeyId, LogicalKeyboardKey.space.keyId);
      expect(updated.pttKeyLabel, 'Space');
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

      // Toggle noise gate
      await notifier.setAutoNoiseGate(false);
      expect(notifier.state.autoNoiseGate, isFalse);

      await notifier.setNoiseGateThreshold(0.4);
      expect(notifier.state.noiseGateThreshold, 0.4);

      await notifier.setNoiseGateReleaseMs(500);
      expect(notifier.state.noiseGateReleaseMs, 500);
    });

    test('Noise Gate clamping safeguards values', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = AudioSettingsNotifier();

      await notifier.setNoiseGateThreshold(-0.5);
      expect(notifier.state.noiseGateThreshold, 0.0);

      await notifier.setNoiseGateThreshold(1.5);
      expect(notifier.state.noiseGateThreshold, 1.0);

      await notifier.setNoiseGateReleaseMs(10);
      expect(notifier.state.noiseGateReleaseMs, 50);

      await notifier.setNoiseGateReleaseMs(5000);
      expect(notifier.state.noiseGateReleaseMs, 1000);
    });

    test('Push-to-Talk key setting and Space label formatting', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = AudioSettingsNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await notifier.setPttKey(LogicalKeyboardKey.space);
      expect(notifier.state.pttKeyLabel, 'Space');
      expect(notifier.state.pttKeyId, LogicalKeyboardKey.space.keyId);

      await notifier.setPttKey(LogicalKeyboardKey.keyV);
      expect(notifier.state.pttKeyLabel, 'V');
      expect(notifier.state.pttKeyId, LogicalKeyboardKey.keyV.keyId);
    });

    test('Push-to-Talk toggling automatically mutes mic via container Ref', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();

      final notifier = container.read(audioSettingsProvider.notifier);
      final voiceNotifier = container.read(voiceStateProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(voiceStateProvider).isMicMuted, isFalse);

      // Activating PTT mutes mic immediately
      await notifier.setIsPushToTalk(true);
      expect(notifier.state.isPushToTalk, isTrue);
      expect(container.read(voiceStateProvider).isMicMuted, isTrue);

      // Holding PTT unmutes
      voiceNotifier.setPttPressed(true);
      expect(container.read(voiceStateProvider).isPttPressed, isTrue);
      expect(container.read(voiceStateProvider).isMicMuted, isFalse);

      // Releasing PTT re-mutes
      voiceNotifier.setPttPressed(false);
      expect(container.read(voiceStateProvider).isPttPressed, isFalse);
      expect(container.read(voiceStateProvider).isMicMuted, isTrue);

      // Turning off PTT unmutes
      await notifier.setIsPushToTalk(false);
      expect(notifier.state.isPushToTalk, isFalse);
      expect(container.read(voiceStateProvider).isMicMuted, isFalse);

      container.dispose();
    });

    test('Loads legacy keyId and automatically migrates to valid Caps Lock keyId', () async {
      // Simulates previously saved settings with bad hex
      SharedPreferences.setMockInitialValues({
        'audio_ptt_key_id': 0x00100000014,
        'audio_ptt_key_label': 'Caps Lock',
        'audio_is_push_to_talk': true,
      });

      final notifier = AudioSettingsNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.pttKeyId, LogicalKeyboardKey.capsLock.keyId);
      expect(notifier.state.pttKeyLabel, 'Caps Lock');
    });

    test('Input volume and profile presets work properly', () async {
      SharedPreferences.setMockInitialValues({});
      final notifier = AudioSettingsNotifier();

      await notifier.setInputVolume(0.95);
      expect(notifier.state.inputVolume, 0.95);

      await notifier.applyProfile('estudio');
      expect(notifier.state.inputProfile, 'estudio');
      expect(notifier.state.highPassFilter, isFalse);

      await notifier.applyProfile('isolamento');
      expect(notifier.state.inputProfile, 'isolamento');
      expect(notifier.state.highPassFilter, isTrue);
    });

    test('toAudioCaptureOptions strips Windows SWD prefix and normalizes to lowercase', () {
      const settings = AudioSettings();
      final opts = settings.toAudioCaptureOptions(deviceId: r'SWD\MMDEVAPI\{0.0.1.00000000}.{GUID-TEST}');
      expect(opts.deviceId, '{0.0.1.00000000}.{guid-test}');
    });
  });
}
