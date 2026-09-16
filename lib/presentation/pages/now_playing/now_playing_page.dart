import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:reproductor_musica/presentation/widgets/glass_widgets.dart';
import 'package:reproductor_musica/services/audio_service.dart' as audio_service;
import 'package:reproductor_musica/presentation/providers/service_providers.dart';
import 'package:reproductor_musica/domain/entities/media.dart';
import 'package:reproductor_musica/core/themes/app_theme.dart';

class NowPlayingPage extends ConsumerStatefulWidget {
  const NowPlayingPage({super.key});

  @override
  ConsumerState<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends ConsumerState<NowPlayingPage> with TickerProviderStateMixin {
  late final AnimationController _artworkController;
  late final AnimationController _progressController;
  late final AnimationController _lyricsController;
  Timer? _progressTimer;
  PaletteGenerator? _paletteGenerator;
  DynamicColors? _dynamicColors;

  @override
  void initState() {
    super.initState();
    _artworkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _lyricsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _artworkController.forward();
    _startProgressTimer();
    _extractColors();
  }

  @override
  void dispose() {
    _artworkController.dispose();
    _progressController.dispose();
    _lyricsController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startProgressTimer() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _extractColors() async {
    final state = ref.read(playbackStateProvider);
    if (state.hasValue && state.value!.currentSong?.artworkPath != null) {
      try {
        final imageProvider = FileImage(File(state.value!.currentSong!.artworkPath!));
        _paletteGenerator = await PaletteGenerator.fromImageProvider(imageProvider);
        if (_paletteGenerator != null && mounted) {
          _dynamicColors = _generateDynamicColors(_paletteGenerator!);
          setState(() {});
        }
      } catch (_) {}
    }
  }

  DynamicColors _generateDynamicColors(PaletteGenerator palette) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color vibrant = palette.vibrantColor?.color ?? palette.dominantColor?.color ?? Colors.indigo;
    Color muted = palette.mutedColor?.color ?? vibrant.withOpacity(0.6);
    Color dominant = palette.dominantColor?.color ?? vibrant;

    return DynamicColors.fromImageColors(
      vibrant: vibrant,
      muted: muted,
      dominant: dominant,
      isDark: isDark,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playbackStateProvider);
    final theme = Theme.of(context);
    final colorScheme = _dynamicColors != null
        ? ColorScheme.fromSeed(
            seedColor: _dynamicColors!.primary,
            brightness: theme.brightness,
            primary: _dynamicColors!.primary,
            secondary: _dynamicColors!.secondary,
            surface: _dynamicColors!.surface,
          )
        : theme.colorScheme;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.keyboard_arrow_down),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.queue_music),
              onPressed: _showQueue,
            ),
            IconButton(
              icon: const Icon(Icons.timer),
              onPressed: _showSleepTimer,
            ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: _showMoreOptions,
            ),
          ],
        ),
        body: state.when(
          data: (playbackState) => _buildContent(playbackState, colorScheme),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
    );
  }

  Widget _buildContent(PlaybackState state, ColorScheme colorScheme) {
    final song = state.currentSong;
    final theme = Theme.of(context);

    if (song == null) {
      return _buildEmptyState(theme, colorScheme);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colorScheme.primary.withOpacity(0.15),
            colorScheme.background,
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            hasScrollBody: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  _buildArtwork(song, colorScheme),
                  const SizedBox(height: 32),
                  _buildSongInfo(song, theme, colorScheme),
                  const SizedBox(height: 32),
                  _buildProgressBar(state, colorScheme),
                  const SizedBox(height: 24),
                  _buildControls(state, colorScheme),
                  const SizedBox(height: 24),
                  _buildSecondaryControls(state, colorScheme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork(Song song, ColorScheme colorScheme) {
    return Hero(
      tag: 'artwork-${song.id}',
      child: AnimatedBuilder(
        animation: _artworkController,
        builder: (context, child) {
          return Transform.scale(
            scale: 0.9 + (_artworkController.value * 0.1),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.3),
                    blurRadius: 40,
                    offset: const Offset(0, 20),
                  ),
                ],
                image: song.artworkPath != null
                    ? DecorationImage(
                        image: FileImage(File(song.artworkPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                gradient: song.artworkPath == null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                      )
                    : null,
              ),
              child: song.artworkPath == null
                  ? Center(
                      child: Icon(
                        Icons.music_note,
                        size: 100,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    ).animate()
        .scale(duration: 600.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 600.ms);
  }

  Widget _buildSongInfo(Song song, ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          song.displayTitle,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onBackground,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 8),
        Text(
          song.displayArtist,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onBackground.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
        const SizedBox(height: 4),
        Text(
          song.displayAlbum,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onBackground.withOpacity(0.5),
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildProgressBar(PlaybackState state, ColorScheme colorScheme) {
    final progress = state.duration.inMilliseconds > 0
        ? state.position.inMilliseconds / state.duration.inMilliseconds
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withOpacity(0.15),
            valueIndicatorColor: colorScheme.primary,
            valueIndicatorTextStyle: TextStyle(color: colorScheme.onPrimary, fontSize: 12),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 0),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            showValueIndicator: ShowValueIndicator.always,
          ),
          child: Slider(
            value: progress.clamp(0.0, 1.0),
            onChanged: (v) => ref.read(audioServiceProvider).seek(
              Duration(milliseconds: (v * state.duration.inMilliseconds).round()),
            ),
            min: 0,
            max: 1,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(state.position), style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text(_formatDuration(state.duration), style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildControls(PlaybackState state, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassIconButton(
          icon: state.shuffleMode == ShuffleMode.on ? Icons.shuffle_on : Icons.shuffle,
          size: 24,
          onPressed: () => ref.read(audioServiceProvider).setShuffleMode(
            state.shuffleMode == ShuffleMode.on ? ShuffleMode.off : ShuffleMode.on,
          ),
          backgroundColor: state.shuffleMode == ShuffleMode.on
              ? colorScheme.primaryContainer
              : null,
          color: state.shuffleMode == ShuffleMode.on
              ? colorScheme.onPrimaryContainer
              : null,
        ).animate().fadeIn(delay: 600.ms).scale(),
        const SizedBox(width: 24),
        GlassIconButton(
          icon: Icons.skip_previous,
          size: 36,
          onPressed: () => ref.read(audioServiceProvider).previous(),
        ).animate().fadeIn(delay: 650.ms).scale(),
        const SizedBox(width: 32),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: GlassIconButton(
            icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
            size: 48,
            padding: const EdgeInsets.all(24),
            onPressed: () => ref.read(audioServiceProvider).playPause(),
            backgroundColor: colorScheme.primary,
            color: colorScheme.onPrimary,
          ),
        ).animate().fadeIn(delay: 700.ms).scale(),
        const SizedBox(width: 32),
        GlassIconButton(
          icon: Icons.skip_next,
          size: 36,
          onPressed: () => ref.read(audioServiceProvider).next(),
        ).animate().fadeIn(delay: 750.ms).scale(),
        const SizedBox(width: 24),
        GlassIconButton(
          icon: _getRepeatIcon(state.repeatMode),
          size: 24,
          onPressed: () => _cycleRepeatMode(state.repeatMode),
          backgroundColor: state.repeatMode != RepeatMode.off
              ? colorScheme.primaryContainer
              : null,
          color: state.repeatMode != RepeatMode.off
              ? colorScheme.onPrimaryContainer
              : null,
        ).animate().fadeIn(delay: 800.ms).scale(),
      ],
    );
  }

  Widget _buildSecondaryControls(PlaybackState state, ColorScheme colorScheme) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GlassIconButton(
          icon: Icons.speed,
          size: 20,
          onPressed: _showSpeedDialog,
          tooltip: 'Velocidad: ${state.speed}x',
        ),
        const SizedBox(width: 16),
        GlassIconButton(
          icon: Icons.equalizer,
          size: 20,
          onPressed: () {
            Navigator.pop(context);
            // Navigate to equalizer tab
          },
          tooltip: 'Ecualizador',
        ),
        const SizedBox(width: 16),
        GlassIconButton(
          icon: Icons.volume_up,
          size: 20,
          onPressed: _showVolumeDialog,
          tooltip: 'Volumen',
        ),
        const SizedBox(width: 16),
        GlassIconButton(
          icon: Icons.bedtime,
          size: 20,
          onPressed: _showSleepTimer,
          tooltip: 'Temporizador',
        ),
      ],
    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildEmptyState(ThemeData theme, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_off, size: 100, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 24),
          Text('Nada reproduciéndose', style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.library_music),
            label: const Text('Ir a la biblioteca'),
          ),
        ],
      ),
    );
  }

  IconData _getRepeatIcon(RepeatMode mode) {
    switch (mode) {
      case RepeatMode.off:
        return Icons.repeat;
      case RepeatMode.one:
        return Icons.repeat_one;
      case RepeatMode.all:
        return Icons.repeat;
    }
  }

  void _cycleRepeatMode(RepeatMode current) {
    RepeatMode next;
    switch (current) {
      case RepeatMode.off:
        next = RepeatMode.all;
        break;
      case RepeatMode.all:
        next = RepeatMode.one;
        break;
      case RepeatMode.one:
        next = RepeatMode.off;
        break;
    }
    ref.read(audioServiceProvider).setRepeatMode(next);
  }

  void _showQueue() {
    // TODO: Show queue bottom sheet
  }

  void _showSleepTimer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSleepTimerSheet(),
    );
  }

  void _showSpeedDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSpeedSheet(),
    );
  }

  void _showVolumeDialog() {
    // TODO: Show volume slider
  }

  void _showMoreOptions() {
    // TODO: Show more options
  }

  Widget _buildSleepTimerSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.read(audioServiceProvider);
    final remaining = state.sleepTimerRemaining;

    return GlassModalSheet(
      maxHeight: 400,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Temporizador de sueño', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          if (remaining != null) ...[
            Text('Se detendrá en', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text(
              _formatDuration(remaining),
              style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => state.setSleepTimer(null),
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
            ),
            const SizedBox(height: 16),
          ],
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              10, 15, 20, 30, 45, 60, 90, 120
            ].map((minutes) => _buildTimerOption(minutes, state, colorScheme)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimerOption(int minutes, audio_service.AudioPlayerService service, ColorScheme colorScheme) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      onTap: () {
        service.setSleepTimer(Duration(minutes: minutes));
        Navigator.pop(context);
      },
      child: Text(
        '$minutes min',
        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildSpeedSheet() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final state = ref.read(audioServiceProvider);

    return GlassModalSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Velocidad de reproducción', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0].map((speed) => _buildSpeedOption(speed, state, colorScheme)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedOption(double speed, audio_service.AudioPlayerService service, ColorScheme colorScheme) {
    final theme = Theme.of(context);
    final isSelected = (service.currentState.speed - speed).abs() < 0.01;

    return GlassChip(
      label: '${speed}x',
      selected: isSelected,
      onTap: () {
        service.setSpeed(speed);
        Navigator.pop(context);
      },
      selectedColor: colorScheme.primaryContainer,
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (d.inHours > 0) {
      return '${d.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}