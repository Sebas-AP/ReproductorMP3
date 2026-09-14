import 'dart:async';
import 'package:reproductor_musica/domain/entities/media.dart';
import 'package:reproductor_musica/services/equalizer_native.dart';

class EqualizerService {
  static const List<int> bandFrequencies = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
  static const double minGain = -12.0;
  static const double maxGain = 12.0;

  final List<double> _gains = List.filled(10, 0.0);
  double _preamp = 0.0;
  double _bassBoost = 0.0;
  double _virtualizer = 0.0;
  bool _enabled = false;
  EqualizerPreset? _currentPreset;
  bool _nativeInitialized = false;
  StreamSubscription<EqualizerNativeState>? _nativeStateSub;

  final StreamController<EqualizerState> _stateController = StreamController<EqualizerState>.broadcast();

  Stream<EqualizerState> get stateStream => _stateController.stream;
  EqualizerState get currentState => EqualizerState(
    gains: List.unmodifiable(_gains),
    preamp: _preamp,
    bassBoost: _bassBoost,
    virtualizer: _virtualizer,
    enabled: _enabled,
    currentPreset: _currentPreset,
  );

  bool get isEnabled => _enabled;
  List<double> get gains => List.unmodifiable(_gains);
  double get preamp => _preamp;
  double get bassBoost => _bassBoost;
  double get virtualizer => _virtualizer;
  EqualizerPreset? get currentPreset => _currentPreset;

  Future<void> initialize({int? audioSessionId}) async {
    await _loadSavedState();
    if (audioSessionId != null) {
      await _initializeNative(audioSessionId);
    }
    _emitState();
  }

  Future<void> _initializeNative(int audioSessionId) async {
    try {
      await NativeEqualizer.initialize(audioSessionId);
      _nativeStateSub = NativeEqualizer.stateStream.listen(_onNativeStateChanged);
      _nativeInitialized = true;
      await _syncToNative();
    } catch (e) {
      _nativeInitialized = false;
    }
  }

  void _onNativeStateChanged(EqualizerNativeState state) {
    _gains
      ..clear()
      ..addAll(state.gains);
    _preamp = state.preamp;
    _bassBoost = state.bassBoost;
    _virtualizer = state.virtualizer;
    _enabled = state.enabled;
    _emitState();
  }

  Future<void> _syncToNative() async {
    if (!_nativeInitialized) return;
    for (int i = 0; i < 10; i++) {
      await NativeEqualizer.setGain(i, _gains[i]);
    }
    await NativeEqualizer.setPreamp(_preamp);
    await NativeEqualizer.setBassBoost(_bassBoost);
    await NativeEqualizer.setVirtualizer(_virtualizer);
    await NativeEqualizer.setEnabled(_enabled);
  }

  Future<void> _loadSavedState() async {
    // TODO: Load from SharedPreferences
  }

  Future<void> _saveState() async {
    // TODO: Save to SharedPreferences
  }

  void setGain(int bandIndex, double gain) {
    if (bandIndex < 0 || bandIndex >= 10) return;
    _gains[bandIndex] = gain.clamp(minGain, maxGain);
    _currentPreset = null;
    if (_nativeInitialized) {
      NativeEqualizer.setGain(bandIndex, _gains[bandIndex]);
    }
    _emitState();
  }

  void setPreamp(double gain) {
    _preamp = gain.clamp(minGain, maxGain);
    _currentPreset = null;
    if (_nativeInitialized) {
      NativeEqualizer.setPreamp(_preamp);
    }
    _emitState();
  }

  void setBassBoost(double gain) {
    _bassBoost = gain.clamp(0.0, 12.0);
    if (_nativeInitialized) {
      NativeEqualizer.setBassBoost(_bassBoost);
    }
    _emitState();
  }

  void setVirtualizer(double gain) {
    _virtualizer = gain.clamp(0.0, 10.0);
    if (_nativeInitialized) {
      NativeEqualizer.setVirtualizer(_virtualizer);
    }
    _emitState();
  }

  void setEnabled(bool enabled) {
    _enabled = enabled;
    if (_nativeInitialized) {
      NativeEqualizer.setEnabled(enabled);
    }
    _emitState();
  }

  Future<void> applyPreset(EqualizerPreset preset) async {
    _currentPreset = preset;
    for (int i = 0; i < 10; i++) {
      if (i < preset.bands.length) {
        _gains[i] = preset.bands[i].clamp(minGain, maxGain);
      }
    }
    _preamp = preset.preamp.clamp(minGain, maxGain);
    _bassBoost = preset.bassBoost.clamp(0.0, 12.0);
    _virtualizer = preset.virtualizer.clamp(0.0, 10.0);
    if (_nativeInitialized) {
      await _syncToNative();
    }
    _emitState();
  }

  Future<void> saveAsPreset(String name) async {
    final preset = EqualizerPreset(
      name: name,
      bands: List.from(_gains),
      preamp: _preamp,
      bassBoost: _bassBoost,
      virtualizer: _virtualizer,
      isCustom: true,
    );
    _currentPreset = preset;
    _emitState();
  }

  void reset() {
    for (int i = 0; i < 10; i++) {
      _gains[i] = 0.0;
    }
    _preamp = 0.0;
    _bassBoost = 0.0;
    _virtualizer = 0.0;
    _currentPreset = null;
    if (_nativeInitialized) {
      _syncToNative();
    }
    _emitState();
  }

  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(currentState);
    }
  }

  void dispose() {
    _nativeStateSub?.cancel();
    if (_nativeInitialized) {
      NativeEqualizer.release();
    }
    _stateController.close();
  }
}

class EqualizerState {
  final List<double> gains;
  final double preamp;
  final double bassBoost;
  final double virtualizer;
  final bool enabled;
  final EqualizerPreset? currentPreset;

  const EqualizerState({
    required this.gains,
    required this.preamp,
    required this.bassBoost,
    required this.virtualizer,
    required this.enabled,
    this.currentPreset,
  });
}