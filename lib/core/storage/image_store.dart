import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:wardrobe/core/storage/app_paths.dart';

class ImageStore {
  ImageStore({Directory? directory}) : _dir = directory;

  Directory? _dir;

  Future<void> init() async {
    if (_dir == null) {
      final root = await AppPaths.ensureSupportDirectory();
      _dir = Directory(p.join(root.path, 'images'));
    }
    if (!await _dir!.exists()) {
      await _dir!.create(recursive: true);
    }
  }

  Directory get directory {
    final dir = _dir;
    if (dir == null) {
      throw StateError('ImageStore.init() must be called first');
    }
    return dir;
  }

  bool isOwned(String? path) {
    if (path == null || path.isEmpty) return false;
    final normalizedDir = p.normalize(directory.path);
    final normalizedPath = p.normalize(path);
    return p.isWithin(normalizedDir, normalizedPath) ||
        normalizedPath == normalizedDir;
  }

  Directory get temporaryDirectory => Directory(p.join(directory.path, '.tmp'));

  bool isTemporary(String? path) {
    if (!isOwned(path)) return false;
    return p.isWithin(p.normalize(temporaryDirectory.path), p.normalize(path!));
  }

  Future<void> _ensureTemporary() async {
    final dir = temporaryDirectory;
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<ImageImport> beginImport(String sourcePath) async {
    await _ensureTemporary();
    final ext = p.extension(sourcePath);
    final name = '${const Uuid().v4()}$ext';
    final temp = p.join(temporaryDirectory.path, name);
    final dest = p.join(directory.path, name);
    await File(sourcePath).copy(temp);
    return ImageImport._(tempPath: temp, finalPath: dest);
  }

  ImageImport adoptTemporary(String tempPath) {
    return ImageImport._(
      tempPath: tempPath,
      finalPath: p.join(directory.path, p.basename(tempPath)),
    );
  }

  Future<ImageImport> beginBytes(Uint8List bytes, String extension) async {
    await _ensureTemporary();
    final ext = extension.startsWith('.') ? extension : '.$extension';
    final name = '${const Uuid().v4()}$ext';
    final temp = p.join(temporaryDirectory.path, name);
    final dest = p.join(directory.path, name);
    await File(temp).writeAsBytes(bytes, flush: true);
    return ImageImport._(tempPath: temp, finalPath: dest);
  }

  Future<String> importFile(String sourcePath) async {
    final op = await beginImport(sourcePath);
    await op.commit();
    return op.finalPath;
  }

  Future<String> writeBytes(Uint8List bytes, String extension) async {
    final op = await beginBytes(bytes, extension);
    await op.commit();
    return op.finalPath;
  }

  Future<String> importOrKeep(String sourcePath) async {
    if (isOwned(sourcePath)) return sourcePath;
    return importFile(sourcePath);
  }

  Future<void> deleteIfOwned(String? path) async {
    if (!isOwned(path)) return;
    final file = File(path!);
    if (await file.exists()) {
      await file.delete();
    }
  }
}

/// A file staged under `images/.tmp` until the database write succeeds.
class ImageImport {
  ImageImport._({required this.tempPath, required this.finalPath});

  final String tempPath;
  final String finalPath;
  bool _committed = false;

  Future<void> commit() async {
    if (_committed) return;
    final source = File(tempPath);
    if (!await source.exists()) {
      throw StateError('临时图片不存在');
    }
    try {
      await source.rename(finalPath);
    } on FileSystemException {
      await source.copy(finalPath);
      await source.delete();
    }
    _committed = true;
  }

  Future<void> rollback() async {
    if (_committed) return;
    final file = File(tempPath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
