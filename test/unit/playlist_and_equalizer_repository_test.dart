import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reproductor_musica/data/datasources/local/app_database.dart' as db;
import 'package:reproductor_musica/data/repositories/equalizer_repository_impl.dart';
import 'package:reproductor_musica/data/repositories/playlist_repository_impl.dart';
import 'package:reproductor_musica/data/repositories/song_repository_impl.dart';
import 'package:reproductor_musica/domain/entities/media.dart' as entity;

void main() {
  late db.AppDatabase database;
  late PlaylistRepositoryImpl playlistRepository;
  late EqualizerRepositoryImpl equalizerRepository;
  late SongRepositoryImpl songRepository;

  setUp(() {
    database = db.AppDatabase.forTesting(NativeDatabase.memory());
    playlistRepository = PlaylistRepositoryImpl(database.playlistDao);
    equalizerRepository = EqualizerRepositoryImpl(database.equalizerPresetDao);
    songRepository = SongRepositoryImpl(database.songDao);
  });

  tearDown(() async {
    await database.close();
  });

  group('PlaylistRepositoryImpl', () {
    test('insert and retrieve playlist', () async {
      final now = DateTime.now();
      final playlist = entity.Playlist(
        name: 'My Rock Favorites',
        createdAt: now,
        updatedAt: now,
      );

      final id = await playlistRepository.insertPlaylist(playlist);
      expect(id, greaterThan(0));

      final fetched = await playlistRepository.getPlaylistById(id);
      expect(fetched, isNotNull);
      expect(fetched!.name, 'My Rock Favorites');
      expect(fetched.isSmart, isFalse);

      final all = await playlistRepository.getAllPlaylists();
      expect(all.length, 1);
      expect(all.first.name, 'My Rock Favorites');
    });

    test('add songs to playlist and retrieve them', () async {
      final now = DateTime.now();
      final pId = await playlistRepository.insertPlaylist(
        entity.Playlist(
          name: 'Party',
          createdAt: now,
          updatedAt: now,
        ),
      );

      final sId = await songRepository.insertSong(
        entity.Song(
          path: '/music/party1.mp3',
          title: 'Party Song',
          artist: 'Artist',
          album: 'Album',
          duration: 180,
          dateAdded: now,
        ),
      );

      await playlistRepository.addSongToPlaylist(pId, sId, 0);
      final count = await playlistRepository.getPlaylistSongCount(pId);
      expect(count, 1);

      final songs = await playlistRepository.getPlaylistSongs(pId);
      expect(songs.length, 1);
      expect(songs.first.title, 'Party Song');

      await playlistRepository.removeSongFromPlaylist(pId, sId);
      final songsAfter = await playlistRepository.getPlaylistSongs(pId);
      expect(songsAfter.isEmpty, isTrue);
    });
  });

  group('EqualizerRepositoryImpl', () {
    test('insert, retrieve and delete custom preset', () async {
      final customPreset = entity.EqualizerPreset(
        name: 'Acoustic Boost',
        bands: [2.0, 1.5, 0.0, 0.0, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5],
        bassBoost: 0.2,
        virtualizer: 0.1,
        isCustom: true,
      );

      final id = await equalizerRepository.insertPreset(customPreset);
      expect(id, greaterThan(0));

      final retrieved = await equalizerRepository.getPresetById(id);
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Acoustic Boost');
      expect(retrieved.bassBoost, 0.2);
      expect(retrieved.bands.length, 10);
      expect(retrieved.bands[0], 2.0);

      await equalizerRepository.deletePreset(id);
      final deleted = await equalizerRepository.getPresetById(id);
      expect(deleted, isNull);
    });
  });
}
