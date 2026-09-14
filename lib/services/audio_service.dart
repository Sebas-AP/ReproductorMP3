import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:audio_session/audio_session.dart';
import 'package:reproductor_musica/domain/entities/media.dart';
import 'package:reproductor_musica/services/media_session_service.dart';
import 'package:reproductor_musica/services/equalizer_service.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final MediaSessionService _mediaSession = MediaSessionService();
  final EqualizerService _equalizerService = EqualizerService();
  final List<AudioSource> _queue = [];
  int _currentIndex = -1;
  bool _shuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;
  double _speed = 1.0;
  double _volume = 1.0;
  Duration? _sleepTimerEnd;
  Timer? _sleepTimer;
  StreamController<PlaybackState>? _stateController;
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _bufferedSub;
  StreamSubscription<ProcessingState>? _processingSub;
  StreamSubscription<LoopMode>? _loopModeSub;
  StreamSubscription<int?>? _indexSub;
  StreamSubscription<double>? _speedSub;
  StreamSubscription<double>? _volumeSub;

  AudioPlayerService._internal();

  static final AudioPlayerService _instance = AudioPlayerService._internal();
  factory AudioPlayerService() => _instance;

  AudioPlayer get player => _player;
  EqualizerService get equalizerService => _equalizerService;

  Future<void> initialize() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    _stateController = StreamController<PlaybackState>.broadcast();

    _playerStateSub = _player.playerStateStream.listen(_onPlayerStateChanged);
    _positionSub = _player.positionStream.listen(_onPositionChanged);
    _bufferedSub = _player.bufferedPositionStream.listen(_onBufferedPositionChanged);
    _processingSub = _player.processingStateStream.listen(_onProcessingStateChanged);
    _loopModeSub = _player.loopModeStream.listen(_onLoopModeChanged);
    _indexSub = _player.currentIndexStream.listen(_onIndexChanged);
    _speedSub = _player.speedStream.listen(_onSpeedChanged);
    _volumeSub = _player.volumeStream.listen(_onVolumeChanged);

    await _player.setVolume(_volume);
    await _player.setSpeed(_speed);

    // Get audio session ID for equalizer (Android)
    int? audioSessionId;
    try {
      audioSessionId = _player.androidAudioSessionId;
    } catch (_) {}

    await _mediaSession.initialize(
      audioPlayer: _player,
      equalizerService: _equalizerService,
    );

    await _equalizerService.initialize(audioSessionId: audioSessionId);
  }

  Stream<PlaybackState> get stateStream => _stateController!.stream;

  PlaybackState get currentState => _buildState();

  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queue.clear();
    for (final song in songs) {
      _queue.add(AudioSource.uri(Uri.parse(song.path), tag: MediaItem(
        id: song.id.toString(),
        title: song.displayTitle,
        artist: song.displayArtist,
        album: song.displayAlbum,
        artUri: song.artworkPath != null ? Uri.parse(song.artworkPath!) : null,
        duration: song.durationDuration,
      )));
    }
    _currentIndex = startIndex.clamp(0, songs.length - 1);
    await _player.setAudioSource(ConcatenatingAudioSource(children: _queue), initialIndex: _currentIndex);
    await _mediaSession.updateQueue(songs, startIndex: startIndex);
  }

  Future<void> play() async {
    await _mediaSession.play();
  }

  Future<void> pause() async {
    await _mediaSession.pause();
  }

  Future<void> playPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop() async {
    await _mediaSession.stop();
  }

  Future<void> seek(Duration position) async {
    await _mediaSession.seekTo(position);
  }

  Future<void> next() async {
    await _mediaSession.skipToNext();
  }

  Future<void> previous() async {
    await _mediaSession.skipToPrevious();
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    _repeatMode = mode;
    switch (mode) {
      case RepeatMode.off:
        await _mediaSession.setRepeatMode(AudioServiceRepeatMode.none);
        break;
      case RepeatMode.one:
        await _mediaSession.setRepeatMode(AudioServiceRepeatMode.one);
        break;
      case RepeatMode.all:
        await _mediaSession.setRepeatMode(AudioServiceRepeatMode.all);
        break;
    }
  }

  Future<void> setShuffleMode(ShuffleMode mode) async {
    _shuffle = mode == ShuffleMode.on;
    await _mediaSession.setShuffleMode(
      _shuffle ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    );
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    await _mediaSession.setSpeed(_speed);
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _mediaSession.setVolume(_volume);
  }

  Future<void> setSleepTimer(Duration? duration) async {
    _sleepTimer?.cancel();
    _sleepTimerEnd = duration != null ? DateTime.now().add(duration) : null;
    if (duration != null) {
      _sleepTimer = Timer(duration, () => pause());
    }
  }

  Duration? get sleepTimerRemaining {
    if (_sleepTimerEnd == null) return null;
    final remaining = _sleepTimerEnd!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> addToQueue(Song song, {int? position}) async {
    final source = AudioSource.uri(Uri.parse(song.path), tag: MediaItem(
      id: song.id.toString(),
      title: song.displayTitle,
      artist: song.displayArtist,
      album: song.displayAlbum,
      artUri: song.artworkPath != null ? Uri.parse(song.artworkPath!) : null,
      duration: song.durationDuration,
    ));

    if (position != null && position <= _queue.length) {
      _queue.insert(position, source);
      await _player.insert(source, index: position);
    } else {
      _queue.add(source);
      await _player.add(source);
    }
    await _mediaSession.addToQueue(song, position: position);
  }

  Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      await _player.removeAt(index);
      await _mediaSession.removeFromQueue(index);
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _queue.length || newIndex < 0 || newIndex >= _queue.length) return;
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);
    await _player.move(oldIndex, newIndex);
    await _mediaSession.reorderQueue(oldIndex, newIndex);
  }

  void _onPlayerStateChanged(PlayerState state) {
    _emitState();
  }

  void _onPositionChanged(Duration position) {
    _emitState();
  }

  void _onBufferedPositionChanged(Duration position) {
    _emitState();
  }

  void _onProcessingStateChanged(ProcessingState state) {
    _emitState();
  }

  void _onLoopModeChanged(LoopMode mode) {
    switch (mode) {
      case LoopMode.off:
        _repeatMode = RepeatMode.off;
        break;
      case LoopMode.one:
        _repeatMode = RepeatMode.one;
        break;
      case LoopMode.all:
        _repeatMode = RepeatMode.all;
        break;
    }
    _emitState();
  }

  void _onIndexChanged(int? index) {
    if (index != null) {
      _currentIndex = index;
      _emitState();
    }
  }

  void _onSpeedChanged(double speed) {
    _speed = speed;
    _emitState();
  }

  void _onVolumeChanged(double volume) {
    _volume = volume;
    _emitState();
  }

  PlaybackState _buildState() {
    Song? currentSong;
    if (_currentIndex >= 0 && _currentIndex < _queue.length) {
      final tag = _queue[_currentIndex].tag as MediaItem?;
      if (tag != null) {
        currentSong = Song(
          id: int.tryParse(tag.id),
          path: tag.extras?['path'] as String? ?? '',
          title: tag.title,
          artist: tag.artist ?? '',
          album: tag.album ?? '',
          duration: tag.duration?.inMilliseconds ?? 0,
          artworkPath: tag.artUri?.toString(),
          dateAdded: DateTime.now(),
        );
      }
    }

    return PlaybackState(
      currentSong: currentSong,
      queue: _queue.map((s) {
        final tag = s.tag as MediaItem?;
        return Song(
          id: int.tryParse(tag?.id ?? ''),
          path: tag?.extras?['path'] as String? ?? '',
          title: tag?.title ?? '',
          artist: tag?.artist ?? '',
          album: tag?.album ?? '',
          duration: tag?.duration?.inMilliseconds ?? 0,
          artworkPath: tag?.artUri?.toString(),
          dateAdded: DateTime.now(),
        );
      }).toList(),
      currentIndex: _currentIndex,
      isPlaying: _player.playing,
      position: _player.position,
      bufferedPosition: _player.bufferedPosition,
      repeatMode: _repeatMode,
      shuffleMode: _shuffle ? ShuffleMode.on : ShuffleMode.off,
      speed: _speed,
      volume: _volume,
      isLoading: _player.processingState == ProcessingState.loading ||
          _player.processingState == ProcessingState.buffering,
    );
  }

  void _emitState() {
    if (!_stateController!.isClosed) {
      _stateController!.add(_buildState());
    }
  }

  Future<void> dispose() async {
    await _playerStateSub?.cancel();
    await _positionSub?.cancel();
    await _bufferedSub?.cancel();
    await _processingSub?.cancel();
    await _loopModeSub?.cancel();
    await _indexSub?.cancel();
    await _speedSub?.cancel();
    await _volumeSub?.cancel();
    _sleepTimer?.cancel();
    await _player.dispose();
    _mediaSession.dispose();
    await _stateController?.close();
  }
}