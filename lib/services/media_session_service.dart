import 'dart:async';
import 'package:audio_service/audio_service.dart' as audio_service;
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:reproductor_musica/domain/entities/media.dart';
import 'package:reproductor_musica/services/equalizer_service.dart';

class MediaSessionService {
  static final MediaSessionService _instance = MediaSessionService._internal();
  factory MediaSessionService() => _instance;
  MediaSessionService._internal();

  AudioPlayer? _audioPlayer;
  audio_service.AudioHandler? _audioHandler;
  StreamSubscription<PlaybackState>? _playbackStateSub;
  StreamSubscription<int?>? _indexSub;
  bool _initialized = false;

  Future<void> initialize({
    required AudioPlayer audioPlayer,
    required EqualizerService equalizerService,
  }) async {
    if (_initialized) return;

    _audioPlayer = audioPlayer;

    _audioHandler = await audio_service.AudioService.init(
      () => _AudioPlayerHandler(
        audioPlayer: audioPlayer,
        equalizerService: equalizerService,
      ),
      config: const audio_service.AudioServiceConfig(
        androidNotificationChannelId: 'com.reproductor.musica.audio',
        androidNotificationChannelName: 'Reproducción de música',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
        androidResumeOnClick: true,
        androidNotificationIcon: 'mipmap/ic_launcher',
      ),
    );

    _setupListeners();
    _initialized = true;
  }

  void _setupListeners() {
    final player = _audioPlayer!;
    final handler = _audioHandler!;

    _playbackStateSub = player.playerStateStream.listen((state) {
      handler.playbackState.add(audio_service.PlaybackState(
        controls: [
          audio_service.MediaControl.rewind,
          if (state.playing) audio_service.MediaControl.pause else audio_service.MediaControl.play,
          audio_service.MediaControl.stop,
          audio_service.MediaControl.fastForward,
        ],
        systemActions: const {
          audio_service.MediaAction.seek,
          audio_service.MediaAction.seekForward,
          audio_service.MediaAction.seekBackward,
          audio_service.MediaAction.skipToNext,
          audio_service.MediaAction.skipToPrevious,
          audio_service.MediaAction.stop,
        },
        androidCompactActions: const [0, 1, 3],
        processingState: _mapProcessingState(player.processingState),
        playing: state.playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
        queueIndex: player.currentIndex,
      ));
    });

    _indexSub = player.currentIndexStream.listen((index) {
      if (index != null && index < (player.sequence?.length ?? 0)) {
        final source = player.sequence![index];
        final mediaItem = source.tag as MediaItem?;
        if (mediaItem != null) {
          handler.mediaItem.add(mediaItem);
        }
      } else {
        handler.mediaItem.add(null);
      }
    });
  }

  audio_service.AudioProcessingState _mapProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return audio_service.AudioProcessingState.idle;
      case ProcessingState.loading:
        return audio_service.AudioProcessingState.loading;
      case ProcessingState.buffering:
        return audio_service.AudioProcessingState.buffering;
      case ProcessingState.ready:
        return audio_service.AudioProcessingState.ready;
      case ProcessingState.completed:
        return audio_service.AudioProcessingState.completed;
      case ProcessingState.error:
        return audio_service.AudioProcessingState.error;
    }
  }

  Future<void> updateQueue(List<Song> songs, {int startIndex = 0}) async {
    final children = songs.map((song) => AudioSource.uri(
      Uri.parse(song.path),
      tag: MediaItem(
        id: song.id.toString(),
        title: song.displayTitle,
        artist: song.displayArtist,
        album: song.displayAlbum,
        artUri: song.artworkPath != null ? Uri.parse(song.artworkPath!) : null,
        duration: song.durationDuration,
      ),
    )).toList();

    final mediaItems = children.map((c) => c.tag as MediaItem).toList();
    await _audioHandler!.queue.add(mediaItems);
    await _audioPlayer!.setAudioSource(ConcatenatingAudioSource(children: children), initialIndex: startIndex);
  }

  Future<void> play() => _audioHandler!.play();
  Future<void> pause() => _audioHandler!.pause();
  Future<void> stop() => _audioHandler!.stop();
  Future<void> seekTo(Duration position) => _audioHandler!.seek(position);
  Future<void> skipToNext() => _audioHandler!.skipToNext();
  Future<void> skipToPrevious() => _audioHandler!.skipToPrevious();
  Future<void> setSpeed(double speed) => _audioHandler!.setSpeed(speed);
  Future<void> setVolume(double volume) => _audioPlayer!.setVolume(volume);
  Future<void> setRepeatMode(audio_service.AudioServiceRepeatMode mode) => _audioHandler!.setRepeatMode(mode);
  Future<void> setShuffleMode(audio_service.AudioServiceShuffleMode mode) => _audioHandler!.setShuffleMode(mode);

  Future<void> addToQueue(Song song, {int? position}) async {
    final mediaItem = MediaItem(
      id: song.id.toString(),
      title: song.displayTitle,
      artist: song.displayArtist,
      album: song.displayAlbum,
      artUri: song.artworkPath != null ? Uri.parse(song.artworkPath!) : null,
      duration: song.durationDuration,
    );
    if (position != null) {
      await _audioHandler!.addQueueItem(mediaItem, at: position);
    } else {
      await _audioHandler!.addQueueItem(mediaItem);
    }
  }

  Future<void> removeFromQueue(int index) => _audioHandler!.removeQueueItemAt(index);
  Future<void> reorderQueue(int oldIndex, int newIndex) => _audioHandler!.moveQueueItem(oldIndex, newIndex);

  void dispose() {
    _playbackStateSub?.cancel();
    _indexSub?.cancel();
    _audioHandler = null;
    _audioPlayer = null;
    _initialized = false;
  }
}

class _AudioPlayerHandler extends audio_service.BaseAudioHandler with audio_service.QueueHandler, audio_service.SeekHandler {
  final AudioPlayer _player;
  final EqualizerService _equalizerService;

  _AudioPlayerHandler({
    required AudioPlayer player,
    required EqualizerService equalizerService,
  }) : _player = player,
       _equalizerService = equalizerService;

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> setSpeed(double speed) => _player.setSpeed(speed);

  @override
  Future<void> setRepeatMode(audio_service.AudioServiceRepeatMode mode) {
    switch (mode) {
      case audio_service.AudioServiceRepeatMode.none:
        return _player.setLoopMode(LoopMode.off);
      case audio_service.AudioServiceRepeatMode.one:
        return _player.setLoopMode(LoopMode.one);
      case audio_service.AudioServiceRepeatMode.all:
        return _player.setLoopMode(LoopMode.all);
      case audio_service.AudioServiceRepeatMode.group:
        return _player.setLoopMode(LoopMode.all);
    }
  }

  @override
  Future<void> setShuffleMode(audio_service.AudioServiceShuffleMode mode) {
    return _player.setShuffleModeEnabled(mode == audio_service.AudioServiceShuffleMode.all);
  }

  @override
  Future<void> addQueueItem(audio_service.MediaItem mediaItem, {int? at}) {
    final source = AudioSource.uri(Uri.parse(mediaItem.id), tag: mediaItem);
    if (at != null) {
      return _player.insert(source, index: at);
    }
    return _player.add(source);
  }

  @override
  Future<void> removeQueueItemAt(int index) => _player.removeAt(index);

  @override
  Future<void> moveQueueItem(int oldIndex, int newIndex) => _player.move(oldIndex, newIndex);

  @override
  Future<audio_service.MediaItem?> getMediaItem(String mediaId) async {
    return queue.value.firstWhereOrNull((item) => item.id == mediaId);
  }
}