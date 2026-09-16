import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reproductor_musica/presentation/widgets/glass_widgets.dart';
import 'package:reproductor_musica/presentation/providers/service_providers.dart';
import 'package:reproductor_musica/presentation/providers/repository_providers.dart';
import 'package:reproductor_musica/domain/entities/media.dart';

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      ref.read(_searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(_filteredSongsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSongsTab(songsAsync),
                _buildArtistsTab(),
                _buildAlbumsTab(),
                _buildFoldersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSongsTab(AsyncValue<List<Song>> songsAsync) {
    return songsAsync.when(
      data: (songs) => _buildSongList(songs),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorState(e.toString()),
    );
  }

  Widget _buildSongList(List<Song> songs) {
    if (songs.isEmpty) {
      return _buildEmptyState(
        'No hay canciones',
        'Añade una carpeta en ajustes para empezar',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongTile(song, index)
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.1, end: 0);
      },
    );
  }

  Widget _buildSongTile(Song song, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final playbackState = ref.watch(playbackStateProvider);

    final isPlaying =
        playbackState.hasValue &&
        playbackState.value!.currentSong?.id == song.id &&
        playbackState.value!.isPlaying;

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: () => _playSong(song),
      child: Row(
        children: [
          Container(
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
                ? Icon(
                    Icons.music_note,
                    color: colorScheme.onSurfaceVariant,
                    size: 28,
                  )
                : null,
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
                    color: isPlaying
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
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
          if (isPlaying)
            Icon(Icons.equalizer, color: colorScheme.primary, size: 20)
          else
            GlassIconButton(
              icon: Icons.more_vert,
              size: 20,
              onPressed: () => _showSongMenu(song),
            ),
        ],
      ),
    );
  }

  Widget _buildArtistsTab() {
    return _buildEmptyState(
      'Artistas',
      'Escanea tu biblioteca para ver artistas',
    );
  }

  Widget _buildAlbumsTab() {
    return _buildEmptyState(
      'Álbumes',
      'Escanea tu biblioteca para ver álbumes',
    );
  }

  Widget _buildFoldersTab() {
    return _buildEmptyState('Carpetas', 'Añade carpetas en ajustes');
  }

  Widget _buildEmptyState(String title, String subtitle) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_off,
            size: 80,
            color: colorScheme.onSurfaceVariant.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _playSong(Song song) {
    ref.read(audioServiceProvider).setQueue([song], startIndex: 0);
    ref.read(audioServiceProvider).play();
  }

  void _showSongMenu(Song song) {
    // TODO: Show bottom sheet with options
  }
}

final _searchQueryProvider = StateProvider<String>((ref) => '');

final _filteredSongsProvider = FutureProvider<List<Song>>((ref) async {
  final repository = ref.watch(songRepositoryProvider);
  final query = ref.watch(_searchQueryProvider);
  return repository.getAllSongs(query: query.isEmpty ? null : query);
});
