import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioDeviceInfo {
  final String deviceId;
  final String label;
  final String kind;
  final bool isDefault;

  const AudioDeviceInfo({
    required this.deviceId,
    required this.label,
    required this.kind,
    this.isDefault = false,
  });

  @override
  String toString() => 'AudioDeviceInfo(deviceId: $deviceId, label: $label, kind: $kind, isDefault: $isDefault)';
}

typedef AudioSnapshot = ({
  List<AudioDeviceInfo> inputs,
  List<AudioDeviceInfo> outputs,
  String? defaultInputId,
  String? defaultOutputId,
});

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

  Future<AudioSnapshot> getAudioDevicesSnapshot() async {
    if (!kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST')) {
      final inputs = await _getGenericInputDevices();
      final outputs = await _getGenericOutputDevices();
      return (
        inputs: inputs,
        outputs: outputs,
        defaultInputId: inputs.where((d) => d.deviceId != 'default').firstOrNull?.deviceId ?? 'default',
        defaultOutputId: outputs.where((d) => d.deviceId != 'default').firstOrNull?.deviceId ?? 'default',
      );
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      final snapshot = await _getWindowsAudioSnapshot();
      if (snapshot.inputs.isNotEmpty || snapshot.outputs.isNotEmpty) {
        return snapshot;
      }
    }

    final inputs = await _getGenericInputDevices();
    final outputs = await _getGenericOutputDevices();
    final defaultIn = inputs.where((d) => d.deviceId != 'default').firstOrNull?.deviceId;
    final defaultOut = outputs.where((d) => d.deviceId != 'default').firstOrNull?.deviceId;

    return (
      inputs: inputs,
      outputs: outputs,
      defaultInputId: defaultIn,
      defaultOutputId: defaultOut,
    );
  }

  Future<List<AudioDeviceInfo>> getInputDevices() async {
    final snapshot = await getAudioDevicesSnapshot();
    return snapshot.inputs;
  }

  Future<List<AudioDeviceInfo>> getOutputDevices() async {
    final snapshot = await getAudioDevicesSnapshot();
    return snapshot.outputs;
  }

  Future<List<AudioDeviceInfo>> _getGenericInputDevices() async {
    if (!kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST')) {
      return const [
        AudioDeviceInfo(
          deviceId: 'default',
          label: 'Microfone Padrão do Sistema',
          kind: 'audioinput',
          isDefault: true,
        ),
      ];
    }
    try {
      await requestMicrophonePermission();
      final rawDevices = await Hardware.instance.enumerateDevices(type: 'audioinput');
      final list = <AudioDeviceInfo>[
        const AudioDeviceInfo(
          deviceId: 'default',
          label: 'Padrão do Sistema',
          kind: 'audioinput',
          isDefault: true,
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
          isDefault: true,
        ),
      ];
    }
  }

  Future<List<AudioDeviceInfo>> _getGenericOutputDevices() async {
    if (!kIsWeb && io.Platform.environment.containsKey('FLUTTER_TEST')) {
      return const [
        AudioDeviceInfo(
          deviceId: 'default',
          label: 'Alto-falantes Padrão do Sistema',
          kind: 'audiooutput',
          isDefault: true,
        ),
      ];
    }
    try {
      final rawDevices = await Hardware.instance.enumerateDevices(type: 'audiooutput');
      final list = <AudioDeviceInfo>[
        const AudioDeviceInfo(
          deviceId: 'default',
          label: 'Padrão do Sistema',
          kind: 'audiooutput',
          isDefault: true,
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
          isDefault: true,
        ),
      ];
    }
  }

  Future<AudioSnapshot> _getWindowsAudioSnapshot() async {
    try {
      final scriptFile = io.File('scripts/get_windows_audio_devices.ps1');
      io.ProcessResult result;
      if (scriptFile.existsSync()) {
        result = await io.Process.run(
          'powershell',
          [
            '-NoProfile',
            '-NonInteractive',
            '-ExecutionPolicy',
            'Bypass',
            '-File',
            scriptFile.absolute.path,
          ],
          stdoutEncoding: utf8,
          stderrEncoding: utf8,
        );
      } else {
        result = await io.Process.run(
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
      }

      if (result.exitCode != 0) {
        debugPrint('[AudioHardwareService] PowerShell exitCode: ${result.exitCode}');
        return (inputs: <AudioDeviceInfo>[], outputs: <AudioDeviceInfo>[], defaultInputId: null, defaultOutputId: null);
      }

      final output = (result.stdout as String).trim();
      if (output.isEmpty) {
        return (inputs: <AudioDeviceInfo>[], outputs: <AudioDeviceInfo>[], defaultInputId: null, defaultOutputId: null);
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(output);
      } catch (e) {
        debugPrint('[AudioHardwareService] JSON parse error: $e');
        return (inputs: <AudioDeviceInfo>[], outputs: <AudioDeviceInfo>[], defaultInputId: null, defaultOutputId: null);
      }

      final inputs = <AudioDeviceInfo>[];
      final outputs = <AudioDeviceInfo>[];
      String? defaultInputId;
      String? defaultOutputId;

      if (decoded is Map<String, dynamic> && decoded.containsKey('inputs')) {
        defaultInputId = (decoded['defaultInput'] as String?)?.toLowerCase();
        defaultOutputId = (decoded['defaultOutput'] as String?)?.toLowerCase();

        final rawInputs = (decoded['inputs'] as List?) ?? [];
        for (final item in rawInputs) {
          if (item is Map) {
            final id = (item['deviceId'] ?? '').toString().toLowerCase();
            final label = (item['label'] ?? '').toString();
            final isDef = item['isDefault'] == true;
            if (id.isNotEmpty && label.isNotEmpty) {
              inputs.add(AudioDeviceInfo(
                deviceId: id,
                label: label,
                kind: 'audioinput',
                isDefault: isDef,
              ));
            }
          }
        }

        final rawOutputs = (decoded['outputs'] as List?) ?? [];
        for (final item in rawOutputs) {
          if (item is Map) {
            final id = (item['deviceId'] ?? '').toString().toLowerCase();
            final label = (item['label'] ?? '').toString();
            final isDef = item['isDefault'] == true;
            if (id.isNotEmpty && label.isNotEmpty) {
              outputs.add(AudioDeviceInfo(
                deviceId: id,
                label: label,
                kind: 'audiooutput',
                isDefault: isDef,
              ));
            }
          }
        }
      } else {
        // Fallback para lista plana caso o script retorne apenas lista de PnpDevices
        final List<dynamic> items = decoded is List ? decoded : [decoded];
        for (final item in items) {
          if (item is Map) {
            final friendlyName = (item['FriendlyName'] ?? '').toString();
            var instanceId = (item['InstanceId'] ?? '').toString().toLowerCase();
            if (instanceId.startsWith(r'swd\mmdevapi\')) {
              instanceId = instanceId.substring(r'swd\mmdevapi\'.length);
            }
            if (friendlyName.isNotEmpty) {
              if (instanceId.contains('{0.0.1.')) {
                inputs.add(AudioDeviceInfo(deviceId: instanceId, label: friendlyName, kind: 'audioinput'));
              } else if (instanceId.contains('{0.0.0.')) {
                outputs.add(AudioDeviceInfo(deviceId: instanceId, label: friendlyName, kind: 'audiooutput'));
              }
            }
          }
        }
        defaultInputId = inputs.firstOrNull?.deviceId;
        defaultOutputId = outputs.firstOrNull?.deviceId;
      }

      // Adiciona a opção virtual "Padrão" no início de cada lista
      final firstInputLabel = inputs.isNotEmpty ? ' (${inputs.first.label})' : '';
      inputs.insert(
        0,
        AudioDeviceInfo(
          deviceId: 'default',
          label: 'Padrão do Windows (Microfone)$firstInputLabel',
          kind: 'audioinput',
          isDefault: true,
        ),
      );

      final firstOutputLabel = outputs.isNotEmpty ? ' (${outputs.first.label})' : '';
      outputs.insert(
        0,
        AudioDeviceInfo(
          deviceId: 'default',
          label: 'Padrão do Windows (Alto-falante)$firstOutputLabel',
          kind: 'audiooutput',
          isDefault: true,
        ),
      );

      return (
        inputs: inputs,
        outputs: outputs,
        defaultInputId: defaultInputId ?? inputs.where((d) => d.deviceId != 'default').firstOrNull?.deviceId,
        defaultOutputId: defaultOutputId ?? outputs.where((d) => d.deviceId != 'default').firstOrNull?.deviceId,
      );
    } catch (e) {
      debugPrint('[AudioHardwareService] Erro ao enumerar dispositivos Windows: $e');
      return (inputs: <AudioDeviceInfo>[], outputs: <AudioDeviceInfo>[], defaultInputId: null, defaultOutputId: null);
    }
  }
}
