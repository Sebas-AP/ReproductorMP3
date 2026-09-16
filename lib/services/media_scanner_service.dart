import 'dart:async';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:reproductor_musica/core/constants/app_constants.dart';
import 'package:reproductor_musica/domain/entities/media.dart';
import 'package:reproductor_musica/domain/repositories/media_repository.dart';

class MediaScannerService implements MediaScannerRepository {
  final SongRepository songRepository;
  final FolderRepository folderRepository;
  final SettingsRepository settingsRepository;

  final StreamController<double> _progressController = StreamController<double>.broadcast();
  bool _isScanning = false;
  Timer? _debounceTimer;

  MediaScannerService({
    required this.songRepository,
    required this.folderRepository,
    required this.settingsRepository,
  });

  @override
  Stream<double> get scanProgress => _progressController.stream;

  @override
  Future<bool> get isScanning async => _isScanning;

  @override
  Future<List<Song>> scanFolder(String folderPath) async {
    final folder = Directory(folderPath);
    if (!await folder.exists()) return [];

    final songs = <Song>[];
    await _scanDirectory(folder, songs);
    return songs;
  }

  Future<void> _scanDirectory(Directory dir, List<Song> songs) async {
    try {
      final entities = await dir.list().toList();
      for (final entity in entities) {
        if (!_isScanning) return;

        if (entity is File) {
          final song = await _extractMetadata(entity);
          if (song != null) {
            songs.add(song);
          }
        } else if (entity is Directory) {
          await _scanDirectory(entity, songs);
        }
      }
    } catch (e) {
      // Ignore permission errors
    }
  }

  Future<Song?> _extractMetadata(File file) async {
    final extension = p.extension(file.path).toLowerCase().replaceAll('.', '');
    if (!AppConstants.supportedAudioExtensions.contains(extension)) return null;

    try {
      // TODO: Use media_metadata_retriever or platform channel for actual metadata
      // For now, create basic song from filename
      final name = p.basenameWithoutExtension(file.path);
      final stat = await file.stat();

      return Song(
        path: file.path,
        title: name,
        artist: 'Artista desconocido',
        album: 'Álbum desconocido',
        duration: 0, // Will be filled by audio player
        dateAdded: stat.modified,
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> scanAllFolders() async {
    if (_isScanning) return;

    _isScanning = true;
    _progressController.add(0.0);

    try {
      final folders = await folderRepository.getAllFolders(enabledOnly: true);
      int totalScanned = 0;
      int totalFolders = folders.length;

      for (final folder in folders) {
        if (!_isScanning) break;

        final songs = await scanFolder(folder.path);
        for (final song in songs) {
          final existing = await songRepository.getSongByPath(song.path);
          if (existing == null) {
            await songRepository.insertSong(song.copyWith(folderId: folder.id));
          } else {
            await songRepository.updateSong(existing.copyWith(folderId: folder.id));
          }
        }

        await folderRepository.updateFolder(folder.copyWith(lastScanned: DateTime.now()));
        totalScanned++;
        _progressController.add(totalScanned / totalFolders);
      }

      await settingsRepository.setSetting(AppConstants.prefsLastScanTime, DateTime.now().toIso8601String());
    } finally {
      _isScanning = false;
      _progressController.add(1.0);
    }
  }

  @override
  Future<void> cancelScan() async {
    _isScanning = false;
  }

  Future<void> requestPermissions() async {
    if (await Permission.storage.isGranted) return;
    if (await Permission.audio.isGranted) return;

    await [
      Permission.storage,
      Permission.audio,
      Permission.manageExternalStorage,
    ].request();
  }

  void dispose() {
    _progressController.close();
    _debounceTimer?.cancel();
  }
}