import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reproductor_musica/data/datasources/local/app_database.dart' hide Song;
import 'package:reproductor_musica/data/repositories/song_repository_impl.dart';
import 'package:reproductor_musica/domain/entities/media.dart';

void main() {
  late AppDatabase db;
  late SongRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SongRepositoryImpl(db.songDao);
  });

  tearDown(() async {
    await db.close();
  });

  group('SongRepository Tests', () {
    test('insertSong and getSongById', () async {
      final now = DateTime.now();
      final song = Song(
        path: '/storage/emulated/0/Music/song1.mp3',
        title: 'Song 1',
        artist: 'Artist 1',
        album: 'Album 1',
        genre: 'Rock',
        duration: 180000,
        dateAdded: now,
      );

      final id = await repository.insertSong(song);
      expect(id, isPositive);

      final fetched = await repository.getSongById(id);
      expect(fetched, isNotNull);
      expect(fetched!.title, 'Song 1');
      expect(fetched.artist, 'Artist 1');
      expect(fetched.album, 'Album 1');
      expect(fetched.genre, 'Rock');
    });

    test('getAllSongs with query search', () async {
      final now = DateTime.now();
      await repository.insertSong(Song(
        path: '/music/trackA.mp3',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        duration: 354000,
        dateAdded: now,
      ));

      await repository.insertSong(Song(
        path: '/music/trackB.mp3',
        title: 'Stairway to Heaven',
        artist: 'Led Zeppelin',
        album: 'Led Zeppelin IV',
        duration: 482000,
        dateAdded: now,
      ));

      final all = await repository.getAllSongs();
      expect(all.length, 2);

      final filtered = await repository.getAllSongs(query: 'Bohemian');
      expect(filtered.length, 1);
      expect(filtered.first.artist, 'Queen');
    });

    test('incrementPlayCount increments play count and sets last played', () async {
      final now = DateTime.now();
      final id = await repository.insertSong(Song(
        path: '/music/stat.mp3',
        title: 'Popular Song',
        artist: 'Hit Maker',
        album: 'Hits',
        duration: 200000,
        dateAdded: now,
        playCount: 0,
      ));

      await repository.incrementPlayCount(id);

      final updated = await repository.getSongById(id);
      expect(updated!.playCount, 1);
      expect(updated.lastPlayed, isNotNull);
    });

    test('deleteSong removes entry', () async {
      final now = DateTime.now();
      final id = await repository.insertSong(Song(
        path: '/music/to_delete.mp3',
        title: 'Delete Me',
        artist: 'Unknown',
        album: 'Trash',
        duration: 100000,
        dateAdded: now,
      ));

      await repository.deleteSong(id);
      final fetched = await repository.getSongById(id);
      expect(fetched, isNull);
    });
  });
}
