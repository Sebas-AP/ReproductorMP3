import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:reproductor_musica/presentation/widgets/glass_widgets.dart';
import 'package:reproductor_musica/presentation/providers/service_providers.dart';
import 'package:reproductor_musica/presentation/providers/repository_providers.dart';
import 'package:reproductor_musica/domain/entities/media.dart';

final _searchQueryProvider = StateProvider<String>((ref) => '');

final _filteredSongsProvider = StreamProvider<List<Song>>((ref) {
  final repository = ref.watch(songRepositoryProvider);
  final query = ref.watch(_searchQueryProvider).toLowerCase();

  return repository.watchAllSongs().map((songs) {
    if (query.isEmpty) return songs;
    return songs.where((s) =>
      s.title.toLowerCase().contains(query) ||
      s.artist.toLowerCase().contains(query) ||
      s.album.toLowerCase().contains(query),
    ).toList();
  });
});

final _foldersStreamProvider = StreamProvider<List<Folder>>((ref) {
  final repository = ref.watch(folderRepositoryProvider);
  return repository.watchAllFolders();
});

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
  bool _isSearching = false;

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
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      ref.read(_searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(_filteredSongsProvider);
    final foldersAsync = ref.watch(_foldersStreamProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            title: _isSearching
                ? TextField(
                    controller: _searchController,
                    autofocus: true,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Buscar canciones, artistas...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : const Text('Biblioteca'),
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(_isSearching ? Icons.close : Icons.search),
                onPressed: () {
                  setState(() {
                    _isSearching = !_isSearching;
                    if (!_isSearching) {
                      _searchController.clear();
                      ref.read(_searchQueryProvider.notifier).state = '';
                    }
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.create_new_folder_outlined),
                tooltip: 'Añadir carpeta',
                onPressed: _openFolderPicker,
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Canciones'),
                Tab(text: 'Artistas'),
                Tab(text: 'Álbumes'),
                Tab(text: 'Carpetas'),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildSongsTab(songsAsync),
            _buildArtistsTab(songsAsync),
            _buildAlbumsTab(songsAsync),
            _buildFoldersTab(foldersAsync),
          ],
        ),
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.music_note_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No hay canciones',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Añade una carpeta para comenzar a escuchar tu música local',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _openFolderPicker,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Añadir Carpeta de Música'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      itemCount: songs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final song = songs[index];
        return _buildSongTile(song, index);
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      onTap: () => _playSong(song),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
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
                    size: 26,
                  )
                : null,
          ),
          const SizedBox(width: 14),
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
                const SizedBox(height: 3),
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
            Icon(Icons.equalizer, color: colorScheme.primary, size: 22)
          else
            GlassIconButton(
              icon: Icons.play_arrow_rounded,
              size: 20,
              onPressed: () => _playSong(song),
            ),
        ],
      ),
    );
  }

  Widget _buildArtistsTab(AsyncValue<List<Song>> songsAsync) {
    return songsAsync.when(
      data: (songs) {
        final Map<String, int> artistCounts = {};
        for (final s in songs) {
          final a = s.artist.isEmpty ? 'Artista desconocido' : s.artist;
          artistCounts[a] = (artistCounts[a] ?? 0) + 1;
        }
        final artists = artistCounts.keys.toList()..sort();

        if (artists.isEmpty) {
          return _buildEmptyState('Sin artistas', 'Añade carpetas con música para ver artistas');
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: artists.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final artist = artists[i];
            final count = artistCounts[artist] ?? 0;
            return GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onTap: () {
                ref.read(_searchQueryProvider.notifier).state = artist;
                _tabController.animateTo(0);
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: const Icon(Icons.person),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(artist, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('$count ${count == 1 ? "canción" : "canciones"}',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorState(e.toString()),
    );
  }

  Widget _buildAlbumsTab(AsyncValue<List<Song>> songsAsync) {
    return songsAsync.when(
      data: (songs) {
        final Map<String, int> albumCounts = {};
        for (final s in songs) {
          final a = s.album.isEmpty ? 'Álbum desconocido' : s.album;
          albumCounts[a] = (albumCounts[a] ?? 0) + 1;
        }
        final albums = albumCounts.keys.toList()..sort();

        if (albums.isEmpty) {
          return _buildEmptyState('Sin álbumes', 'Añade carpetas con música para ver álbumes');
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: albums.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final album = albums[i];
            final count = albumCounts[album] ?? 0;
            return GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              onTap: () {
                ref.read(_searchQueryProvider.notifier).state = album;
                _tabController.animateTo(0);
              },
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    child: const Icon(Icons.album),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(album, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('$count ${count == 1 ? "canción" : "canciones"}',
                            style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorState(e.toString()),
    );
  }

  Widget _buildFoldersTab(AsyncValue<List<Folder>> foldersAsync) {
    return foldersAsync.when(
      data: (folders) {
        if (folders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_outlined,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sin carpetas añadidas',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona las carpetas donde guardas tus archivos de música',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _openFolderPicker,
                    icon: const Icon(Icons.create_new_folder_outlined),
                    label: const Text('Seleccionar Carpeta'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          itemCount: folders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final folder = folders[index];
            return GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(Icons.folder, color: Theme.of(context).colorScheme.onPrimaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          folder.path,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Re-escanear carpeta',
                    onPressed: () => _rescanFolder(folder),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    tooltip: 'Eliminar carpeta',
                    onPressed: () => _deleteFolder(folder),
                  ),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => _buildErrorState(e.toString()),
    );
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
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
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

  Future<void> _openFolderPicker() async {
    final scanner = ref.read(mediaScannerProvider);
    final hasPerm = await scanner.requestPermissions();
    if (!mounted) return;

    if (!hasPerm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se requieren permisos de acceso a archivos/audio para añadir carpetas.'),
          backgroundColor: Colors.orange,
        ),
      );
    }

    final standardPaths = [
      '/storage/emulated/0/Music',
      '/storage/emulated/0/Download',
      '/storage/emulated/0/Audiobooks',
      '/storage/emulated/0/Podcasts',
    ];
    final availableStandards = standardPaths.where((path) {
      try {
        return Directory(path).existsSync();
      } catch (_) {
        return false;
      }
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;

        return GlassModalSheet(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.7,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.folder_special, color: colorScheme.primary, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Añadir Carpeta de Música',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(sheetContext);
                  final selectedPath = await FilePicker.getDirectoryPath(
                    dialogTitle: 'Selecciona la carpeta con tu música',
                  );
                  if (selectedPath != null) {
                    await _addAndScanFolder(selectedPath);
                  }
                },
                icon: const Icon(Icons.folder_open),
                label: const Text('Explorar y seleccionar carpeta...'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (availableStandards.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Carpetas comunes detectadas',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableStandards.map((path) {
                    final dirName = p.basename(path);
                    return ActionChip(
                      avatar: const Icon(Icons.add_circle_outline, size: 18),
                      label: Text(dirName),
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await _addAndScanFolder(path);
                      },
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _addAndScanFolder(String path) async {
    final folderRepo = ref.read(folderRepositoryProvider);
    final existing = await folderRepo.getFolderByPath(path);
    int folderId;
    if (existing != null && existing.id != null) {
      folderId = existing.id!;
    } else {
      final name = p.basename(path).isEmpty ? path : p.basename(path);
      folderId = await folderRepo.insertFolder(Folder(
        name: name,
        path: path,
        isEnabled: true,
      ));
    }

    final folder = await folderRepo.getFolderById(folderId);
    if (folder != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Escaneando canciones en "${folder.name}"...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      final scanner = ref.read(mediaScannerProvider);
      final count = await scanner.scanAndSaveSingleFolder(folder);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Escaneo completado: se encontraron $count canciones.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _rescanFolder(Folder folder) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Re-escaneando "${folder.name}"...')),
      );
    }
    final scanner = ref.read(mediaScannerProvider);
    final count = await scanner.scanAndSaveSingleFolder(folder);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Se actualizaron $count canciones en "${folder.name}".'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteFolder(Folder folder) async {
    if (folder.id != null) {
      await ref.read(folderRepositoryProvider).deleteFolder(folder.id!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Carpeta "${folder.name}" eliminada.')),
        );
      }
    }
  }
}

