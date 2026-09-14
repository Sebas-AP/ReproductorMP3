import 'package:reproductor_musica/data/datasources/local/app_database.dart' as db;
import 'package:reproductor_musica/domain/repositories/media_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final db.SettingsDao _dao;

  SettingsRepositoryImpl(this._dao);

  @override
  Future<String?> getSetting(String key) {
    return _dao.getSetting(key);
  }

  @override
  Future<void> setSetting(String key, String value) {
    return _dao.setSetting(key, value);
  }

  @override
  Future<void> deleteSetting(String key) {
    return _dao.deleteSetting(key);
  }

  @override
  Future<Map<String, String>> getAllSettings() {
    return _dao.getAllSettings();
  }
}