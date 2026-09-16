import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reproductor_musica/presentation/widgets/glass_widgets.dart';
import 'package:reproductor_musica/presentation/providers/theme_provider.dart';
import 'package:reproductor_musica/presentation/providers/service_providers.dart';
import 'package:reproductor_musica/presentation/providers/repository_providers.dart';
import 'package:reproductor_musica/core/constants/app_constants.dart';
import 'package:reproductor_musica/domain/entities/media.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  List<Folder> _folders = [];

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final repository = ref.read(folderRepositoryProvider);
    final folders = await repository.getAllFolders();
    setState(() {
      _folders = folders;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = ref.read(themeProvider.notifier);
    final userTheme = ref.read(themeProvider.notifier).userTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Ajustes'),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildSection(
                'Apariencia',
                [
                  _buildThemeModeTile(themeNotifier, userTheme),
                  _buildDynamicColorsTile(themeNotifier, userTheme),
                  _buildPrimaryColorTile(themeNotifier, userTheme),
                  _buildSecondaryColorTile(themeNotifier, userTheme),
                  _buildBlurIntensityTile(themeNotifier, userTheme),
                  _buildSurfaceOpacityTile(themeNotifier, userTheme),
                  _buildBorderRadiusTile(themeNotifier, userTheme),
                ],
              ),
              _buildSection(
                'Biblioteca',
                [
                  _buildFoldersTile(),
                  _buildScanTile(),
                  _buildAutoScanTile(),
                ],
              ),
              _buildSection(
                'Reproducción',
                [
                  _buildCrossfadeTile(),
                  _buildNormalizeVolumeTile(),
                  _buildGaplessPlaybackTile(),
                ],
              ),
              _buildSection(
                'Ecualizador',
                [
                  _buildEqualizerEnabledTile(),
                  _buildEqualizerPresetTile(),
                ],
              ),
              _buildSection(
                'Avanzado',
                [
                  _buildCacheTile(),
                  _buildBackupTile(),
                  _buildAboutTile(),
                ],
              ),
              const SizedBox(height: 100),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        GlassCard(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildThemeModeTile(ThemeNotifier notifier, UserTheme userTheme) {
    return _buildSettingsTile(
      title: 'Tema',
      subtitle: userTheme.isDark ? 'Oscuro' : 'Claro',
      leading: Icons.palette_outlined,
      trailing: Switch(
        value: userTheme.isDark,
        onChanged: (v) => notifier.setThemeMode(v),
      ),
    );
  }

  Widget _buildDynamicColorsTile(ThemeNotifier notifier, UserTheme userTheme) {
    return _buildSettingsTile(
      title: 'Colores dinámicos',
      subtitle: 'Basados en la carátula de la canción',
      leading: Icons.color_lens_outlined,
      trailing: Switch(
        value: userTheme.dynamicColors,
        onChanged: (v) => notifier.setDynamicColors(v),
      ),
    );
  }

  Widget _buildPrimaryColorTile(ThemeNotifier notifier, UserTheme userTheme) {
    return _buildSettingsTile(
      title: 'Color primario',
      subtitle: 'Color principal de la interfaz',
      leading: Icons.colorize_outlined,
      onTap: () => _showColorPicker(notifier.setPrimaryColor, userTheme.primaryColor),
    );
  }

  Widget _buildSecondaryColorTile(ThemeNotifier notifier, UserTheme userTheme) {
    return _buildSettingsTile(
      title: 'Color secundario',
      subtitle: 'Color de acento',
      leading: Icons.brush_outlined,
      onTap: () => _showColorPicker(notifier.setSecondaryColor, userTheme.secondaryColor),
    );
  }

  Widget _buildBlurIntensityTile(ThemeNotifier notifier, UserTheme userTheme) {
    return _buildSettingsTile(
      title: 'Intensidad del desenfoque',
      subtitle: '${userTheme.blurIntensity.round()}',
      leading: Icons.blur_on_outlined,
      child: SizedBox(
        width: 200,
        child: Slider(
          value: userTheme.blurIntensity,
          onChanged: (v) => notifier.setBlurIntensity(v),
          min: 0,
          max: 30,
          divisions: 30,
        ),
      ),
    );
  }

  Widget _buildSurfaceOpacityTile(ThemeNotifier notifier, UserTheme userTheme) {
    return _buildSettingsTile(
      title: 'Opacidad de superficies',
      subtitle: '${(userTheme.surfaceOpacity * 100).round()}%',
      leading: Icons.opacity_outlined,
      child: SizedBox(
        width: 200,
        child: Slider(
          value: userTheme.surfaceOpacity,
          onChanged: (v) => notifier.setSurfaceOpacity(v),
          min: 0.05,
          max: 0.9,
          divisions: 17,
        ),
      ),
    );
  }

  Widget _buildBorderRadiusTile(ThemeNotifier notifier, UserTheme userTheme) {
    return _buildSettingsTile(
      title: 'Radio de bordes',
      subtitle: '${userTheme.borderRadius.round()}',
      leading: Icons.rounded_corner_outlined,
      child: SizedBox(
        width: 200,
        child: Slider(
          value: userTheme.borderRadius,
          onChanged: (v) => notifier.setBorderRadius(v),
          min: 0,
          max: 32,
          divisions: 32,
        ),
      ),
    );
  }

  Widget _buildFoldersTile() {
    return _buildSettingsTile(
      title: 'Carpetas de música',
      subtitle: '${_folders.where((f) => f.isEnabled).length} seleccionadas',
      leading: Icons.folder_outlined,
      onTap: _showFolderPicker,
    );
  }

  Widget _buildScanTile() {
    return _buildSettingsTile(
      title: 'Escanear biblioteca',
      subtitle: 'Buscar nuevas canciones en las carpetas',
      leading: Icons.refresh_outlined,
      onTap: _scanLibrary,
    );
  }

  Widget _buildAutoScanTile() {
    final prefs = ref.watch(settingsRepositoryProvider);
    return FutureBuilder<String?>(
      future: prefs.getSetting(AppConstants.prefsAutoScan),
      builder: (context, snapshot) {
        final enabled = snapshot.data == 'true';
        return _buildSettingsTile(
          title: 'Escanear automáticamente',
          subtitle: 'Al iniciar la aplicación',
          leading: Icons.autorenew_outlined,
          trailing: Switch(
            value: enabled,
            onChanged: (v) async {
              await prefs.setSetting(AppConstants.prefsAutoScan, v.toString());
              setState(() {});
            },
          ),
        );
      },
    );
  }

  Widget _buildCrossfadeTile() {
    return _buildSettingsTile(
      title: 'Crossfade',
      subtitle: 'Transición suave entre canciones',
      leading: Icons.blur_linear_outlined,
      child: SizedBox(
        width: 200,
        child: Slider(
          value: 0,
          onChanged: (_) {},
          min: 0,
          max: 12,
          divisions: 12,
          label: '0s',
        ),
      ),
    );
  }

  Widget _buildNormalizeVolumeTile() {
    return _buildSettingsTile(
      title: 'Normalizar volumen',
      subtitle: 'ReproductorGain / EBU R128',
      leading: Icons.volume_up_outlined,
      trailing: Switch(value: false, onChanged: (_) {}),
    );
  }

  Widget _buildGaplessPlaybackTile() {
    return _buildSettingsTile(
      title: 'Reproducción sin pausas',
      subtitle: 'Eliminar silencios entre pistas',
      leading: Icons.skip_next_outlined,
      trailing: Switch(value: true, onChanged: (_) {}),
    );
  }

  Widget _buildEqualizerEnabledTile() {
    final eqService = ref.read(equalizerServiceProvider);
    return _buildSettingsTile(
      title: 'Ecualizador',
      subtitle: eqService.isEnabled ? 'Activado' : 'Desactivado',
      leading: Icons.equalizer_outlined,
      trailing: Switch(
        value: eqService.isEnabled,
        onChanged: (v) => eqService.setEnabled(v),
      ),
    );
  }

  Widget _buildEqualizerPresetTile() {
    final eqService = ref.read(equalizerServiceProvider);
    return _buildSettingsTile(
      title: 'Preset actual',
      subtitle: eqService.currentPreset?.name ?? 'Personalizado',
      leading: Icons.tune_outlined,
      onTap: () {},
    );
  }

  Widget _buildCacheTile() {
    return _buildSettingsTile(
      title: 'Limpiar caché',
      subtitle: 'Eliminar imágenes temporales',
      leading: Icons.cleaning_services_outlined,
      onTap: _clearCache,
    );
  }

  Widget _buildBackupTile() {
    return _buildSettingsTile(
      title: 'Respaldar y restaurar',
      subtitle: 'Base de datos y ajustes',
      leading: Icons.backup_outlined,
      onTap: _showBackupDialog,
    );
  }

  Widget _buildAboutTile() {
    return _buildSettingsTile(
      title: 'Acerca de',
      subtitle: 'Versión ${AppConstants.appVersion}',
      leading: Icons.info_outlined,
      onTap: _showAboutDialog,
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData leading,
    Widget? trailing,
    Widget? child,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(leading, color: colorScheme.onPrimaryContainer, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            if (child != null) child,
            if (trailing != null) trailing,
            if (onTap != null && child == null && trailing == null)
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  void _showColorPicker(Function(Color) onColorSelected, Color currentColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildColorPickerSheet(onColorSelected, currentColor),
    );
  }

  Widget _buildColorPickerSheet(Function(Color) onColorSelected, Color currentColor) {
    final theme = Theme.of(context);

    final materialColors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    ];

    return GlassModalSheet(
      maxHeight: 500,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Seleccionar color', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: materialColors.map((color) => _buildColorOption(color, currentColor, onColorSelected)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildColorOption(Color color, Color currentColor, Function(Color) onSelected) {
    final isSelected = color.value == currentColor.value;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () {
        onSelected(color);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? theme.colorScheme.onSurface : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 24)
            : null,
      ),
    );
  }

  void _showFolderPicker() {
    // TODO: Implement folder picker using file_picker or platform channels
  }

  Future<void> _scanLibrary() async {
    final scanner = ref.read(mediaScannerProvider);
    await scanner.scanAllFolders();
    await _loadFolders();
  }

  void _clearCache() {
    // TODO: Clear image cache
  }

  void _showBackupDialog() {
    // TODO: Show backup/restore dialog
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: const Icon(Icons.music_note, size: 48),
    );
  }
}