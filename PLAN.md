# Plan de Aplicación Móvil - Reproductor de Música

## Resumen Ejecutivo
Aplicación nativa multiplataforma (iOS/Android) para reproducción de música local con UI moderna (glassmorfismo), colores dinámicos basados en carátulas, ecualizador avanzado, gestión de playlists y widget de control.

---

## Stack Tecnológico Recomendado

### Opción A: Flutter (Recomendado)
- **Framework**: Flutter 3.x + Dart
- **UI**: Material 3 + Glassmorphism personalizado
- **Audio**: `just_audio` + `audio_session` + `just_audio_background`
- **Ecualizador**: `flutter_equalizer` o implementación nativa via FFI
- **Base de datos**: `drift` (SQLite) para playlists/metadatos
- **Permisos**: `permission_handler`
- **Widget**: `home_widget` + platform channels
- **Extracción colores**: `palette_generator` / `image_colors`

### Opción B: React Native + Expo
- **Framework**: React Native 0.74+ + Expo SDK 51
- **UI**: `react-native-glassmorphism` + `nativewind` (Tailwind)
- **Audio**: `expo-av` + `react-native-track-player`
- **Ecualizador**: Módulo nativo custom (iOS: AudioUnit, Android: AudioFx)
- **Base de datos**: `watermelondb` / `realm`
- **Widget**: `react-native-widgetkit` (iOS) + `glance` (Android)

---

## Arquitectura

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   ├── utils/
│   └── themes/
├── data/
│   ├── datasources/
│   │   ├── local/ (SQLite, SharedPreferences)
│   │   └── remote/ (opcional: Last.fm, MusicBrainz)
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── pages/
│   │   ├── home/
│   │   ├── library/
│   │   ├── playlists/
│   │   ├── equalizer/
│   │   ├── now_playing/
│   │   └── settings/
│   ├── widgets/
│   ├── providers/ (Riverpod/Bloc)
│   └── themes/
└── main.dart
```

---

## Módulos y Funcionalidades

### 1. Explorador de Archivos / Biblioteca
- [ ] Permiso de almacenamiento (MediaStore Android 10+ / PhotoKit iOS)
- [ ] Escaneo recursivo de carpetas seleccionadas
- [ ] Parsing de metadatos ID3 (title, artist, album, artwork, duration, track number, genre, year)
- [ ] Agrupación: Todas las canciones, Artistas, Álbumes, Géneros, Carpetas
- [ ] Búsqueda en tiempo real (debounced)
- [ ] Ordenación múltiple (alfabético, fecha, duración, reproducciones)

### 2. Reproductor Principal (Now Playing)
- [ ] Pantalla full-screen con carátula grande (hero animation)
- [ ] Colores dinámicos extraídos de la carátula (Pallete Generator)
- [ ] Controles: play/pause, prev/next, seekbar, velocidad, sleep timer
- [ ] Modos de repetición: Off / One / All / Shuffle
- [ ] Cola de reproducción editable (drag & drop)
- [ ] Letras sincronizadas (LRC) - opcional
- [ ] Visualizador de onda/espectro - opcional

### 3. Ecualizador
- [ ] 10 bandas (31Hz - 16kHz) + Preamp
- [ ] Presets: Rock, Pop, Jazz, Classical, Bass Boost, Vocal, Custom
- [ ] Guardado de preset personalizado
- [ ] Bass Boost + Virtualizer (Android) / AudioUnit (iOS)
- [ ] Persistencia de configuración por dispositivo/auriculares
- [ ] UI: Sliders verticales con glassmorfismo, respuesta háptica

### 4. Playlists
- [ ] Crear/editar/eliminar playlists
- [ ] Añadir/quitar canciones (multi-select)
- [ ] Reordenar canciones (drag & drop)
- [ ] Playlists inteligentes: "Más reproducidas", "Recientes", "Por género", "Por año"
- [ ] Importar/Exportar (M3U, JSON)
- [ ] Portada personalizada o auto-generada (collage de carátulas)

### 5. Temas y Personalización (Glassmorfismo + Colores Dinámicos)
- [ ] Tema base: Light / Dark / System
- [ ] **Colores dinámicos**: Extraer palette (Vibrant, Muted, Dominant) de carátula actual
- [ ] Aplicar a: Background, AppBar, Botones, Sliders, Progress bars
- [ ] **Personalización manual**:
  - Color primario / secundario / acento
  - Intensidad del blur (0-30dp)
  - Opacidad de superficies (0.1-0.9)
  - Radio de bordes (0-32dp)
  - Fuente personalizada
- [ ] Guardar temas como presets
- [ ] Transiciones suaves entre colores (animateColorAsState)

### 6. Widget de Pantalla de Inicio / Bloqueo
#### Android (Glance / RemoteViews)
- [ ] Tamaños: 1x1, 2x1, 4x1, 4x2
- [ ] Controles: Play/Pause, Prev, Next, Título/Artista, Carátula pequeña
- [ ] Actualización via MediaSessionCompat + MediaController
- [ ] Click en carátula → abre app en Now Playing

#### iOS (WidgetKit + Live Activity)
- [ ] Tamaños: Small, Medium, Large
- [ ] Live Activity en Dynamic Island / Lock Screen
- [ ] Controles idénticos a Android
- [ ] Timeline refresh cada 30s / en eventos de playback

### 7. Configuraciones Avanzadas
- [ ] Carpeta(s) de origen múltiples
- [ ] Auto-scan en inicio / programado
- [ ] Normalización de volumen (ReplayGain / EBU R128)
- [ ] Crossfade (0-12s)
- [ ] Gapless playback
- [ ] Salida de audio: Dispositivo / Bluetooth / Cast
- [ ] Scrobbling (Last.fm / ListenBrainz) - opcional
- [ ] Backup/Restore de base de datos (Google Drive / iCloud / Local)

---

## UI/UX - Glassmorfismo Específico

### Componentes Base
```dart
// GlassContainer
Container(
  decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: Colors.white.withOpacity(0.15)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 20,
        offset: Offset(0, 10),
      ),
    ],
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        color: Colors.white.withOpacity(0.05),
        child: content,
      ),
    ),
  ),
)
```

### Paleta Dinámica por Carátula
| Rol | Fuente | Fallback |
|-----|--------|----------|
| Primary | Vibrant / Dominant | Theme primary |
| Secondary | Muted / LightVibrant | Theme secondary |
| Surface | SurfaceVariant (baja saturación) | Theme surface |
| OnPrimary | OnColor (contraste WCAG AA) | White/Black |
| Accent | DarkVibrant / Vibrant | Theme tertiary |

### Animaciones Clave
- Hero transition: Library → Now Playing (carátula)
- Shared axis transition: Entre tabs
- Staggered entrance: List items
- Color morphing: Cambio de pista (500ms easeInOut)
- Blur intensity: Scroll parallax en Now Playing

---

## Base de Datos (Drift/SQLite)

```sql
-- songs
CREATE TABLE songs (
  id INTEGER PRIMARY KEY,
  path TEXT UNIQUE NOT NULL,
  title TEXT,
  artist TEXT,
  album TEXT,
  album_artist TEXT,
  genre TEXT,
  year INTEGER,
  track_number INTEGER,
  disc_number INTEGER,
  duration INTEGER,
  artwork_path TEXT,
  date_added INTEGER,
  play_count INTEGER DEFAULT 0,
  last_played INTEGER,
  folder_id INTEGER REFERENCES folders(id)
);

-- folders
CREATE TABLE folders (
  id INTEGER PRIMARY KEY,
  path TEXT UNIQUE NOT NULL,
  name TEXT,
  is_enabled INTEGER DEFAULT 1,
  last_scanned INTEGER
);

-- playlists
CREATE TABLE playlists (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  artwork_path TEXT,
  created_at INTEGER,
  updated_at INTEGER,
  is_smart INTEGER DEFAULT 0,
  smart_query TEXT
);

-- playlist_songs
CREATE TABLE playlist_songs (
  playlist_id INTEGER REFERENCES playlists(id) ON DELETE CASCADE,
  song_id INTEGER REFERENCES songs(id) ON DELETE CASCADE,
  position INTEGER,
  PRIMARY KEY (playlist_id, song_id)
);

-- equalizer_presets
CREATE TABLE equalizer_presets (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  bands TEXT NOT NULL, -- JSON: [gain1, gain2, ...]
  preamp REAL DEFAULT 0,
  bass_boost REAL DEFAULT 0,
  virtualizer REAL DEFAULT 0,
  is_custom INTEGER DEFAULT 1
);

-- settings (key-value)
CREATE TABLE settings (
  key TEXT PRIMARY KEY,
  value TEXT
);
```

---

## Fases de Desarrollo

### Fase 1: Fundación (Semanas 1-3)
- [ ] Setup proyecto + CI/CD (GitHub Actions / Codemagic)
- [ ] Arquitectura base (Clean Architecture + Riverpod/Bloc)
- [ ] Tema base + Glassmorphism components library
- [ ] Permisos + MediaStore / PhotoKit integration
- [ ] Escaneo de carpetas + parsing metadata (media_metadata_retriever / mp4parser)
- [ ] DB schema + Repository pattern
- [ ] Tests unitarios (repositories, usecases)

### Fase 2: Reproductor Core (Semanas 4-6)
- [ ] Audio engine (just_audio + background)
- [ ] MediaSession / MediaNotification / Lock screen controls
- [ ] Now Playing screen + Hero animations
- [ ] Cola de reproducción + modos (repeat/shuffle)
- [ ] Extracción colores + aplicación tema dinámico
- [ ] Sleep timer + velocidad de reproducción
- [ ] Tests de integración (playback)

### Fase 3: Ecualizador (Semanas 7-8)
- [ ] Platform channels: Android (AudioFx) / iOS (AudioUnit)
- [ ] UI ecualizador (10 bandas + presets)
- [ ] Persistencia + auto-aplicar por dispositivo BT
- [ ] Tests en dispositivos reales (latencia, battery)

### Fase 4: Biblioteca y Playlists (Semanas 9-11)
- [ ] Vistas: Artistas, Álbumes, Géneros, Carpetas
- [ ] Búsqueda + filtros
- [ ] CRUD Playlists + Smart playlists
- [ ] Drag & drop (reorder, add to playlist)
- [ ] Import/Export M3U

### Fase 5: Personalización y Temas (Semanas 12-13)
- [ ] Settings screen completo
- [ ] Color picker + live preview
- [ ] Blur/opacity/radius controls
- [ ] Export/Import temas
- [ ] Fuentes personalizadas

### Fase 6: Widgets (Semanas 14-15)
- [ ] Android Glance widget (3 tamaños)
- [ ] iOS WidgetKit + Live Activity
- [ ] Sincronización via MediaSession/NowPlayingCenter
- [ ] Tests en launchers distintos

### Fase 7: Pulido y Release (Semanas 16-18)
- [ ] Accesibilidad (TalkBack/VoiceOver, escalado fuente)
- [ ] Performance: lazy loading imágenes, pagination, isolate para scan
- [ ] Onboarding + permisos explicados
- [ ] Crashlytics / Sentry + Analytics (opt-in)
- [ ] Store listings (Play Store / App Store)
- [ ] Beta testing (TestFlight / Play Console Internal)

---

## Consideraciones Técnicas Críticas

### Android
- **Foreground Service** tipo `mediaPlayback` para background audio
- **Media3/ExoPlayer** alternativa si just_audio falla en edge cases
- **Scoped Storage**: MediaStore para Android 10+, SAF para carpetas custom
- **Bluetooth**: MediaButtonReceiver para controles de auriculares
- **Doze mode**: Whitelist o foreground service persistente

### iOS
- **Audio Session**: Category `playback`, mode `default`, options `mixWithOthers` + `allowBluetooth`
- **Background Modes**: Audio, AirPlay, Picture in Picture
- **NowPlayingInfoCenter** + **MPRemoteCommandCenter**
- **File Access**: Security-scoped bookmarks para carpetas fuera de sandbox
- **Widgets**: TimelineProvider + App Groups para compartir datos

### Rendimiento
- Imágenes: `cached_network_image` + `flutter_cache_manager` (thumbnails 200x200)
- Listas: `SliverList` + `AutomaticKeepAliveClientMixin`
- Scan: Isolate/Compute para parsing metadata (no bloquear UI)
- DB: Índices en `artist`, `album`, `folder_id`, `title`

---

## Métricas de Éxito
- Cold start < 1.5s
- Scan 10k canciones < 30s
- Cambio de pista < 200ms
- Widget update latency < 500ms
- Battery drain < 3%/hora reproducción
- Crash-free rate > 99.5%

---

## Riesgos y Mitigación
| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| Ecualizador nativo inestable | Media | Alto | Fallback a DSP software (rubberband) |
| Permisos Android 14+ restrictivos | Alta | Alto | Test early, usar MediaStore principalmente |
| Widget iOS no actualiza en tiempo real | Media | Medio | Live Activity + push notifications silenciosas |
| Colores dinámicos poco contrastados | Media | Medio | WCAG AA check + fallback a theme colors |
| Background kill en China ROMs | Media | Alto | Foreground service + autostart permission guide |

---

## Próximos Pasos Inmediatos
1. Decidir stack final (Flutter vs React Native)
2. Crear repositorio + configurar CI
3. Implementar tema base + glass components
4. Prototipo: Scan carpeta → lista → play → now playing
5. Validar ecualizador nativo en device real