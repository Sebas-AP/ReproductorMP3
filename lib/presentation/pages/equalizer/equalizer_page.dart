import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:reproductor_musica/presentation/widgets/glass_widgets.dart';
import 'package:reproductor_musica/services/equalizer_service.dart';
import 'package:reproductor_musica/presentation/providers/service_providers.dart';
import 'package:reproductor_musica/presentation/providers/repository_providers.dart';
import 'package:reproductor_musica/domain/entities/media.dart';

class EqualizerPage extends ConsumerStatefulWidget {
  const EqualizerPage({super.key});

  @override
  ConsumerState<EqualizerPage> createState() => _EqualizerPageState();
}

class _EqualizerPageState extends ConsumerState<EqualizerPage> with TickerProviderStateMixin {
  late final List<AnimationController> _bandControllers;

  @override
  void initState() {
    super.initState();
    _bandControllers = List.generate(10, (i) => AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    ));
  }

  @override
  void dispose() {
    for (final c in _bandControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final equalizerState = ref.watch(equalizerStateProvider);
    final equalizerService = ref.watch(equalizerServiceProvider);
    final presetsAsync = ref.watch(_presetsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: const Text('Ecualizador'),
            actions: [
              GlassIconButton(
                icon: Icons.tune,
                onPressed: _showPresetDialog,
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverFillRemaining(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildEnableToggle(equalizerState, equalizerService),
                  const SizedBox(height: 24),
                  _buildBands(equalizerState, equalizerService),
                  const SizedBox(height: 24),
                  _buildBassVirtualizer(equalizerState, equalizerService),
                  const SizedBox(height: 24),
                  _buildPresets(presetsAsync, equalizerService),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnableToggle(AsyncValue<EqualizerState> state, EqualizerService service) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enabled = state.value?.enabled ?? false;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ecualizador',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ajusta el sonido a tu gusto',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) => service.setEnabled(value),
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildBands(AsyncValue<EqualizerState> state, EqualizerService service) {
    final theme = Theme.of(context);
    final gains = state.value?.gains ?? List.filled(10, 0.0);
    final enabled = state.value?.enabled ?? false;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Frecuencias', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(10, (i) => _buildBandSlider(i, gains[i], enabled, service)),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: EqualizerService.bandFrequencies.map((f) => _buildFrequencyLabel(f)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBandSlider(int index, double gain, bool enabled, EqualizerService service) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: 32,
      height: 200,
      child: RotatedBox(
        quarterTurns: -1,
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withOpacity(0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: gain,
            onChanged: enabled ? (v) => _onBandChanged(index, v, service) : null,
            min: EqualizerService.minGain,
            max: EqualizerService.maxGain,
            divisions: 24,
          ),
        ),
      ),
    ).animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideY(begin: 0.2, end: 0);
  }

  void _onBandChanged(int index, double value, EqualizerService service) {
    service.setGain(index, value);
    _bandControllers[index].forward(from: 0);
  }

  Widget _buildFrequencyLabel(int freq) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    String label;
    if (freq >= 1000) {
      label = '${freq ~/ 1000}k';
    } else {
      label = freq.toString();
    }
    return SizedBox(
      width: 32,
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }

  Widget _buildBassVirtualizer(AsyncValue<EqualizerState> state, EqualizerService service) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bassBoost = state.value?.bassBoost ?? 0.0;
    final virtualizer = state.value?.virtualizer ?? 0.0;
    final enabled = state.value?.enabled ?? false;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Efectos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          _buildEffectSlider('Bass Boost', Icons.graphic_eq, bassBoost, 0, 12,
              enabled ? (v) => service.setBassBoost(v) : null, colorScheme),
          const SizedBox(height: 16),
          _buildEffectSlider('Virtualizador', Icons.surround_sound, virtualizer, 0, 10,
              enabled ? (v) => service.setVirtualizer(v) : null, colorScheme),
          const SizedBox(height: 16),
          _buildEffectSlider('Preamp', Icons.volume_up, state.value?.preamp ?? 0.0,
              EqualizerService.minGain, EqualizerService.maxGain,
              enabled ? (v) => service.setPreamp(v) : null, colorScheme),
        ],
      ),
    );
  }

  Widget _buildEffectSlider(
    String label,
    IconData icon,
    double value,
    double min,
    double max,
    ValueChanged<double>? onChanged,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500)),
            const Spacer(),
            Text(value.toStringAsFixed(1), style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: colorScheme.primary,
            inactiveTrackColor: colorScheme.primary.withOpacity(0.2),
            thumbColor: colorScheme.primary,
            overlayColor: colorScheme.primary.withOpacity(0.15),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
            min: min,
            max: max,
            divisions: ((max - min) * 2).round(),
          ),
        ),
      ],
    );
  }

  Widget _buildPresets(AsyncValue<List<EqualizerPreset>> presetsAsync, EqualizerService service) {
    return presetsAsync.when(
      data: (presets) => GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Presets', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                  GlassIconButton(
                  icon: Icons.add,
                  size: 20,
                  onPressed: _showSavePresetDialog,
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: presets.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _buildPresetChip(presets[index], service, index),
              ),
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPresetChip(EqualizerPreset preset, EqualizerService service, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentPreset = ref.watch(equalizerStateProvider).value?.currentPreset;
    final isSelected = currentPreset?.id == preset.id;

    return GlassChip(
      label: preset.name,
      selected: isSelected,
      onTap: () => service.applyPreset(preset),
      backgroundColor: colorScheme.surfaceContainerHighest,
      selectedColor: colorScheme.primaryContainer,
    ).animate(delay: (index * 50).ms)
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.2, end: 0);
  }

  void _showPresetDialog() {
    // TODO: Show preset management dialog
  }

  void _showSavePresetDialog() {
    final controller = TextEditingController();
    final equalizerService = ref.read(equalizerServiceProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Guardar preset'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Nombre del preset'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                equalizerService.saveAsPreset(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}

final _presetsProvider = FutureProvider<List<EqualizerPreset>>((ref) async {
  final repository = ref.watch(equalizerRepositoryProvider);
  return repository.getAllPresets();
});