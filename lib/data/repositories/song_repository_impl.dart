import 'package:reproductor_musica/data/datasources/local/app_database.dart' as db;
import 'package:reproductor_musica/domain/entities/media.dart';
import 'package:reproductor_musica/domain/repositories/media_repository.dart';

class SongRepositoryImpl implements SongRepository {
  final db.SongDao _dao;

  SongRepositoryImpl(this._dao);

  @override
  Future<List<Song>> getAllSongs({String? query, int? limit, int? offset}) async {
    final dbSongs = await _dao.getAllSongs(query: query, limit: limit, offset: offset);
    return dbSongs.map(_toEntity).toList();
  }

  @override
  Future<Song?> getSongById(int id) async {
    final dbSong = await _dao.getSongById(id);
    return dbSong != null ? _toEntity(dbSong) : null;
  }

  @override
  Future<Song?> getSongByPath(String path) async {
    final dbSong = await _dao.getSongByPath(path);
    return dbSong != null ? _toEntity(dbSong) : null;
  }

  @override
  Future<List<Song>> getSongsByArtist(String artist) async {
    final dbSongs = await _dao.getSongsByArtist(artist);
    return dbSongs.map(_toEntity).toList();
  }

  @override
  Future<List<Song>> getSongsByAlbum(String album, String artist) async {
    final dbSongs = await _dao.getSongsByAlbum(album, artist);
    return dbSongs.map(_toEntity).toList();
  }

  @override
  Future<List<Song>> getSongsByFolder(int folderId) async {
    final dbSongs = await _dao.getSongsByFolder(folderId);
    return dbSongs.map(_toEntity).toList();
  }

  @override
  Future<List<Song>> getRecentlyAdded({int limit = 20}) async {
    final dbSongs = await _dao.getRecentlyAdded(limit: limit);
    return dbSongs.map(_toEntity).toList();
  }

  @override
  Future<List<Song>> getMostPlayed({int limit = 20}) async {
    final dbSongs = await _dao.getMostPlayed(limit: limit);
    return dbSongs.map(_toEntity).toList();
  }

  @override
  Future<List<Song>> getRecentlyPlayed({int limit = 20}) async {
    final dbSongs = await _dao.getRecentlyPlayed(limit: limit);
    return dbSongs.map(_toEntity).toList();
  }

  @override
  Future<int> insertSong(Song song) {
    return _dao.insertSong(_toCompanion(song));
  }

  @override
  Future<bool> updateSong(Song song) {
    return _dao.updateSong(_toCompanion(song));
  }

  @override
  Future<int> deleteSong(int id) {
    return _dao.deleteSong(id);
  }

  @override
  Future<void> incrementPlayCount(int songId) {
    return _dao.incrementPlayCount(songId);
  }

  @override
  Future<int> getSongCount() {
    return _dao.getSongCount();
  }

  @override
  Stream<List<Song>> watchAllSongs() {
    return _dao.watchAllSongs().map((list) => list.map(_toEntity).toList());
  }

  @override
  Future<void> deleteAllSongs() {
    return _dao.deleteAllSongs();
  }

  Song _toEntity(db.Song song) {
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

  db.SongsCompanion _toCompanion(Song song) {
    return db.SongsCompanion(
      id: song.id != null ? Value(song.id!) : const Value.absent(),
      path: Value(song.path),
      title: Value(song.title),
      artist: Value(song.artist),
      album: Value(song.album),
      albumArtist: Value(song.albumArtist),
      genre: Value(song.genre),
      year: Value(song.year),
      trackNumber: Value(song.trackNumber),
      discNumber: Value(song.discNumber),
      duration: Value(song.duration),
      artworkPath: Value(song.artworkPath),
      dateAdded: Value(song.dateAdded),
      playCount: Value(song.playCount),
      lastPlayed: Value(song.lastPlayed),
      folderId: Value(song.folderId),
    );
  }
}