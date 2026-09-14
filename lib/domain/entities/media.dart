import 'package:equatable/equatable.dart';

class Song extends Equatable {
  final int? id;
  final String path;
  final String title;
  final String artist;
  final String album;
  final String? albumArtist;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? discNumber;
  final int duration;
  final String? artworkPath;
  final DateTime dateAdded;
  final int playCount;
  final DateTime? lastPlayed;
  final int? folderId;

  const Song({
    this.id,
    required this.path,
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist,
    this.genre,
    this.year,
    this.trackNumber,
    this.discNumber,
    required this.duration,
    this.artworkPath,
    required this.dateAdded,
    this.playCount = 0,
    this.lastPlayed,
    this.folderId,
  });

  String get displayTitle => title.isNotEmpty ? title : path.split('/').last;

  String get displayArtist => artist.isNotEmpty ? artist : 'Artista desconocido';

  String get displayAlbum => album.isNotEmpty ? album : 'Álbum desconocido';

  String get durationFormatted {
    final minutes = duration ~/ 60000;
    final seconds = (duration % 60000) ~/ 1000;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  Duration get durationDuration => Duration(milliseconds: duration);

  Song copyWith({
    int? id,
    String? path,
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? genre,
    int? year,
    int? trackNumber,
    int? discNumber,
    int? duration,
    String? artworkPath,
    DateTime? dateAdded,
    int? playCount,
    DateTime? lastPlayed,
    int? folderId,
  }) {
    return Song(
      id: id ?? this.id,
      path: path ?? this.path,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      duration: duration ?? this.duration,
      artworkPath: artworkPath ?? this.artworkPath,
      dateAdded: dateAdded ?? this.dateAdded,
      playCount: playCount ?? this.playCount,
      lastPlayed: lastPlayed ?? this.lastPlayed,
      folderId: folderId ?? this.folderId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        path,
        title,
        artist,
        album,
        albumArtist,
        genre,
        year,
        trackNumber,
        discNumber,
        duration,
        artworkPath,
        dateAdded,
        playCount,
        lastPlayed,
        folderId,
      ];
}

class Artist extends Equatable {
  final String name;
  final int songCount;
  final int albumCount;
  final String? artworkPath;

  const Artist({
    required this.name,
    required this.songCount,
    required this.albumCount,
    this.artworkPath,
  });

  @override
  List<Object?> get props => [name, songCount, albumCount, artworkPath];
}

class Album extends Equatable {
  final int? id;
  final String name;
  final String artist;
  final int songCount;
  final int year;
  final String? artworkPath;
  final String? genre;

  const Album({
    this.id,
    required this.name,
    required this.artist,
    required this.songCount,
    required this.year,
    this.artworkPath,
    this.genre,
  });

  @override
  List<Object?> get props => [id, name, artist, songCount, year, artworkPath, genre];
}

class Playlist extends Equatable {
  final int? id;
  final String name;
  final String? artworkPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSmart;
  final String? smartQuery;
  final int songCount;

  const Playlist({
    this.id,
    required this.name,
    this.artworkPath,
    required this.createdAt,
    required this.updatedAt,
    this.isSmart = false,
    this.smartQuery,
    this.songCount = 0,
  });

  Playlist copyWith({
    int? id,
    String? name,
    String? artworkPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isSmart,
    String? smartQuery,
    int? songCount,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      artworkPath: artworkPath ?? this.artworkPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isSmart: isSmart ?? this.isSmart,
      smartQuery: smartQuery ?? this.smartQuery,
      songCount: songCount ?? this.songCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        artworkPath,
        createdAt,
        updatedAt,
        isSmart,
        smartQuery,
        songCount,
      ];
}

class Folder extends Equatable {
  final int? id;
  final String path;
  final String name;
  final bool isEnabled;
  final DateTime? lastScanned;
  final int songCount;

  const Folder({
    this.id,
    required this.path,
    required this.name,
    this.isEnabled = true,
    this.lastScanned,
    this.songCount = 0,
  });

  Folder copyWith({
    int? id,
    String? path,
    String? name,
    bool? isEnabled,
    DateTime? lastScanned,
    int? songCount,
  }) {
    return Folder(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      isEnabled: isEnabled ?? this.isEnabled,
      lastScanned: lastScanned ?? this.lastScanned,
      songCount: songCount ?? this.songCount,
    );
  }

  @override
  List<Object?> get props => [id, path, name, isEnabled, lastScanned, songCount];
}

class EqualizerPreset extends Equatable {
  final int? id;
  final String name;
  final List<double> bands;
  final double preamp;
  final double bassBoost;
  final double virtualizer;
  final bool isCustom;

  const EqualizerPreset({
    this.id,
    required this.name,
    required this.bands,
    this.preamp = 0.0,
    this.bassBoost = 0.0,
    this.virtualizer = 0.0,
    this.isCustom = true,
  });

  EqualizerPreset copyWith({
    int? id,
    String? name,
    List<double>? bands,
    double? preamp,
    double? bassBoost,
    double? virtualizer,
    bool? isCustom,
  }) {
    return EqualizerPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      bands: bands ?? this.bands,
      preamp: preamp ?? this.preamp,
      bassBoost: bassBoost ?? this.bassBoost,
      virtualizer: virtualizer ?? this.virtualizer,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  @override
  List<Object?> get props => [id, name, bands, preamp, bassBoost, virtualizer, isCustom];
}

enum RepeatMode { off, one, all }
enum ShuffleMode { off, on }

class PlaybackState extends Equatable {
  final Song? currentSong;
  final List<Song> queue;
  final int currentIndex;
  final bool isPlaying;
  final Duration position;
  final Duration bufferedPosition;
  final RepeatMode repeatMode;
  final ShuffleMode shuffleMode;
  final double speed;
  final double volume;
  final bool isLoading;

  const PlaybackState({
    this.currentSong,
    this.queue = const [],
    this.currentIndex = -1,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.bufferedPosition = Duration.zero,
    this.repeatMode = RepeatMode.off,
    this.shuffleMode = ShuffleMode.off,
    this.speed = 1.0,
    this.volume = 1.0,
    this.isLoading = false,
  });

  Song? get nextSong {
    if (queue.isEmpty || currentIndex >= queue.length - 1) return null;
    return queue[currentIndex + 1];
  }

  Song? get previousSong {
    if (queue.isEmpty || currentIndex <= 0) return null;
    return queue[currentIndex - 1];
  }

  double get progress => position.inMilliseconds / duration.inMilliseconds.clamp(1, double.infinity);

  Duration get duration => currentSong?.durationDuration ?? Duration.zero;

  PlaybackState copyWith({
    Song? currentSong,
    List<Song>? queue,
    int? currentIndex,
    bool? isPlaying,
    Duration? position,
    Duration? bufferedPosition,
    RepeatMode? repeatMode,
    ShuffleMode? shuffleMode,
    double? speed,
    double? volume,
    bool? isLoading,
  }) {
    return PlaybackState(
      currentSong: currentSong ?? this.currentSong,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      bufferedPosition: bufferedPosition ?? this.bufferedPosition,
      repeatMode: repeatMode ?? this.repeatMode,
      shuffleMode: shuffleMode ?? this.shuffleMode,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [
        currentSong,
        queue,
        currentIndex,
        isPlaying,
        position,
        bufferedPosition,
        repeatMode,
        shuffleMode,
        speed,
        volume,
        isLoading,
      ];
}

class DynamicColors extends Equatable {
  final Color primary;
  final Color secondary;
  final Color surface;
  final Color onPrimary;
  final Color onSecondary;
  final Color onSurface;
  final Color accent;

  const DynamicColors({
    required this.primary,
    required this.secondary,
    required this.surface,
    required this.onPrimary,
    required this.onSecondary,
    required this.onSurface,
    required this.accent,
  });

  factory DynamicColors.fromImageColors({
    required Color vibrant,
    required Color muted,
    required Color dominant,
    required bool isDark,
  }) {
    final primary = vibrant.computeLuminance() > 0.5 ? vibrant : dominant;
    final secondary = muted.computeLuminance() > 0.3 ? muted : dominant.withOpacity(0.7);
    final surface = isDark
        ? Color.lerp(const Color(0xFF1E293B), dominant.withOpacity(0.15), 0.5)!
        : Color.lerp(Colors.white, dominant.withOpacity(0.1), 0.5)!;
    final onPrimary = primary.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final onSecondary = secondary.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black;
    final accent = dominant;

    return DynamicColors(
      primary: primary,
      secondary: secondary,
      surface: surface,
      onPrimary: onPrimary,
      onSecondary: onSecondary,
      onSurface: onSurface,
      accent: accent,
    );
  }

  DynamicColors lerp(DynamicColors other, double t) {
    return DynamicColors(
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      onSecondary: Color.lerp(onSecondary, other.onSecondary, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
    );
  }

  @override
  List<Object?> get props => [primary, secondary, surface, onPrimary, onSecondary, onSurface, accent];
}

class UserTheme extends Equatable {
  final String? id;
  final String name;
  final int primaryColorValue;
  final int secondaryColorValue;
  final double blurIntensity;
  final double surfaceOpacity;
  final double borderRadius;
  final bool dynamicColors;
  final bool isDark;
  final String? fontFamily;

  const UserTheme({
    this.id,
    required this.name,
    required this.primaryColorValue,
    required this.secondaryColorValue,
    this.blurIntensity = AppTheme.defaultBlurIntensity,
    this.surfaceOpacity = AppTheme.defaultSurfaceOpacity,
    this.borderRadius = AppTheme.defaultBorderRadius,
    this.dynamicColors = true,
    this.isDark = false,
    this.fontFamily,
  });

  Color get primaryColor => Color(primaryColorValue);
  Color get secondaryColor => Color(secondaryColorValue);

  ThemeData toThemeData() {
    return isDark
        ? AppTheme.darkTheme(
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            blurIntensity: blurIntensity,
            surfaceOpacity: surfaceOpacity,
            borderRadius: borderRadius,
          )
        : AppTheme.lightTheme(
            primaryColor: primaryColor,
            secondaryColor: secondaryColor,
            blurIntensity: blurIntensity,
            surfaceOpacity: surfaceOpacity,
            borderRadius: borderRadius,
          );
  }

  UserTheme copyWith({
    String? id,
    String? name,
    int? primaryColorValue,
    int? secondaryColorValue,
    double? blurIntensity,
    double? surfaceOpacity,
    double? borderRadius,
    bool? dynamicColors,
    bool? isDark,
    String? fontFamily,
  }) {
    return UserTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      primaryColorValue: primaryColorValue ?? this.primaryColorValue,
      secondaryColorValue: secondaryColorValue ?? this.secondaryColorValue,
      blurIntensity: blurIntensity ?? this.blurIntensity,
      surfaceOpacity: surfaceOpacity ?? this.surfaceOpacity,
      borderRadius: borderRadius ?? this.borderRadius,
      dynamicColors: dynamicColors ?? this.dynamicColors,
      isDark: isDark ?? this.isDark,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        primaryColorValue,
        secondaryColorValue,
        blurIntensity,
        surfaceOpacity,
        borderRadius,
        dynamicColors,
        isDark,
        fontFamily,
      ];
}