import 'dart:async';
import 'package:flutter/services.dart';

class NativeEqualizer {
  static const MethodChannel _channel = MethodChannel('com.reproductor.equalizer');
  static const EventChannel _stateChannel = EventChannel('com.reproductor.equalizer/state');

  static bool _initialized = false;
  static int? _audioSessionId;
  static int? get audioSessionId => _audioSessionId;

  static Future<void> initialize(int audioSessionId) async {
    if (_initialized) return;
    _audioSessionId = audioSessionId;
    await _channel.invokeMethod('init', {'audioSessionId': audioSessionId});
    _initialized = true;
  }

  static Future<void> setGain(int bandIndex, double gain) async {
    if (!_initialized) return;
    await _channel.invokeMethod('setGain', {
      'band': bandIndex,
      'gain': gain,
    });
  }

  static Future<void> setPreamp(double gain) async {
    if (!_initialized) return;
    await _channel.invokeMethod('setPreamp', {'gain': gain});
  }

  static Future<void> setBassBoost(double gain) async {
    if (!_initialized) return;
    await _channel.invokeMethod('setBassBoost', {'gain': gain});
  }

  static Future<void> setVirtualizer(double gain) async {
    if (!_initialized) return;
    await _channel.invokeMethod('setVirtualizer', {'gain': gain});
  }

  static Future<void> setEnabled(bool enabled) async {
    if (!_initialized) return;
    await _channel.invokeMethod('setEnabled', {'enabled': enabled});
  }

  static Future<void> release() async {
    if (!_initialized) return;
    await _channel.invokeMethod('release');
    _initialized = false;
  }

  static Stream<EqualizerNativeState> get stateStream {
    return _stateChannel.receiveBroadcastStream().map((event) {
      return EqualizerNativeState.fromMap(Map<String, dynamic>.from(event));
    });
  }
}

class EqualizerNativeState {
  final List<double> gains;
  final double preamp;
  final double bassBoost;
  final double virtualizer;
  final bool enabled;

  EqualizerNativeState({
    required this.gains,
    required this.preamp,
    required this.bassBoost,
    required this.virtualizer,
    required this.enabled,
  });

  factory EqualizerNativeState.fromMap(Map<String, dynamic> map) {
    return EqualizerNativeState(
      gains: (map['gains'] as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
      preamp: (map['preamp'] as num).toDouble(),
      bassBoost: (map['bassBoost'] as num).toDouble(),
      virtualizer: (map['virtualizer'] as num).toDouble(),
      enabled: map['enabled'] as bool,
    );
  }
}