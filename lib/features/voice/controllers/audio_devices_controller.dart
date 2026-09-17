import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/features/voice/services/audio_hardware_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioDevicesState {
  final bool isLoading;
  final List<AudioDeviceInfo> inputDevices;
  final List<AudioDeviceInfo> outputDevices;
  final String? selectedInputDeviceId;
  final String? selectedOutputDeviceId;
  final String? defaultInputDeviceId;
  final String? defaultOutputDeviceId;
  final String? error;

  const AudioDevicesState({
    this.isLoading = false,
    this.inputDevices = const [],
    this.outputDevices = const [],
    this.selectedInputDeviceId,
    this.selectedOutputDeviceId,
    this.defaultInputDeviceId,
    this.defaultOutputDeviceId,
    this.error,
  });

  AudioDevicesState copyWith({
    bool? isLoading,
    List<AudioDeviceInfo>? inputDevices,
    List<AudioDeviceInfo>? outputDevices,
    String? selectedInputDeviceId,
    String? selectedOutputDeviceId,
    String? defaultInputDeviceId,
    String? defaultOutputDeviceId,
    String? error,
  }) {
    return AudioDevicesState(
      isLoading: isLoading ?? this.isLoading,
      inputDevices: inputDevices ?? this.inputDevices,
      outputDevices: outputDevices ?? this.outputDevices,
      selectedInputDeviceId: selectedInputDeviceId ?? this.selectedInputDeviceId,
      selectedOutputDeviceId: selectedOutputDeviceId ?? this.selectedOutputDeviceId,
      defaultInputDeviceId: defaultInputDeviceId ?? this.defaultInputDeviceId,
      defaultOutputDeviceId: defaultOutputDeviceId ?? this.defaultOutputDeviceId,
      error: error,
    );
  }

  /// Retorna o ID real a ser passado para o WebRTC (resolve 'default' para o microfone padrão detectado)
  String? get effectiveInputDeviceId {
    if (selectedInputDeviceId == null || selectedInputDeviceId == 'default') {
      return defaultInputDeviceId ??
          inputDevices.where((d) => d.deviceId != 'default').firstOrNull?.deviceId;
    }
    return selectedInputDeviceId;
  }

  /// Retorna o ID real a ser passado para o WebRTC (resolve 'default' para a saída padrão detectada)
  String? get effectiveOutputDeviceId {
    if (selectedOutputDeviceId == null || selectedOutputDeviceId == 'default') {
      return defaultOutputDeviceId ??
          outputDevices.where((d) => d.deviceId != 'default').firstOrNull?.deviceId;
    }
    return selectedOutputDeviceId;
  }

  String get selectedInputLabel {
    if (inputDevices.isEmpty) return 'Nenhum microfone encontrado';
    final found = inputDevices.where((d) => d.deviceId == selectedInputDeviceId).firstOrNull;
    if (found != null) return found.label;
    return inputDevices.first.label;
  }

  String get selectedOutputLabel {
    if (outputDevices.isEmpty) return 'Nenhum dispositivo de saída encontrado';
    final found = outputDevices.where((d) => d.deviceId == selectedOutputDeviceId).firstOrNull;
    if (found != null) return found.label;
    return outputDevices.first.label;
  }
}

class AudioDevicesNotifier extends StateNotifier<AudioDevicesState> {
  final AudioHardwareService _service;

  AudioDevicesNotifier(this._service) : super(const AudioDevicesState()) {
    loadDevices();
  }

  Future<void> loadDevices() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedInputId = prefs.getString('preferred_audio_input_id');
      final savedOutputId = prefs.getString('preferred_audio_output_id');

      final snapshot = await _service.getAudioDevicesSnapshot();
      final inputs = snapshot.inputs;
      final outputs = snapshot.outputs;
      final defaultInputId = snapshot.defaultInputId;
      final defaultOutputId = snapshot.defaultOutputId;

      String? cleanId(String? raw) {
        if (raw == null) return null;
        var s = raw;
        if (s.startsWith(r'SWD\MMDEVAPI\')) {
          s = s.substring(r'SWD\MMDEVAPI\'.length);
        }
        return s.trim().toLowerCase();
      }

      final normalizedSavedInput = cleanId(savedInputId);
      final normalizedSavedOutput = cleanId(savedOutputId);

      String? activeInputId;
      if (savedInputId == 'default') {
        activeInputId = 'default';
      } else if (normalizedSavedInput != null && inputs.any((d) => d.deviceId.toLowerCase() == normalizedSavedInput)) {
        activeInputId = inputs.firstWhere((d) => d.deviceId.toLowerCase() == normalizedSavedInput).deviceId;
      } else if (inputs.isNotEmpty) {
        activeInputId = inputs.first.deviceId;
      }

      String? activeOutputId;
      if (savedOutputId == 'default') {
        activeOutputId = 'default';
      } else if (normalizedSavedOutput != null && outputs.any((d) => d.deviceId.toLowerCase() == normalizedSavedOutput)) {
        activeOutputId = outputs.firstWhere((d) => d.deviceId.toLowerCase() == normalizedSavedOutput).deviceId;
      } else if (outputs.isNotEmpty) {
        activeOutputId = outputs.first.deviceId;
      }

      state = state.copyWith(
        isLoading: false,
        inputDevices: inputs,
        outputDevices: outputs,
        selectedInputDeviceId: activeInputId,
        selectedOutputDeviceId: activeOutputId,
        defaultInputDeviceId: defaultInputId,
        defaultOutputDeviceId: defaultOutputId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar dispositivos de áudio: $e',
      );
    }
  }

  Future<void> selectInputDevice(String deviceId) async {
    state = state.copyWith(selectedInputDeviceId: deviceId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_audio_input_id', deviceId);
    } catch (_) {}
  }

  Future<void> selectOutputDevice(String deviceId) async {
    state = state.copyWith(selectedOutputDeviceId: deviceId);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('preferred_audio_output_id', deviceId);
    } catch (_) {}
  }
}

final audioHardwareServiceProvider = Provider<AudioHardwareService>((ref) {
  return const AudioHardwareService();
});

final audioDevicesProvider =
    StateNotifierProvider<AudioDevicesNotifier, AudioDevicesState>((ref) {
  final service = ref.watch(audioHardwareServiceProvider);
  return AudioDevicesNotifier(service);
});
