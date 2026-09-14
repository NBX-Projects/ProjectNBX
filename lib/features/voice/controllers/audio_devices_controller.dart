import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:projectnbx/features/voice/services/audio_hardware_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AudioDevicesState {
  final bool isLoading;
  final List<AudioDeviceInfo> inputDevices;
  final List<AudioDeviceInfo> outputDevices;
  final String? selectedInputDeviceId;
  final String? selectedOutputDeviceId;
  final String? error;

  const AudioDevicesState({
    this.isLoading = false,
    this.inputDevices = const [],
    this.outputDevices = const [],
    this.selectedInputDeviceId,
    this.selectedOutputDeviceId,
    this.error,
  });

  AudioDevicesState copyWith({
    bool? isLoading,
    List<AudioDeviceInfo>? inputDevices,
    List<AudioDeviceInfo>? outputDevices,
    String? selectedInputDeviceId,
    String? selectedOutputDeviceId,
    String? error,
  }) {
    return AudioDevicesState(
      isLoading: isLoading ?? this.isLoading,
      inputDevices: inputDevices ?? this.inputDevices,
      outputDevices: outputDevices ?? this.outputDevices,
      selectedInputDeviceId: selectedInputDeviceId ?? this.selectedInputDeviceId,
      selectedOutputDeviceId: selectedOutputDeviceId ?? this.selectedOutputDeviceId,
      error: error,
    );
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

      final inputs = await _service.getInputDevices();
      final outputs = await _service.getOutputDevices();

      String? activeInputId;
      if (savedInputId != null && inputs.any((d) => d.deviceId == savedInputId)) {
        activeInputId = savedInputId;
      } else if (inputs.isNotEmpty) {
        activeInputId = inputs.first.deviceId;
      }

      String? activeOutputId;
      if (savedOutputId != null && outputs.any((d) => d.deviceId == savedOutputId)) {
        activeOutputId = savedOutputId;
      } else if (outputs.isNotEmpty) {
        activeOutputId = outputs.first.deviceId;
      }

      state = state.copyWith(
        isLoading: false,
        inputDevices: inputs,
        outputDevices: outputs,
        selectedInputDeviceId: activeInputId,
        selectedOutputDeviceId: activeOutputId,
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
