import 'dart:async';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:reproductor_musica/domain/entities/media.dart';
import 'package:reproductor_musica/services/equalizer_service.dart';

class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  final EqualizerService _equalizerService = EqualizerService();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  final List<Song> _queueSongs = [];

  int _currentIndex = -1;
  bool _shuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;
  double _speed = 1.0;
  double _volume = 1.0;
  DateTime? _sleepTimerEnd;
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
    await _player.setAudioSource(_playlist);

    // Get audio session ID for equalizer (Android)
    int? audioSessionId;
    try {
      audioSessionId = _player.androidAudioSessionId;
    } catch (_) {}

    await _equalizerService.initialize(audioSessionId: audioSessionId);
  }

  Stream<PlaybackState> get stateStream => _stateController!.stream;

  PlaybackState get currentState => _buildState();

  AudioSource _createAudioSource(Song song) {
    return AudioSource.uri(
      Uri.parse(song.path),
      tag: MediaItem(
        id: song.id?.toString() ?? song.path,
        title: song.displayTitle,
        artist: song.displayArtist,
        album: song.displayAlbum,
        artUri: song.artworkPath != null ? Uri.file(song.artworkPath!) : null,
        duration: song.durationDuration,
        extras: {'path': song.path},
      ),
    );
  }

  Future<void> setQueue(List<Song> songs, {int startIndex = 0}) async {
    _queueSongs.clear();
    _queueSongs.addAll(songs);
    final sources = songs.map(_createAudioSource).toList();

    _currentIndex = songs.isEmpty ? -1 : startIndex.clamp(0, songs.length - 1);
    await _playlist.clear();
    await _playlist.addAll(sources);

    if (_currentIndex >= 0 && _currentIndex < songs.length) {
      await _player.seek(Duration.zero, index: _currentIndex);
    }
    _emitState();
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> playPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> next() async {
    if (_player.hasNext) {
      await _player.seekToNext();
    }
  }

  Future<void> previous() async {
    if (_player.hasPrevious) {
      await _player.seekToPrevious();
    }
  }

  Future<void> setRepeatMode(RepeatMode mode) async {
    _repeatMode = mode;
    switch (mode) {
      case RepeatMode.off:
        await _player.setLoopMode(LoopMode.off);
        break;
      case RepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.all:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
    _emitState();
  }

  Future<void> setShuffleMode(ShuffleMode mode) async {
    _shuffle = mode == ShuffleMode.on;
    await _player.setShuffleModeEnabled(_shuffle);
    _emitState();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed.clamp(0.5, 2.0);
    await _player.setSpeed(_speed);
    _emitState();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
    _emitState();
  }

  Future<void> setSleepTimer(Duration? duration) async {
    _sleepTimer?.cancel();
    _sleepTimerEnd = duration != null ? DateTime.now().add(duration) : null;
    if (duration != null) {
      _sleepTimer = Timer(duration, () => pause());
    }
    _emitState();
  }

  Duration? get sleepTimerRemaining {
    if (_sleepTimerEnd == null) return null;
    final remaining = _sleepTimerEnd!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Future<void> addToQueue(Song song, {int? position}) async {
    final source = _createAudioSource(song);
    if (position != null && position <= _queueSongs.length) {
      _queueSongs.insert(position, song);
      await _playlist.insert(position, source);
    } else {
      _queueSongs.add(song);
      await _playlist.add(source);
    }
    _emitState();
  }

  Future<void> removeFromQueue(int index) async {
    if (index >= 0 && index < _queueSongs.length) {
      _queueSongs.removeAt(index);
      await _playlist.removeAt(index);
      _emitState();
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= _queueSongs.length || newIndex < 0 || newIndex >= _queueSongs.length) return;
    final song = _queueSongs.removeAt(oldIndex);
    _queueSongs.insert(newIndex, song);
    await _playlist.move(oldIndex, newIndex);
    _emitState();
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
    if (_currentIndex >= 0 && _currentIndex < _queueSongs.length) {
      currentSong = _queueSongs[_currentIndex];
    }

    return PlaybackState(
      currentSong: currentSong,
      queue: List<Song>.unmodifiable(_queueSongs),
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
    if (_stateController != null && !_stateController!.isClosed) {
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
    await _stateController?.close();
  }
}