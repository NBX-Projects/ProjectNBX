import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:projectnbx/core/network/api_client.dart';
import 'package:projectnbx/core/network/websocket_client.dart';
import 'package:projectnbx/features/voice/controllers/screen_share_controller.dart';
import 'package:projectnbx/features/voice/services/screen_capture_source.dart';
import 'package:projectnbx/features/voice/services/screen_share_transport.dart';

class MockMediaStream extends Fake implements MediaStream {}

class MockScreenCaptureSource implements ScreenCaptureSource {
  bool getSourcesCalled = false;
  bool captureCalled = false;
  bool stopCalled = false;

  @override
  Future<List<ScreenSource>> getSources({bool includeWindows = true}) async {
    getSourcesCalled = true;
    return [
      const ScreenSource(id: 'screen:1', name: 'Monitor 1', isWindow: false),
      const ScreenSource(id: 'window:101', name: 'VS Code', isWindow: true),
    ];
  }

  @override
  Future<MediaStream> capture(ScreenSource source, ScreenQualityProfile profile) async {
    captureCalled = true;
    return MockMediaStream();
  }

  @override
  Future<void> stop(MediaStream stream) async {
    stopCalled = true;
  }
}

class MockScreenShareTransport implements ScreenShareTransport {
  final _remoteStreamController = StreamController<RemoteScreenShare?>.broadcast();
  final _connectionStateController = StreamController<ScreenShareConnectionState>.broadcast();
  final _statsController = StreamController<Map<String, dynamic>>.broadcast();

  bool startBroadcastCalled = false;
  bool stopBroadcastCalled = false;
  bool connectToCalled = false;
  bool disconnectFromCalled = false;

  @override
  Stream<RemoteScreenShare?> get remoteStreamStream => _remoteStreamController.stream;

  @override
  Stream<ScreenShareConnectionState> get connectionStateStream => _connectionStateController.stream;

  @override
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  @override
  Future<ScreenShareSession> startBroadcast({
    required String channelId,
    required MediaStream stream,
    required ScreenQualityProfile profile,
  }) async {
    startBroadcastCalled = true;
    _connectionStateController.add(ScreenShareConnectionState.connected);
    return ScreenShareSession(
      sessionId: 'sess-123',
      channelId: channelId,
      broadcasterId: 'user-host',
      role: ScreenShareRole.broadcaster,
      profile: profile,
      startedAt: DateTime.now(),
    );
  }

  @override
  Future<void> stopBroadcast() async {
    stopBroadcastCalled = true;
    _connectionStateController.add(ScreenShareConnectionState.closed);
  }

  @override
  Future<ScreenShareConnection> connectTo({
    required String sessionId,
    required String broadcasterId,
  }) async {
    connectToCalled = true;
    _connectionStateController.add(ScreenShareConnectionState.connected);
    return ScreenShareConnection(
      sessionId: sessionId,
      peerId: broadcasterId,
      state: ScreenShareConnectionState.connected,
    );
  }

  @override
  Future<void> disconnectFrom({required String sessionId}) async {
    disconnectFromCalled = true;
    _connectionStateController.add(ScreenShareConnectionState.closed);
  }

  @override
  void dispose() {
    _remoteStreamController.close();
    _connectionStateController.close();
    _statsController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockScreenCaptureSource mockCapture;
  late MockScreenShareTransport mockTransport;
  late WebSocketClient mockWsClient;
  late ScreenShareController controller;

  setUp(() {
    mockCapture = MockScreenCaptureSource();
    mockTransport = MockScreenShareTransport();
    mockWsClient = WebSocketClient(ApiClient());

    controller = ScreenShareController(
      captureSource: mockCapture,
      transport: mockTransport,
      wsClient: mockWsClient,
    );
  });

  tearDown(() {
    controller.dispose();
    mockTransport.dispose();
  });

  test('ScreenShareController inicializa com estado padrão', () {
    expect(controller.state.isSharing, false);
    expect(controller.state.isViewing, false);
    expect(controller.state.connectionState, ScreenShareConnectionState.idle);
    expect(controller.state.selectedProfile, ScreenQualityProfile.medium);
  });

  test('loadSources carrega lista de fontes e seleciona a primeira', () async {
    await controller.loadSources();

    expect(mockCapture.getSourcesCalled, true);
    expect(controller.state.availableSources.length, 2);
    expect(controller.state.selectedSource?.id, 'screen:1');
    expect(controller.state.isLoadingSources, false);
  });

  test('selectSource e selectProfile alteram seleções no estado', () {
    const customSource = ScreenSource(id: 'win:2', name: 'Browser', isWindow: true);
    controller.selectSource(customSource);
    expect(controller.state.selectedSource?.id, 'win:2');

    controller.selectProfile(ScreenQualityProfile.high);
    expect(controller.state.selectedProfile.maxFps, 60);
  });

  test('startScreenShare e stopScreenShare alteram estado de transmissão', () async {
    await controller.loadSources();
    final success = await controller.startScreenShare('channel-voice-1');

    expect(success, true);
    expect(mockCapture.captureCalled, true);
    expect(mockTransport.startBroadcastCalled, true);
    expect(controller.state.isSharing, true);
    expect(controller.state.currentSession?.sessionId, 'sess-123');

    await controller.stopScreenShare();
    expect(mockTransport.stopBroadcastCalled, true);
    expect(controller.state.isSharing, false);
  });

  test('joinScreenShare e leaveScreenShare alteram estado de visualização', () async {
    await controller.joinScreenShare('sess-456', 'user-remote-host');

    expect(mockTransport.connectToCalled, true);
    expect(controller.state.isViewing, true);

    await controller.leaveScreenShare();
    expect(mockTransport.disconnectFromCalled, true);
    expect(controller.state.isViewing, false);
  });
}
