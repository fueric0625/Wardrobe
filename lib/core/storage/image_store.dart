import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:wardrobe/core/storage/app_paths.dart';

class ImageStore {
  Directory? _dir;

  Future<void> init() async {
    final root = await AppPaths.ensureSupportDirectory();
    _dir = Directory(p.join(root.path, 'images'));
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

  Future<String> importFile(String sourcePath) async {
    final ext = p.extension(sourcePath);
    final dest = p.join(directory.path, '${const Uuid().v4()}$ext');
    await File(sourcePath).copy(dest);
    return dest;
  }

  Future<String> writeBytes(Uint8List bytes, String extension) async {
    final ext = extension.startsWith('.') ? extension : '.$extension';
    final dest = p.join(directory.path, '${const Uuid().v4()}$ext');
    await File(dest).writeAsBytes(bytes, flush: true);
    return dest;
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
