import 'package:reproductor_musica/domain/entities/media.dart';

abstract class SongRepository {
  Future<List<Song>> getAllSongs({String? query, int? limit, int? offset});
  Future<Song?> getSongById(int id);
  Future<Song?> getSongByPath(String path);
  Future<List<Song>> getSongsByArtist(String artist);
  Future<List<Song>> getSongsByAlbum(String album, String artist);
  Future<List<Song>> getSongsByFolder(int folderId);
  Future<List<Song>> getRecentlyAdded({int limit});
  Future<List<Song>> getMostPlayed({int limit});
  Future<List<Song>> getRecentlyPlayed({int limit});
  Future<int> insertSong(Song song);
  Future<bool> updateSong(Song song);
  Future<int> deleteSong(int id);
  Future<void> incrementPlayCount(int songId);
  Future<int> getSongCount();
  Stream<List<Song>> watchAllSongs();
  Future<void> deleteAllSongs();
}

abstract class FolderRepository {
  Future<List<Folder>> getAllFolders({bool enabledOnly});
  Future<Folder?> getFolderById(int id);
  Future<Folder?> getFolderByPath(String path);
  Future<int> insertFolder(Folder folder);
  Future<bool> updateFolder(Folder folder);
  Future<int> deleteFolder(int id);
  Stream<List<Folder>> watchAllFolders();
}

abstract class PlaylistRepository {
  Future<List<Playlist>> getAllPlaylists();
  Future<Playlist?> getPlaylistById(int id);
  Future<int> insertPlaylist(Playlist playlist);
  Future<bool> updatePlaylist(Playlist playlist);
  Future<int> deletePlaylist(int id);
  Future<List<Song>> getPlaylistSongs(int playlistId);
  Future<void> addSongToPlaylist(int playlistId, int songId, int position);
  Future<void> removeSongFromPlaylist(int playlistId, int songId);
  Future<void> reorderPlaylistSongs(int playlistId, List<int> songIds);
  Future<int> getPlaylistSongCount(int playlistId);
  Stream<List<Playlist>> watchAllPlaylists();
}

abstract class EqualizerRepository {
  Future<List<EqualizerPreset>> getAllPresets();
  Future<EqualizerPreset?> getPresetById(int id);
  Future<int> insertPreset(EqualizerPreset preset);
  Future<bool> updatePreset(EqualizerPreset preset);
  Future<int> deletePreset(int id);
}

abstract class SettingsRepository {
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<void> deleteSetting(String key);
  Future<Map<String, String>> getAllSettings();
}

abstract class MediaScannerRepository {
  Future<List<Song>> scanFolder(String folderPath);
  Future<void> scanAllFolders();
  Future<void> cancelScan();
  Stream<double> get scanProgress;
  Future<bool> get isScanning;
}