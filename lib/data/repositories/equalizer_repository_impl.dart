import 'package:reproductor_musica/data/datasources/local/app_database.dart' as db;
import 'package:reproductor_musica/domain/entities/media.dart';
import 'package:reproductor_musica/domain/repositories/media_repository.dart';
import 'package:drift/drift.dart';

class EqualizerRepositoryImpl implements EqualizerRepository {
  final db.EqualizerPresetDao _dao;

  EqualizerRepositoryImpl(this._dao);

  @override
  Future<List<EqualizerPreset>> getAllPresets() async {
    final dbPresets = await _dao.getAllPresets();
    return dbPresets.map(_toEntity).toList();
  }

  @override
  Future<EqualizerPreset?> getPresetById(int id) async {
    final dbPreset = await _dao.getPresetById(id);
    return dbPreset != null ? _toEntity(dbPreset) : null;
  }

  @override
  Future<int> insertPreset(EqualizerPreset preset) {
    return _dao.insertPreset(_toCompanion(preset));
  }

  @override
  Future<bool> updatePreset(EqualizerPreset preset) {
    return _dao.updatePreset(_toCompanion(preset));
  }

  @override
  Future<int> deletePreset(int id) {
    return _dao.deletePreset(id);
  }

  EqualizerPreset _toEntity(db.EqualizerPreset preset) {
    return EqualizerPreset(
      id: preset.id,
      name: preset.name,
      bands: _parseBands(preset.bands),
      preamp: preset.preamp,
      bassBoost: preset.bassBoost,
      virtualizer: preset.virtualizer,
      isCustom: preset.isCustom,
    );
  }

  db.EqualizerPresetsCompanion _toCompanion(EqualizerPreset preset) {
    return db.EqualizerPresetsCompanion(
      id: preset.id != null ? Value(preset.id!) : const Value.absent(),
      name: Value(preset.name),
      bands: Value(_encodeBands(preset.bands)),
      preamp: Value(preset.preamp),
      bassBoost: Value(preset.bassBoost),
      virtualizer: Value(preset.virtualizer),
      isCustom: Value(preset.isCustom),
    );
  }

  List<double> _parseBands(String json) {
    try {
      final list = json
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => double.parse(e.trim()))
          .toList();
      return list.length == 10 ? list : List.filled(10, 0.0);
    } catch (_) {
      return List.filled(10, 0.0);
    }
  }

  String _encodeBands(List<double> bands) {
    return '[${bands.map((e) => e.toStringAsFixed(1)).join(',')}]';
  }
}