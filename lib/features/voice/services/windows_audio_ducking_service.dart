import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WindowsAudioDuckingService {
  static const MethodChannel _channel =
      MethodChannel('com.projectnbx.audio/ducking');

  /// Define se o Windows deve ignorar a atenuação de áudio (ducking)
  /// para a sessão de áudio do ProjectNBX.
  static Future<void> setDuckingOptOut(bool optOut) async {
    if (kIsWeb || !Platform.isWindows) return;

    try {
      await _channel.invokeMethod('setDuckingOptOut', {
        'optOut': optOut,
      });
      debugPrint('[WindowsAudioDucking] Ducking opt-out definido para: $optOut');
    } catch (e) {
      debugPrint('[WindowsAudioDucking] Erro ao configurar ducking opt-out: $e');
    }
  }
}
