import 'package:flutter_test/flutter_test.dart';
import 'package:reproductor_musica/domain/entities/media.dart';

void main() {
  group('Song Entity Tests', () {
    test('Song displayTitle fallback to filename when title is empty', () {
      final song = Song(
        id: 1,
        path: '/storage/emulated/0/Music/track01.mp3',
        title: '',
        artist: '',
        album: '',
        duration: 185000,
        dateAdded: DateTime.now(),
      );

      expect(song.displayTitle, 'track01.mp3');
      expect(song.displayArtist, 'Artista desconocido');
      expect(song.displayAlbum, 'Álbum desconocido');
    });

    test('Song durationFormatted converts milliseconds correctly', () {
      final song = Song(
        id: 2,
        path: '/music/song.mp3',
        title: 'Title',
        artist: 'Artist',
        album: 'Album',
        duration: 215000, // 3 minutes, 35 seconds
        dateAdded: DateTime.now(),
      );

      expect(song.durationFormatted, '3:35');
      expect(song.durationDuration, const Duration(milliseconds: 215000));
    });

    test('Song copyWith preserves existing values', () {
      final now = DateTime.now();
      final song = Song(
        id: 1,
        path: '/path/song.mp3',
        title: 'Original Title',
        artist: 'Original Artist',
        album: 'Original Album',
        duration: 120000,
        dateAdded: now,
        playCount: 5,
      );

      final updated = song.copyWith(playCount: 6, title: 'New Title');

      expect(updated.id, 1);
      expect(updated.path, '/path/song.mp3');
      expect(updated.title, 'New Title');
      expect(updated.artist, 'Original Artist');
      expect(updated.playCount, 6);
    });
  });

  group('PlaybackState Entity Tests', () {
    test('PlaybackState default and copyWith behavior', () {
      const state = PlaybackState();

      expect(state.isPlaying, isFalse);
      expect(state.currentIndex, -1);
      expect(state.repeatMode, RepeatMode.off);
      expect(state.shuffleMode, ShuffleMode.off);
      expect(state.speed, 1.0);
      expect(state.volume, 1.0);

      final playingState = state.copyWith(
        isPlaying: true,
        currentIndex: 0,
        position: const Duration(seconds: 30),
      );

      expect(playingState.isPlaying, isTrue);
      expect(playingState.currentIndex, 0);
      expect(playingState.position, const Duration(seconds: 30));
    });
  });

  group('EqualizerPreset Entity Tests', () {
    test('EqualizerPreset parse bands JSON correctly', () {
      const preset = EqualizerPreset(
        id: 1,
        name: 'Rock',
        bands: [4.0, 3.0, -1.0, 2.0, 3.5, 4.0, 2.0, 1.0, 3.0, 4.0],
        bassBoost: 3.0,
        virtualizer: 2.0,
        isCustom: false,
      );

      expect(preset.name, 'Rock');
      expect(preset.bands.length, 10);
      expect(preset.bands[0], 4.0);
      expect(preset.bassBoost, 3.0);
      expect(preset.isCustom, isFalse);
    });
  });
}
