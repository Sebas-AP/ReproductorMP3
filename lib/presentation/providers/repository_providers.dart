import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reproductor_musica/data/datasources/local/app_database.dart';
import 'package:reproductor_musica/data/repositories/song_repository_impl.dart';
import 'package:reproductor_musica/data/repositories/folder_repository_impl.dart';
import 'package:reproductor_musica/data/repositories/playlist_repository_impl.dart';
import 'package:reproductor_musica/data/repositories/equalizer_repository_impl.dart';
import 'package:reproductor_musica/data/repositories/settings_repository_impl.dart';
import 'package:reproductor_musica/domain/repositories/media_repository.dart';
import 'package:reproductor_musica/data/repositories/database_providers.dart';

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepositoryImpl(ref.watch(songDaoProvider));
});

final folderRepositoryProvider = Provider<FolderRepository>((ref) {
  return FolderRepositoryImpl(ref.watch(folderDaoProvider));
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  return PlaylistRepositoryImpl(ref.watch(playlistDaoProvider));
});

final equalizerRepositoryProvider = Provider<EqualizerRepository>((ref) {
  return EqualizerRepositoryImpl(ref.watch(equalizerPresetDaoProvider));
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepositoryImpl(ref.watch(settingsDaoProvider));
});