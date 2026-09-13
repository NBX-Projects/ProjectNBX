import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

class LiveKitVoiceService {
  Room? _room;
  EventsListener<RoomEvent>? _listener;

  final _speakingController = StreamController<Map<String, bool>>.broadcast();
  final _participantsController = StreamController<List<Participant>>.broadcast();

  Stream<Map<String, bool>> get onSpeakingChanged => _speakingController.stream;
  Stream<List<Participant>> get onParticipantsChanged => _participantsController.stream;

  bool get isConnected => _room != null && _room!.connectionState == ConnectionState.connected;
  Room? get room => _room;

  Future<bool> connect({
    required String url,
    required String token,
  }) async {
    try {
      await disconnect();

      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioPublishOptions: AudioPublishOptions(
            dtx: true,
          ),
        ),
      );

      _listener = _room!.createListener();

      _listener!
        ..on<RoomConnectedEvent>((event) {
          debugPrint('[LiveKit] Conectado à sala: ${_room?.name}');
          _emitParticipants();
        })
        ..on<ParticipantConnectedEvent>((event) {
          debugPrint('[LiveKit] Participante entrou: ${event.participant.identity}');
          _emitParticipants();
        })
        ..on<ParticipantDisconnectedEvent>((event) {
          debugPrint('[LiveKit] Participante saiu: ${event.participant.identity}');
          _emitParticipants();
        })
        ..on<ActiveSpeakersChangedEvent>((event) {
          final Map<String, bool> speakingMap = {};
          for (final p in event.speakers) {
            speakingMap[p.identity] = true;
          }
          _speakingController.add(speakingMap);
        })
        ..on<TrackSubscribedEvent>((event) {
          _emitParticipants();
        })
        ..on<TrackUnsubscribedEvent>((event) {
          _emitParticipants();
        });

      await _room!.connect(url, token);

      // Habilita microfone local por padrão com VAD
      try {
        await _room!.localParticipant?.setMicrophoneEnabled(true);
      } catch (e) {
        debugPrint('[LiveKit] Não foi possível ativar microfone local de imediato: $e');
      }

      return true;
    } catch (e) {
      debugPrint('[LiveKit] Erro ao conectar na sala LiveKit: $e');
      await disconnect();
      return false;
    }
  }

  Future<void> setMuted(bool muted) async {
    try {
      await _room?.localParticipant?.setMicrophoneEnabled(!muted);
    } catch (e) {
      debugPrint('[LiveKit] Erro ao alterar mudo: $e');
    }
  }

  Future<void> setCameraEnabled(bool enabled) async {
    try {
      await _room?.localParticipant?.setCameraEnabled(enabled);
    } catch (e) {
      debugPrint('[LiveKit] Erro ao alterar câmera: $e');
    }
  }

  Future<void> setScreenShareEnabled(bool enabled) async {
    try {
      await _room?.localParticipant?.setScreenShareEnabled(enabled);
    } catch (e) {
      debugPrint('[LiveKit] Erro ao alterar compartilhamento de tela: $e');
    }
  }

  void _emitParticipants() {
    if (_room == null) return;
    final allParticipants = <Participant>[];
    if (_room!.localParticipant != null) {
      allParticipants.add(_room!.localParticipant!);
    }
    allParticipants.addAll(_room!.remoteParticipants.values);
    _participantsController.add(allParticipants);
  }

  Future<void> disconnect() async {
    try {
      await _listener?.dispose();
      _listener = null;
      await _room?.disconnect();
      await _room?.dispose();
      _room = null;
    } catch (e) {
      debugPrint('[LiveKit] Erro ao desconectar: $e');
    }
  }

  void dispose() {
    disconnect();
    _speakingController.close();
    _participantsController.close();
  }
}
