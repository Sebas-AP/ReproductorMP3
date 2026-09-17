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
    await requestPermissions();
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
        if (!_isScanning && songs.isNotEmpty && songs.length > 5000) return;

        if (entity is File) {
          final song = await _extractMetadata(entity);
          if (song != null) {
            songs.add(song);
          }
        } else if (entity is Directory) {
          final dirName = p.basename(entity.path);
          // Omitir carpetas ocultas o de sistema
          if (!dirName.startsWith('.')) {
            await _scanDirectory(entity, songs);
          }
        }
      }
    } catch (e) {
      // Ignorar errores de acceso en directorios protegidos
    }
  }

  Future<Song?> _extractMetadata(File file) async {
    final extension = p.extension(file.path).toLowerCase().replaceAll('.', '');
    if (!AppConstants.supportedAudioExtensions.contains(extension)) return null;

    try {
      final name = p.basenameWithoutExtension(file.path);
      String artist = 'Artista desconocido';
      String title = name;

      if (name.contains(' - ')) {
        final parts = name.split(' - ');
        if (parts.length >= 2) {
          artist = parts[0].trim();
          title = parts.sublist(1).join(' - ').trim();
        }
      }

      final stat = await file.stat();

      return Song(
        path: file.path,
        title: title,
        artist: artist,
        album: 'Álbum desconocido',
        duration: 0, // Will be filled on playback
        dateAdded: stat.modified,
      );
    } catch (e) {
      return null;
    }
  }

  /// Escanea una carpeta específica e inserta sus canciones en la base de datos
  Future<int> scanAndSaveSingleFolder(Folder folder) async {
    await requestPermissions();
    _isScanning = true;
    _progressController.add(0.0);

    try {
      final songs = await scanFolder(folder.path);
      int addedCount = 0;

      for (final song in songs) {
        final existing = await songRepository.getSongByPath(song.path);
        if (existing == null) {
          await songRepository.insertSong(song.copyWith(folderId: folder.id));
          addedCount++;
        } else {
          await songRepository.updateSong(existing.copyWith(folderId: folder.id));
        }
      }

      await folderRepository.updateFolder(folder.copyWith(lastScanned: DateTime.now()));
      _progressController.add(1.0);
      return addedCount;
    } finally {
      _isScanning = false;
    }
  }

  @override
  Future<void> scanAllFolders() async {
    if (_isScanning) return;

    await requestPermissions();
    _isScanning = true;
    _progressController.add(0.0);

    try {
      final folders = await folderRepository.getAllFolders(enabledOnly: true);
      int totalScanned = 0;
      int totalFolders = folders.length;

      if (totalFolders == 0) {
        _progressController.add(1.0);
        return;
      }

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

  Future<bool> requestPermissions() async {
    final audioGranted = await Permission.audio.isGranted;
    final storageGranted = await Permission.storage.isGranted;
    final manageGranted = await Permission.manageExternalStorage.isGranted;

    if (audioGranted || storageGranted || manageGranted) {
      return true;
    }

    final statuses = await [
      Permission.audio,
      Permission.storage,
      Permission.manageExternalStorage,
    ].request();

    return statuses[Permission.audio]?.isGranted == true ||
           statuses[Permission.storage]?.isGranted == true ||
           statuses[Permission.manageExternalStorage]?.isGranted == true;
  }

  void dispose() {
    _progressController.close();
    _debounceTimer?.cancel();
  }
}