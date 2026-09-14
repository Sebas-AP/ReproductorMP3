import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reproductor_musica/data/datasources/local/app_database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

final songDaoProvider = Provider<SongDao>((ref) => ref.watch(databaseProvider).songDao);
final folderDaoProvider = Provider<FolderDao>((ref) => ref.watch(databaseProvider).folderDao);
final playlistDaoProvider = Provider<PlaylistDao>((ref) => ref.watch(databaseProvider).playlistDao);
final equalizerPresetDaoProvider = Provider<EqualizerPresetDao>((ref) => ref.watch(databaseProvider).equalizerPresetDao);
final settingsDaoProvider = Provider<SettingsDao>((ref) => ref.watch(databaseProvider).settingsDao);