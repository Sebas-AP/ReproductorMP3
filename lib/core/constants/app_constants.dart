class AppConstants {
  static const String appName = 'Reproductor Música';
  static const String appVersion = '1.0.0';

  static const String dbName = 'music_player.db';
  static const int dbVersion = 1;

  static const Duration scanDebounce = Duration(milliseconds: 500);
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const int pageSize = 50;

  static const List<int> equalizerBands = [31, 62, 125, 250, 500, 1000, 2000, 4000, 8000, 16000];
  static const double eqMinGain = -12.0;
  static const double eqMaxGain = 12.0;
  static const double eqDefaultGain = 0.0;

  static const List<String> supportedAudioExtensions = [
    'mp3', 'm4a', 'aac', 'flac', 'ogg', 'wav', 'opus', 'wma', 'alac', 'aiff'
  ];

  static const List<String> artworkExtensions = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];

  static const String prefsThemeMode = 'theme_mode';
  static const String prefsPrimaryColor = 'primary_color';
  static const String prefsSecondaryColor = 'secondary_color';
  static const String prefsBlurIntensity = 'blur_intensity';
  static const String prefsSurfaceOpacity = 'surface_opacity';
  static const String prefsBorderRadius = 'border_radius';
  static const String prefsDynamicColors = 'dynamic_colors';
  static const String prefsEqualizerEnabled = 'equalizer_enabled';
  static const String prefsEqualizerPreset = 'equalizer_preset';
  static const String prefsCrossfadeDuration = 'crossfade_duration';
  static const String prefsNormalizeVolume = 'normalize_volume';
  static const String prefsSleepTimer = 'sleep_timer';
  static const String prefsPlaybackSpeed = 'playback_speed';
  static const String prefsFolders = 'scan_folders';
  static const String prefsAutoScan = 'auto_scan';
  static const String prefsLastScanTime = 'last_scan_time';
}