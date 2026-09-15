import 'package:reproductor_musica/data/datasources/local/app_database.dart' as db;
import 'package:reproductor_musica/domain/entities/media.dart';
import 'package:reproductor_musica/domain/repositories/media_repository.dart';
import 'package:drift/drift.dart';

class FolderRepositoryImpl implements FolderRepository {
  final db.FolderDao _dao;

  FolderRepositoryImpl(this._dao);

  @override
  Future<List<Folder>> getAllFolders({bool enabledOnly = false}) async {
    final dbFolders = await _dao.getAllFolders(enabledOnly: enabledOnly);
    return dbFolders.map(_toEntity).toList();
  }

  @override
  Future<Folder?> getFolderById(int id) async {
    final dbFolder = await _dao.getFolderById(id);
    return dbFolder != null ? _toEntity(dbFolder) : null;
  }

  @override
  Future<Folder?> getFolderByPath(String path) async {
    final dbFolder = await _dao.getFolderByPath(path);
    return dbFolder != null ? _toEntity(dbFolder) : null;
  }

  @override
  Future<int> insertFolder(Folder folder) {
    return _dao.insertFolder(_toCompanion(folder));
  }

  @override
  Future<bool> updateFolder(Folder folder) {
    return _dao.updateFolder(_toCompanion(folder));
  }

  @override
  Future<int> deleteFolder(int id) {
    return _dao.deleteFolder(id);
  }

  @override
  Stream<List<Folder>> watchAllFolders() {
    return _dao.watchAllFolders().map((list) => list.map(_toEntity).toList());
  }

  Folder _toEntity(db.Folder folder) {
    return Folder(
      id: folder.id,
      path: folder.path,
      name: folder.name,
      isEnabled: folder.isEnabled,
      lastScanned: folder.lastScanned,
    );
  }

  db.FoldersCompanion _toCompanion(Folder folder) {
    return db.FoldersCompanion(
      id: folder.id != null ? Value(folder.id!) : const Value.absent(),
      path: Value(folder.path),
      name: Value(folder.name),
      isEnabled: Value(folder.isEnabled),
      lastScanned: Value(folder.lastScanned),
    );
  }
}