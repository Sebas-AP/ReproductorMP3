import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reproductor_musica/presentation/widgets/glass_widgets.dart';
import 'package:reproductor_musica/domain/entities/media.dart';
import 'package:reproductor_musica/presentation/providers/repository_providers.dart';
import 'package:reproductor_musica/presentation/providers/service_providers.dart';

class PlaylistsPage extends ConsumerStatefulWidget {
  const PlaylistsPage({super.key});

  @override
  ConsumerState<PlaylistsPage> createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends ConsumerState<PlaylistsPage> {
  @override
  Widget build(BuildContext context) {
    final playlistsAsync = ref.watch(_playlistsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Playlists'),
            actions: [
              GlassIconButton(
                icon: Icons.add,
                onPressed: _showCreatePlaylistDialog,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverFillRemaining(
            child: playlistsAsync.when(
              data: (playlists) => _buildPlaylistGrid(playlists),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _buildErrorState(e.toString()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistGrid(List<Playlist> playlists) {
    if (playlists.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: playlists.length,
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        return _buildPlaylistCard(playlist, index)
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 300.ms)
            .scale(duration: 300.ms, curve: Curves.easeOutBack);
      },
    );
  }

  Widget _buildPlaylistCard(Playlist playlist, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _openPlaylist(playlist),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: playlist.artworkPath != null
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primaryContainer,
                          colorScheme.secondaryContainer,
                        ],
                      ),
                image: playlist.artworkPath != null
                    ? DecorationImage(
                        image: FileImage(File(playlist.artworkPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: playlist.artworkPath == null
                  ? Center(
                      child: Icon(
                        Icons.queue_music,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                      ),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            playlist.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${playlist.songCount} canciones',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GlassIconButton(
                icon: Icons.play_arrow,
                size: 20,
                onPressed: () => _playPlaylist(playlist),
                backgroundColor: colorScheme.primaryContainer,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              GlassIconButton(
                icon: Icons.more_vert,
                size: 20,
                onPressed: () => _showPlaylistMenu(playlist),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music_outlined, size: 80, color: colorScheme.onSurfaceVariant.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text('Sin playlists', style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text('Crea tu primera playlist', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _showCreatePlaylistDialog,
            icon: const Icon(Icons.add),
            label: const Text('Crear playlist'),
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
          Text('Error', style: theme.textTheme.headlineSmall?.copyWith(color: colorScheme.error)),
          const SizedBox(height: 8),
          Text(error, style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nueva playlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nombre de la playlist'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _createPlaylist(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  Future<void> _createPlaylist(String name) async {
    final repository = ref.read(playlistRepositoryProvider);
    final playlist = Playlist(
      name: name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await repository.insertPlaylist(playlist);
    ref.invalidate(_playlistsProvider);
  }

  void _openPlaylist(Playlist playlist) {
    // TODO: Navigate to playlist detail page
  }

  void _playPlaylist(Playlist playlist) async {
    final repository = ref.read(playlistRepositoryProvider);
    final songs = await repository.getPlaylistSongs(playlist.id!);
    if (songs.isNotEmpty) {
      await ref.read(audioServiceProvider).setQueue(songs, startIndex: 0);
      await ref.read(audioServiceProvider).play();
    }
  }

  void _showPlaylistMenu(Playlist playlist) {
    // TODO: Show menu
  }
}

final _playlistsProvider = FutureProvider<List<Playlist>>((ref) async {
  final repository = ref.watch(playlistRepositoryProvider);
  return repository.getAllPlaylists();
});