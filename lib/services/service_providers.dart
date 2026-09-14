import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reproductor_musica/services/audio_service.dart';
import 'package:reproductor_musica/services/equalizer_service.dart';
import 'package:reproductor_musica/services/media_scanner_service.dart';
import 'package:reproductor_musica/data/repositories/repository_providers.dart';

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(() => service.dispose());
  return service;
});

final equalizerServiceProvider = Provider<EqualizerService>((ref) {
  final service = EqualizerService();
  ref.onDispose(() => service.dispose());
  return service;
});

final mediaScannerProvider = Provider<MediaScannerService>((ref) {
  return MediaScannerService(
    songRepository: ref.watch(songRepositoryProvider),
    folderRepository: ref.watch(folderRepositoryProvider),
    settingsRepository: ref.watch(settingsRepositoryProvider),
  );
});

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final audioService = ref.watch(audioServiceProvider);
  return audioService.stateStream;
});

final equalizerStateProvider = StreamProvider<EqualizerState>((ref) {
  final equalizerService = ref.watch(equalizerServiceProvider);
  return equalizerService.stateStream;
});

final scanProgressProvider = StreamProvider<double>((ref) {
  final scanner = ref.watch(mediaScannerProvider);
  return scanner.scanProgress;
});

final isScanningProvider = FutureProvider<bool>((ref) {
  final scanner = ref.watch(mediaScannerProvider);
  return scanner.isScanning;
});