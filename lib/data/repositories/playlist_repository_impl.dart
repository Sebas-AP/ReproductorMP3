import 'package:reproductor_musica/data/datasources/local/app_database.dart' as db;
import 'package:reproductor_musica/domain/entities/media.dart';
import 'package:reproductor_musica/domain/repositories/media_repository.dart';
import 'package:drift/drift.dart';

class PlaylistRepositoryImpl implements PlaylistRepository {
  final db.PlaylistDao _dao;

  PlaylistRepositoryImpl(this._dao);

  @override
  Future<List<Playlist>> getAllPlaylists() async {
    final dbPlaylists = await _dao.getAllPlaylists();
    return dbPlaylists.map(_toEntity).toList();
  }

  @override
  Future<Playlist?> getPlaylistById(int id) async {
    final dbPlaylist = await _dao.getPlaylistById(id);
    return dbPlaylist != null ? _toEntity(dbPlaylist) : null;
  }

  @override
  Future<int> insertPlaylist(Playlist playlist) {
    return _dao.insertPlaylist(_toCompanion(playlist));
  }

  @override
  Future<bool> updatePlaylist(Playlist playlist) {
    return _dao.updatePlaylist(_toCompanion(playlist.copyWith(updatedAt: DateTime.now())));
  }

  @override
  Future<int> deletePlaylist(int id) {
    return _dao.deletePlaylist(id);
  }

  @override
  Future<List<Song>> getPlaylistSongs(int playlistId) async {
    final dbSongs = await _dao.getPlaylistSongs(playlistId);
    return dbSongs.map(_songToEntity).toList();
  }

  @override
  Future<void> addSongToPlaylist(int playlistId, int songId, int position) {
    return _dao.addSongToPlaylist(playlistId, songId, position);
  }

  @override
  Future<void> removeSongFromPlaylist(int playlistId, int songId) {
    return _dao.removeSongFromPlaylist(playlistId, songId);
  }

  @override
  Future<void> reorderPlaylistSongs(int playlistId, List<int> songIds) {
    return _dao.reorderPlaylistSongs(playlistId, songIds);
  }

  @override
  Future<int> getPlaylistSongCount(int playlistId) {
    return _dao.getPlaylistSongCount(playlistId);
  }

  @override
  Stream<List<Playlist>> watchAllPlaylists() {
    return _dao.watchAllPlaylists().map((list) => list.map(_toEntity).toList());
  }

  Playlist _toEntity(db.Playlist playlist) {
    return Playlist(
      id: playlist.id,
      name: playlist.name,
      artworkPath: playlist.artworkPath,
      createdAt: playlist.createdAt,
      updatedAt: playlist.updatedAt,
      isSmart: playlist.isSmart,
      smartQuery: playlist.smartQuery,
    );
  }

  Song _songToEntity(db.Song song) {
    return Song(
      id: song.id,
      path: song.path,
      title: song.title ?? '',
      artist: song.artist ?? '',
      album: song.album ?? '',
      albumArtist: song.albumArtist,
      genre: song.genre,
      year: song.year,
      trackNumber: song.trackNumber,
      discNumber: song.discNumber,
      duration: song.duration,
      artworkPath: song.artworkPath,
      dateAdded: song.dateAdded,
      playCount: song.playCount,
      lastPlayed: song.lastPlayed,
      folderId: song.folderId,
    );
  }

  db.PlaylistsCompanion _toCompanion(Playlist playlist) {
    return db.PlaylistsCompanion(
      id: playlist.id != null ? Value(playlist.id!) : const Value.absent(),
      name: Value(playlist.name),
      artworkPath: Value(playlist.artworkPath),
      createdAt: Value(playlist.createdAt),
      updatedAt: Value(playlist.updatedAt),
      isSmart: Value(playlist.isSmart),
      smartQuery: Value(playlist.smartQuery),
    );
  }
}