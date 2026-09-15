import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reproductor_musica/presentation/pages/library/library_page.dart';
import 'package:reproductor_musica/presentation/pages/playlists/playlists_page.dart';
import 'package:reproductor_musica/presentation/pages/equalizer/equalizer_page.dart';
import 'package:reproductor_musica/presentation/pages/now_playing/now_playing_page.dart';
import 'package:reproductor_musica/presentation/pages/settings/settings_page.dart';
import 'package:reproductor_musica/presentation/widgets/glass_widgets.dart';
import 'package:reproductor_musica/presentation/providers/service_providers.dart';
import 'package:reproductor_musica/domain/entities/media.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final PageController _pageController;
  late final AnimationController _fabAnimationController;
  late final Animation<double> _fabAnimation;

  final List<Widget> _pages = [
    const LibraryPage(),
    const PlaylistsPage(),
    const EqualizerPage(),
    const SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeOutBack,
    );
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final playbackState = ref.watch(playbackStateProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: _pages,
            onPageChanged: (index) => setState(() => _currentIndex = index),
          ),
          if (playbackState.hasValue && playbackState.value!.currentSong != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 90,
              child: _buildMiniPlayer(playbackState.value!),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomNavBar(colorScheme),
          ),
        ],
      ),
      floatingActionButton: _buildFAB(colorScheme),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildMiniPlayer(PlaybackState state) {
    final song = state.currentSong!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: () => _openNowPlaying(),
      child: Row(
        children: [
          Hero(
            tag: 'artwork-${song.id}',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: colorScheme.surfaceContainerHighest,
                image: song.artworkPath != null
                    ? DecorationImage(
                        image: FileImage(File(song.artworkPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: song.artworkPath == null
                  ? Icon(Icons.music_note, color: colorScheme.onSurfaceVariant, size: 28)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  song.displayTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.displayArtist,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassIconButton(
                icon: Icons.skip_previous,
                size: 24,
                onPressed: () => ref.read(audioServiceProvider).previous(),
              ),
              const SizedBox(width: 8),
              GlassIconButton(
                icon: state.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 28,
                onPressed: () => ref.read(audioServiceProvider).playPause(),
                backgroundColor: colorScheme.primaryContainer,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              GlassIconButton(
                icon: Icons.skip_next,
                size: 24,
                onPressed: () => ref.read(audioServiceProvider).next(),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOut);
  }

  Widget _buildBottomNavBar(ColorScheme colorScheme) {
    final items = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.library_music_outlined),
        activeIcon: Icon(Icons.library_music),
        label: 'Biblioteca',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.queue_music_outlined),
        activeIcon: Icon(Icons.queue_music),
        label: 'Playlists',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.equalizer_outlined),
        activeIcon: Icon(Icons.equalizer),
        label: 'Ecualizador',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.settings_outlined),
        activeIcon: Icon(Icons.settings),
        label: 'Ajustes',
      ),
    ];

    return GlassBottomNavBar(
      currentIndex: _currentIndex,
      onTap: _onTabTapped,
      items: items,
    );
  }

  Widget _buildFAB(ColorScheme colorScheme) {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton(
        onPressed: _openNowPlaying,
        elevation: 0,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(Icons.music_note, size: 28),
      ),
    );
  }

  void _openNowPlaying() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const NowPlayingPage(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(0, 1), end: Offset.zero).chain(
                CurveTween(curve: Curves.easeOutCubic),
              ),
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
        barrierColor: Colors.black54,
      ),
    );
  }
}