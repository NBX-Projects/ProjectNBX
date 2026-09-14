import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioDeviceInfo {
  final String deviceId;
  final String label;
  final String kind;

  const AudioDeviceInfo({
    required this.deviceId,
    required this.label,
    required this.kind,
  });

  @override
  String toString() => 'AudioDeviceInfo(deviceId: $deviceId, label: $label, kind: $kind)';
}

class AudioHardwareService {
  const AudioHardwareService();

  Future<bool> requestMicrophonePermission() async {
    if (kIsWeb) {
      return true;
    }
    try {
      final status = await Permission.microphone.request();
      return status.isGranted;
    } catch (_) {
      return true;
    }
  }

  Future<List<AudioDeviceInfo>> getInputDevices() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final windowsDevices = await _getWindowsAudioEndpoints(isInput: true);
      if (windowsDevices.isNotEmpty) {
        return windowsDevices;
      }
    }

    try {
      await requestMicrophonePermission();
      final rawDevices = await Hardware.instance.enumerateDevices(type: 'audioinput');
      final list = <AudioDeviceInfo>[
        const AudioDeviceInfo(
          deviceId: 'default',
          label: 'Padrão do Sistema',
          kind: 'audioinput',
        ),
      ];

      for (final d in rawDevices) {
        final id = d.deviceId;
        final label = d.label;
        final kind = d.kind;
        if (id.isNotEmpty && id != 'default') {
          list.add(AudioDeviceInfo(
            deviceId: id,
            label: label.isNotEmpty ? label : 'Microfone (${id.length > 8 ? id.substring(0, 8) : id})',
            kind: kind.isNotEmpty ? kind : 'audioinput',
          ));
        }
      }
      return list;
    } catch (e) {
      debugPrint('[AudioHardwareService] Erro ao listar dispositivos de entrada WebRTC: $e');
      return [
        const AudioDeviceInfo(
          deviceId: 'default',
          label: 'Microfone Padrão do Sistema',
          kind: 'audioinput',
        ),
      ];
    }
  }

  Future<List<AudioDeviceInfo>> getOutputDevices() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final windowsDevices = await _getWindowsAudioEndpoints(isInput: false);
      if (windowsDevices.isNotEmpty) {
        return windowsDevices;
      }
    }

    try {
      final rawDevices = await Hardware.instance.enumerateDevices(type: 'audiooutput');
      final list = <AudioDeviceInfo>[
        const AudioDeviceInfo(
          deviceId: 'default',
          label: 'Padrão do Sistema',
          kind: 'audiooutput',
        ),
      ];

      for (final d in rawDevices) {
        final id = d.deviceId;
        final label = d.label;
        final kind = d.kind;
        if (id.isNotEmpty && id != 'default') {
          list.add(AudioDeviceInfo(
            deviceId: id,
            label: label.isNotEmpty ? label : 'Alto-falante (${id.length > 8 ? id.substring(0, 8) : id})',
            kind: kind.isNotEmpty ? kind : 'audiooutput',
          ));
        }
      }
      return list;
    } catch (e) {
      debugPrint('[AudioHardwareService] Erro ao listar dispositivos de saída WebRTC: $e');
      return [
        const AudioDeviceInfo(
          deviceId: 'default',
          label: 'Alto-falantes Padrão do Sistema',
          kind: 'audiooutput',
        ),
      ];
    }
  }

  Future<List<AudioDeviceInfo>> _getWindowsAudioEndpoints({required bool isInput}) async {
    try {
      // {0.0.1. is Capture (input/mic), {0.0.0. is Render (output/speakers)
      final filterMatch = isInput ? '{0.0.1.' : '{0.0.0.';
      final defaultPrefix = isInput ? 'Padrão do Windows (Microfone)' : 'Padrão do Windows (Alto-falante)';

      final result = await io.Process.run(
        'powershell',
        [
          '-NoProfile',
          '-NonInteractive',
          '-Command',
          r'[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Get-PnpDevice -Class AudioEndpoint -Status OK | ForEach-Object { [PSCustomObject]@{ FriendlyName = $_.FriendlyName; InstanceId = $_.InstanceId } } | ConvertTo-Json -Compress',
        ],
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );

      if (result.exitCode != 0) {
        debugPrint('[AudioHardwareService] PowerShell exitCode: ${result.exitCode}');
        return [];
      }

      final output = (result.stdout as String).trim();
      if (output.isEmpty) return [];

      dynamic decoded;
      try {
        decoded = jsonDecode(output);
      } catch (e) {
        debugPrint('[AudioHardwareService] JSON parse error: $e');
        return [];
      }

      final List<dynamic> items = decoded is List ? decoded : [decoded];
      final devices = <AudioDeviceInfo>[];

      for (final item in items) {
        if (item is Map) {
          final friendlyName = (item['FriendlyName'] ?? '').toString();
          final instanceId = (item['InstanceId'] ?? '').toString();

          if (instanceId.contains(filterMatch) && friendlyName.isNotEmpty) {
            devices.add(AudioDeviceInfo(
              deviceId: instanceId,
              label: friendlyName,
              kind: isInput ? 'audioinput' : 'audiooutput',
            ));
          }
        }
      }

      // Adiciona o item padrão no início com o nome do primeiro dispositivo caso exista
      final firstLabel = devices.isNotEmpty ? ' (${devices.first.label})' : '';
      devices.insert(
        0,
        AudioDeviceInfo(
          deviceId: 'default',
          label: '$defaultPrefix$firstLabel',
          kind: isInput ? 'audioinput' : 'audiooutput',
        ),
      );

      return devices;
    } catch (e) {
      debugPrint('[AudioHardwareService] Erro ao enumerar dispositivos Windows: $e');
      return [];
    }
  }
}
