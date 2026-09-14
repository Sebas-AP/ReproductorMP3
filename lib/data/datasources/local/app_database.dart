import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

part 'app_database.g.dart';

class Songs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  TextColumn get title => text().nullable()();
  TextColumn get artist => text().nullable()();
  TextColumn get album => text().nullable()();
  TextColumn get albumArtist => text().nullable()();
  TextColumn get genre => text().nullable()();
  IntColumn get year => integer().nullable()();
  IntColumn get trackNumber => integer().nullable()();
  IntColumn get discNumber => integer().nullable()();
  IntColumn get duration => integer()();
  TextColumn get artworkPath => text().nullable()();
  DateTimeColumn get dateAdded => dateTime()();
  IntColumn get playCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayed => dateTime().nullable()();
  IntColumn get folderId => integer().nullable().references(Folders, #id, onDelete: KeyAction.setNull)();
}

class Folders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get path => text().unique()();
  TextColumn get name => text()();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get lastScanned => dateTime().nullable()();
}

class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get artworkPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isSmart => boolean().withDefault(const Constant(false))();
  TextColumn get smartQuery => text().nullable()();
}

class PlaylistSongs extends Table {
  IntColumn get playlistId => integer().references(Playlists, #id, onDelete: KeyAction.cascade)();
  IntColumn get songId => integer().references(Songs, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {playlistId, songId};
}

class EqualizerPresets extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get bands => text()();
  RealColumn get preamp => real().withDefault(const Constant(0.0))();
  RealColumn get bassBoost => real().withDefault(const Constant(0.0))();
  RealColumn get virtualizer => real().withDefault(const Constant(0.0))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(true))();
}

class Settings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

@DriftDatabase(
  tables: [Songs, Folders, Playlists, PlaylistSongs, EqualizerPresets, Settings],
  daos: [SongDao, FolderDao, PlaylistDao, EqualizerPresetDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertDefaultEqualizerPresets();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Future migrations
      },
    );
  }

  Future<void> _insertDefaultEqualizerPresets() async {
    final defaultPresets = [
      EqualizerPresetsCompanion.insert(
        name: 'Flat',
        bands: '[0,0,0,0,0,0,0,0,0,0]',
        preamp: Value(0.0),
        bassBoost: Value(0.0),
        virtualizer: Value(0.0),
        isCustom: const Value(false),
      ),
      EqualizerPresetsCompanion.insert(
        name: 'Rock',
        bands: '[4,3,2,1,0,-1,-2,-1,0,1]',
        preamp: Value(0.0),
        bassBoost: Value(2.0),
        virtualizer: Value(0.0),
        isCustom: const Value(false),
      ),
      EqualizerPresetsCompanion.insert(
        name: 'Pop',
        bands: '[-1,0,1,2,3,2,1,0,-1,-2]',
        preamp: Value(0.0),
        bassBoost: Value(1.0),
        virtualizer: Value(0.0),
        isCustom: const Value(false),
      ),
      EqualizerPresetsCompanion.insert(
        name: 'Jazz',
        bands: '[3,2,1,0,-1,-2,-1,0,1,2]',
        preamp: Value(0.0),
        bassBoost: Value(0.0),
        virtualizer: Value(3.0),
        isCustom: const Value(false),
      ),
      EqualizerPresetsCompanion.insert(
        name: 'Classical',
        bands: '[0,0,0,0,0,0,0,0,0,0]',
        preamp: Value(0.0),
        bassBoost: Value(0.0),
        virtualizer: Value(2.0),
        isCustom: const Value(false),
      ),
      EqualizerPresetsCompanion.insert(
        name: 'Bass Boost',
        bands: '[6,5,4,3,2,1,0,0,0,0]',
        preamp: Value(0.0),
        bassBoost: Value(6.0),
        virtualizer: Value(0.0),
        isCustom: const Value(false),
      ),
      EqualizerPresetsCompanion.insert(
        name: 'Vocal',
        bands: '[-2,-1,0,1,3,4,3,1,0,-1]',
        preamp: Value(0.0),
        bassBoost: Value(0.0),
        virtualizer: Value(1.0),
        isCustom: const Value(false),
      ),
    ];

    await batch((batch) {
      batch.insertAll(equalizerPresets, defaultPresets);
    });
  }
}

@DriftAccessor(tables: [Songs])
class SongDao extends DatabaseAccessor<AppDatabase> with _$SongDaoMixin {
  SongDao(AppDatabase db) : super(db);

  Future<List<Song>> getAllSongs({String? query, int? limit, int? offset}) {
    final expression = select(songs);
    if (query != null && query.isNotEmpty) {
      expression.where((s) =>
          s.title.like('%$query%') |
          s.artist.like('%$query%') |
          s.album.like('%$query%'));
    }
    expression.orderBy([
      (s) => OrderingTerm.asc(s.artist),
      (s) => OrderingTerm.asc(s.album),
      (s) => OrderingTerm.asc(s.trackNumber),
    ]);
    if (limit != null) expression.limit(limit, offset: offset);
    return expression.get();
  }

  Future<Song?> getSongById(int id) {
    return (select(songs)..where((s) => s.id.equals(id))).getSingleOrNull();
  }

  Future<Song?> getSongByPath(String path) {
    return (select(songs)..where((s) => s.path.equals(path))).getSingleOrNull();
  }

  Future<List<Song>> getSongsByArtist(String artist) {
    return (select(songs)
          ..where((s) => s.artist.equals(artist))
          ..orderBy([
            (s) => OrderingTerm.asc(s.album),
            (s) => OrderingTerm.asc(s.trackNumber),
          ]))
        .get();
  }

  Future<List<Song>> getSongsByAlbum(String album, String artist) {
    return (select(songs)
          ..where((s) => s.album.equals(album) & s.artist.equals(artist))
          ..orderBy([(s) => OrderingTerm.asc(s.trackNumber)]))
        .get();
  }

  Future<List<Song>> getSongsByFolder(int folderId) {
    return (select(songs)
          ..where((s) => s.folderId.equals(folderId))
          ..orderBy([
            (s) => OrderingTerm.asc(s.artist),
            (s) => OrderingTerm.asc(s.album),
            (s) => OrderingTerm.asc(s.trackNumber),
          ]))
        .get();
  }

  Future<List<Song>> getRecentlyAdded({int limit = 20}) {
    return (select(songs)
          ..orderBy([(s) => OrderingTerm.desc(s.dateAdded)])
          ..limit(limit))
        .get();
  }

  Future<List<Song>> getMostPlayed({int limit = 20}) {
    return (select(songs)
          ..orderBy([(s) => OrderingTerm.desc(s.playCount)])
          ..limit(limit))
        .get();
  }

  Future<List<Song>> getRecentlyPlayed({int limit = 20}) {
    return (select(songs)
          ..where((s) => s.lastPlayed.isNotNull())
          ..orderBy([(s) => OrderingTerm.desc(s.lastPlayed)])
          ..limit(limit))
        .get();
  }

  Future<int> insertSong(SongsCompanion song) {
    return into(songs).insert(song);
  }

  Future<bool> updateSong(SongsCompanion song) {
    return update(songs).replace(song);
  }

  Future<int> deleteSong(int id) {
    return (delete(songs)..where((s) => s.id.equals(id))).go();
  }

  Future<void> incrementPlayCount(int songId) {
    return (update(songs)..where((s) => s.id.equals(songId))).write(
      SongsCompanion(
        playCount: Value(songs.playCount + 1),
        lastPlayed: Value(DateTime.now()),
      ),
    );
  }

  Future<int> getSongCount() {
    return selectOnly(songs).map((row) => songs.id.count()).getSingle().then((v) => v.read(songs.id.count()));
  }

  Stream<List<Song>> watchAllSongs() {
    return (select(songs)
          ..orderBy([
            (s) => OrderingTerm.asc(s.artist),
            (s) => OrderingTerm.asc(s.album),
            (s) => OrderingTerm.asc(s.trackNumber),
          ]))
        .watch();
  }

  Future<void> deleteAllSongs() {
    return delete(songs).go();
  }
}

@DriftAccessor(tables: [Folders])
class FolderDao extends DatabaseAccessor<AppDatabase> with _$FolderDaoMixin {
  FolderDao(AppDatabase db) : super(db);

  Future<List<Folder>> getAllFolders({bool? enabledOnly}) {
    final expression = select(folders);
    if (enabledOnly == true) {
      expression.where((f) => f.isEnabled.equals(true));
    }
    expression.orderBy([(f) => OrderingTerm.asc(f.name)]);
    return expression.get();
  }

  Future<Folder?> getFolderById(int id) {
    return (select(folders)..where((f) => f.id.equals(id))).getSingleOrNull();
  }

  Future<Folder?> getFolderByPath(String path) {
    return (select(folders)..where((f) => f.path.equals(path))).getSingleOrNull();
  }

  Future<int> insertFolder(FoldersCompanion folder) {
    return into(folders).insert(folder);
  }

  Future<bool> updateFolder(FoldersCompanion folder) {
    return update(folders).replace(folder);
  }

  Future<int> deleteFolder(int id) {
    return (delete(folders)..where((f) => f.id.equals(id))).go();
  }

  Stream<List<Folder>> watchAllFolders() {
    return (select(folders)..orderBy([(f) => OrderingTerm.asc(f.name)])).watch();
  }
}

@DriftAccessor(tables: [Playlists, PlaylistSongs])
class PlaylistDao extends DatabaseAccessor<AppDatabase> with _$PlaylistDaoMixin {
  PlaylistDao(AppDatabase db) : super(db);

  Future<List<Playlist>> getAllPlaylists() {
    return (select(playlists)..orderBy([(p) => OrderingTerm.desc(p.createdAt)])).get();
  }

  Future<Playlist?> getPlaylistById(int id) {
    return (select(playlists)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertPlaylist(PlaylistsCompanion playlist) {
    return transaction(() async {
      final id = await into(playlists).insert(playlist);
      return id;
    });
  }

  Future<bool> updatePlaylist(PlaylistsCompanion playlist) {
    return update(playlists).replace(playlist);
  }

  Future<int> deletePlaylist(int id) {
    return (delete(playlists)..where((p) => p.id.equals(id))).go();
  }

  Future<List<Song>> getPlaylistSongs(int playlistId) {
    return (select(songs)
          ..join([
            innerJoin(playlistSongs, playlistSongs.songId.equalsExp(songs.id))
          ])
          ..where(playlistSongs.playlistId.equals(playlistId))
          ..orderBy([(s) => OrderingTerm.asc(playlistSongs.position)]))
        .get();
  }

  Future<void> addSongToPlaylist(int playlistId, int songId, int position) {
    await into(playlistSongs).insert(
      PlaylistSongsCompanion(
        playlistId: Value(playlistId),
        songId: Value(songId),
        position: Value(position),
      ),
      onConflict: DoNothing(),
    );
  }

  Future<void> removeSongFromPlaylist(int playlistId, int songId) {
    return (delete(playlistSongs)
          ..where((ps) => ps.playlistId.equals(playlistId) & ps.songId.equals(songId)))
        .go();
  }

  Future<void> reorderPlaylistSongs(int playlistId, List<int> songIds) {
    return transaction(() async {
      for (int i = 0; i < songIds.length; i++) {
        await (update(playlistSongs)
              ..where((ps) => ps.playlistId.equals(playlistId) & ps.songId.equals(songIds[i])))
            .write(PlaylistSongsCompanion(position: Value(i)));
      }
    });
  }

  Future<int> getPlaylistSongCount(int playlistId) {
    return (selectOnly(playlistSongs)
          ..where(playlistSongs.playlistId.equals(playlistId))
          ..map((row) => playlistSongs.songId.count()))
        .getSingle()
        .then((v) => v.read(playlistSongs.songId.count()));
  }

  Stream<List<Playlist>> watchAllPlaylists() {
    return (select(playlists)..orderBy([(p) => OrderingTerm.desc(p.createdAt)])).watch();
  }
}

@DriftAccessor(tables: [EqualizerPresets])
class EqualizerPresetDao extends DatabaseAccessor<AppDatabase> with _$EqualizerPresetDaoMixin {
  EqualizerPresetDao(AppDatabase db) : super(db);

  Future<List<EqualizerPreset>> getAllPresets() {
    return (select(equalizerPresets)..orderBy([(p) => OrderingTerm.asc(p.name)])).get();
  }

  Future<EqualizerPreset?> getPresetById(int id) {
    return (select(equalizerPresets)..where((p) => p.id.equals(id))).getSingleOrNull();
  }

  Future<int> insertPreset(EqualizerPresetsCompanion preset) {
    return into(equalizerPresets).insert(preset);
  }

  Future<bool> updatePreset(EqualizerPresetsCompanion preset) {
    return update(equalizerPresets).replace(preset);
  }

  Future<int> deletePreset(int id) {
    return (delete(equalizerPresets)..where((p) => p.id.equals(id))).go();
  }
}

@DriftAccessor(tables: [Settings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(AppDatabase db) : super(db);

  Future<String?> getSetting(String key) {
    return (select(settings)..where((s) => s.key.equals(key))).getSingleOrNull().then((s) => s?.value);
  }

  Future<void> setSetting(String key, String value) {
    return into(settings).insertOnConflictUpdate(SettingsCompanion(key: Value(key), value: Value(value)));
  }

  Future<void> deleteSetting(String key) {
    return (delete(settings)..where((s) => s.key.equals(key))).go();
  }

  Future<Map<String, String>> getAllSettings() async {
    final rows = await select(settings).get();
    return {for (var r in rows) r.key: r.value};
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'music_player.db'));
    return NativeDatabase.createInBackground(file);
  });
}