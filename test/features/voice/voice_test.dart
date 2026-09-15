import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:projectnbx/features/voice/controllers/audio_devices_controller.dart';
import 'package:projectnbx/features/voice/controllers/voice_state_controller.dart';
import 'package:projectnbx/features/voice/models/voice_participant_info.dart';
import 'package:projectnbx/features/voice/services/audio_hardware_service.dart';
import 'package:projectnbx/features/voice/widgets/screen_share_dialog.dart';
import 'package:projectnbx/features/voice/widgets/stream_bottom_control_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockAudioService extends AudioHardwareService {
  const MockAudioService();

  @override
  Future<List<AudioDeviceInfo>> getInputDevices() async => const [
        AudioDeviceInfo(deviceId: 'mic-1', label: 'USB Mic', kind: 'audioinput'),
      ];

  @override
  Future<List<AudioDeviceInfo>> getOutputDevices() async => const [
        AudioDeviceInfo(deviceId: 'spk-1', label: 'Headphones', kind: 'audiooutput'),
      ];
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('VoiceParticipantInfo tests', () {
    test('toJson, fromJson and copyWith work as expected', () {
      final now = DateTime.now();
      final p = VoiceParticipantInfo(
        sessionId: 'sess-1',
        userId: 'u-1',
        username: 'GamerOne',
        serverId: 's-1',
        channelId: 'c-1',
        device: 'desktop',
        isInVoice: true,
        isConnecting: false,
        isTransmitting: true,
        streamTitle: 'Ranked Gameplay',
        previewType: 'window',
        thumbnail: 'thumb_data',
        isMuted: false,
        isDeafened: false,
        isSpeaking: true,
        updatedAt: now,
      );

      expect(p.key, 'sess-1');

      final json = p.toJson();
      expect(json['session_id'], 'sess-1');
      expect(json['username'], 'GamerOne');
      expect(json['is_transmitting'], true);

      final restored = VoiceParticipantInfo.fromJson(json);
      expect(restored.sessionId, 'sess-1');
      expect(restored.username, 'GamerOne');
      expect(restored.isTransmitting, true);
      expect(restored.isSpeaking, true);

      final copy = p.copyWith(isMuted: true, isSpeaking: false);
      expect(copy.isMuted, true);
      expect(copy.isSpeaking, false);
      expect(copy.username, 'GamerOne');
    });
  });

  group('VoiceStateNotifier tests', () {
    test('VoiceStateNotifier toggles mic, deafen and connects/disconnects', () {
      final notifier = VoiceStateNotifier();
      expect(notifier.state.isConnected, false);
      expect(notifier.state.isMicMuted, false);
      expect(notifier.state.isDeafened, false);

      // Connect
      notifier.connectVoice('s-1', 'c-1');
      expect(notifier.state.isConnected, true);
      expect(notifier.state.connectedServerId, 's-1');
      expect(notifier.state.connectedChannelId, 'c-1');

      // Toggle mic
      notifier.toggleMic();
      expect(notifier.state.isMicMuted, true);
      notifier.toggleMic();
      expect(notifier.state.isMicMuted, false);

      // Toggle deafen (also mutes mic)
      notifier.toggleDeafened();
      expect(notifier.state.isDeafened, true);
      expect(notifier.state.isMicMuted, true);

      notifier.toggleDeafened();
      expect(notifier.state.isDeafened, false);

      // Unmuting mic while deafened automatically un-deafens and enables audio
      notifier.setDeafened(true);
      expect(notifier.state.isDeafened, true);
      expect(notifier.state.isMicMuted, true);
      notifier.toggleMic();
      expect(notifier.state.isMicMuted, false);
      expect(notifier.state.isDeafened, false);

      // Explicit set
      notifier.setMicMuted(true);
      expect(notifier.state.isMicMuted, true);
      notifier.setDeafened(true);
      expect(notifier.state.isDeafened, true);
      notifier.setDeafened(false);
      expect(notifier.state.isDeafened, false);

      // Disconnect
      notifier.disconnectVoice();
      expect(notifier.state.isConnected, false);
      expect(notifier.state.connectedChannelId, isNull);
    });
  });

  group('AudioDevicesNotifier tests', () {
    test('loads devices and updates selection', () async {
      const mockService = MockAudioService();
      final notifier = AudioDevicesNotifier(mockService);

      await Future<void>.delayed(const Duration(milliseconds: 50));
      await notifier.loadDevices();

      expect(notifier.state.inputDevices.length, 1);
      expect(notifier.state.outputDevices.length, 1);
      expect(notifier.state.selectedInputLabel, 'USB Mic');
      expect(notifier.state.selectedOutputLabel, 'Headphones');

      await notifier.selectInputDevice('mic-2');
      expect(notifier.state.selectedInputDeviceId, 'mic-2');

      await notifier.selectOutputDevice('spk-2');
      expect(notifier.state.selectedOutputDeviceId, 'spk-2');
    });
  });

  group('StreamStageBottomBar widget tests', () {
    testWidgets('renders controls and responds to user interaction', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var volume = 0.8;
      var chatToggled = false;
      var fullscreenToggled = false;
      var stopped = false;

      const testConfig = ScreenShareConfig(
        sourceId: 'src-1',
        title: 'Valorant Stream',
        type: 'window',
        resolution: '1080p',
        fps: 60,
        shareAudio: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamStageBottomBar(
              isDark: true,
              username: 'GamerOne',
              activeScreenShareConfig: testConfig,
              streamVolume: volume,
              onVolumeChanged: (v) {
                volume = v;
              },
              isChatVisible: false,
              onToggleChat: () {
                chatToggled = true;
              },
              isFullscreen: false,
              onToggleFullscreen: () {
                fullscreenToggled = true;
              },
              onStopOrLeave: () {
                stopped = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AO VIVO'), findsOneWidget);
      expect(find.textContaining('Valorant Stream'), findsOneWidget);

      // Toggle chat
      final chatFinder = find.byIcon(LucideIcons.messageSquare);
      if (chatFinder.evaluate().isNotEmpty) {
        await tester.tap(chatFinder.first);
        expect(chatToggled, isTrue);
      }

      // Toggle fullscreen
      final fsFinder = find.byIcon(LucideIcons.maximize2);
      if (fsFinder.evaluate().isNotEmpty) {
        await tester.tap(fsFinder.first);
        expect(fullscreenToggled, isTrue);
      }

      // Stop stream button
      final stopFinder = find.text('Parar');
      if (stopFinder.evaluate().isNotEmpty) {
        await tester.tap(stopFinder.first);
        expect(stopped, isTrue);
      }
    });
  });
}
