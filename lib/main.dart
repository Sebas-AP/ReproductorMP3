import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:reproductor_musica/presentation/providers/theme_provider.dart';
import 'package:reproductor_musica/presentation/pages/home/home_page.dart';
import 'package:reproductor_musica/services/audio_service.dart' as audio_service;
import 'package:reproductor_musica/services/equalizer_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.reproductor.musica.audio',
    androidNotificationChannelName: 'Reproducción de música',
    androidNotificationOngoing: true,
  );

  final audioService = audio_service.AudioPlayerService();
  await audioService.initialize();

  final equalizerService = EqualizerService();
  await equalizerService.initialize();

  runApp(const ProviderScope(child: ReproductorApp()));
}

class ReproductorApp extends ConsumerWidget {
  const ReproductorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);

    return MaterialApp(
      title: 'Reproductor Música',
      debugShowCheckedModeBanner: false,
      theme: theme,
      darkTheme: theme,
      themeMode: theme.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
      home: const HomePage(),
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3)),
          ),
          child: child!,
        );
      },
    );
  }
}