import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

const wardrobeBackupFiles = [
  'wardrobe.sqlite',
  'wardrobe.sqlite-wal',
  'wardrobe.sqlite-shm',
  'appearance.json',
  'detail_layout.json',
  'list_sort.json',
  'font.txt',
];

const wardrobeBackupNote = '''
这是衣橱的本机备份，包含数据库、图片，以及外观、布局和排序。
没有抠图和识别用的模型。下次打开衣橱时会自己准备模型。

要恢复：打开衣橱的设置，点「导入备份」，选这个文件夹。
如果衣橱打不开，先完全退出，把这个文件夹里的文件和 images 文件夹拷到
%APPDATA%\\wardrobe\\
盖过同名文件，再打开衣橱。不要拷 models。
''';

const _importStagingName = 'import-staging';
const _importRollbackName = 'import-rollback';

/// Copies the local wardrobe into a new folder under [destinationParent].
///
/// [beforeCopy] runs first so the caller can checkpoint the open database.
/// Model files are left behind.
Future<Directory> exportWardrobeBackup({
  required Directory source,
  required Directory destinationParent,
  DateTime? now,
  Future<void> Function()? beforeCopy,
}) async {
  final database = File(p.join(source.path, 'wardrobe.sqlite'));
  if (!await database.exists()) {
    throw StateError('没有找到衣橱数据库');
  }
  if (beforeCopy != null) await beforeCopy();

  final stamp = DateFormat('yyyyMMdd-HHmm').format(now ?? DateTime.now());
  var dest = Directory(
    p.join(destinationParent.path, 'wardrobe-backup-$stamp'),
  );
  var extra = 2;
  while (await dest.exists()) {
    dest = Directory(
      p.join(destinationParent.path, 'wardrobe-backup-$stamp-$extra'),
    );
    extra++;
  }
  await dest.create(recursive: true);

  for (final name in wardrobeBackupFiles) {
    final file = File(p.join(source.path, name));
    if (!await file.exists()) continue;
    await file.copy(p.join(dest.path, name));
  }
  await _copyTree(
    Directory(p.join(source.path, 'images')),
    Directory(p.join(dest.path, 'images')),
  );
  await File(p.join(dest.path, '说明.txt')).writeAsString(wardrobeBackupNote);
  return dest;
}

/// Copies [backup] into a staging folder inside [destination].
///
/// The open database can stay in place. [commitWardrobeImport] does the swap
/// after the caller closes it.
Future<void> stageWardrobeImport({
  required Directory backup,
  required Directory destination,
  void Function(int copiedBytes, int totalBytes)? onProgress,
}) async {
  final database = File(p.join(backup.path, 'wardrobe.sqlite'));
  if (!await database.exists()) {
    throw StateError('这个文件夹里没有衣橱备份');
  }
  if (p.equals(
    p.normalize(backup.absolute.path),
    p.normalize(destination.absolute.path),
  )) {
    throw StateError('不能把正在使用的数据目录当成备份导入');
  }

  final staging = Directory(p.join(destination.path, _importStagingName));
  if (await staging.exists()) await staging.delete(recursive: true);
  await staging.create(recursive: true);

  var total = 0;
  if (onProgress != null) {
    for (final name in wardrobeBackupFiles) {
      final file = File(p.join(backup.path, name));
      if (await file.exists()) total += await file.length();
    }
    total += await _treeBytes(Directory(p.join(backup.path, 'images')));
    onProgress(0, total);
  }

  var copied = 0;
  void bump(int bytes) {
    copied += bytes;
    onProgress?.call(copied, total);
  }

  for (final name in wardrobeBackupFiles) {
    final file = File(p.join(backup.path, name));
    if (!await file.exists()) continue;
    await _copyFile(
      file,
      p.join(staging.path, name),
      onProgress == null ? null : bump,
    );
  }
  await _copyTree(
    Directory(p.join(backup.path, 'images')),
    Directory(p.join(staging.path, 'images')),
    onBytes: onProgress == null ? null : bump,
  );
}

/// Replaces the wardrobe files in [destination] with the staged backup.
///
/// Call this only after the database is closed. A leftover `-wal` from the
/// previous library is removed, so it is not replayed onto the imported file.
/// Model files stay. [beforeCleanup] runs after the swap and before the
/// temporary folders are deleted; a throw there restores the previous files.
///
/// The previous images are renamed aside and left for
/// [deleteAbandonedRollbacks]. Deleting them here would block the import on
/// every old file.
Future<void> commitWardrobeImport({
  required Directory destination,
  Future<void> Function()? beforeCleanup,
}) async {
  final staging = Directory(p.join(destination.path, _importStagingName));
  if (!await File(p.join(staging.path, 'wardrobe.sqlite')).exists()) {
    throw StateError('没有找到准备好的备份');
  }
  final rollback = Directory(
    p.join(
      destination.path,
      '$_importRollbackName-${DateTime.now().microsecondsSinceEpoch}',
    ),
  );
  await rollback.create();

  final swapped = <({String name, bool directory})>[];
  try {
    for (final name in wardrobeBackupFiles) {
      await _swapEntry(
        destination: destination,
        staging: staging,
        rollback: rollback,
        name: name,
        directory: false,
      );
      swapped.add((name: name, directory: false));
    }
    await _swapEntry(
      destination: destination,
      staging: staging,
      rollback: rollback,
      name: 'images',
      directory: true,
    );
    swapped.add((name: 'images', directory: true));
    if (beforeCleanup != null) await beforeCleanup();
  } catch (_) {
    for (final entry in swapped.reversed) {
      await _restoreEntry(
        destination: destination,
        staging: staging,
        rollback: rollback,
        name: entry.name,
        directory: entry.directory,
      );
    }
    rethrow;
  }

  try {
    if (await staging.exists()) await staging.delete(recursive: true);
  } catch (_) {}
}

/// Applies a staged import left by the previous process.
///
/// Retries while the previous process still has the files open. Returns
/// whether an import was waiting.
Future<bool> applyPendingWardrobeImport(Directory destination) async {
  final stagedDatabase = File(
    p.join(destination.path, _importStagingName, 'wardrobe.sqlite'),
  );
  if (!await stagedDatabase.exists()) return false;

  Object? lastError;
  for (var attempt = 0; attempt < 40; attempt++) {
    if (!await stagedDatabase.exists()) return true;
    try {
      await commitWardrobeImport(destination: destination);
      return true;
    } catch (error) {
      lastError = error;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
  }
  if (!await stagedDatabase.exists()) return true;
  Error.throwWithStackTrace(
    lastError ?? StateError('导入没有完成'),
    StackTrace.current,
  );
}

/// Deletes rollback folders left by a finished import. Safe to run while the
/// app is open; those files are no longer in use.
Future<void> deleteAbandonedRollbacks(Directory support) async {
  if (!await support.exists()) return;
  final pending = <Directory>[];
  await for (final entity in support.list(followLinks: false)) {
    if (entity is! Directory) continue;
    if (!p.basename(entity.path).startsWith(_importRollbackName)) continue;
    pending.add(entity);
  }
  for (final dir in pending) {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        if (await dir.exists()) await dir.delete(recursive: true);
        break;
      } catch (_) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
  }
}

Future<void> _swapEntry({
  required Directory destination,
  required Directory staging,
  required Directory rollback,
  required String name,
  required bool directory,
}) async {
  final livePath = p.join(destination.path, name);
  final asidePath = p.join(rollback.path, name);
  final stagedPath = p.join(staging.path, name);
  final live = directory ? Directory(livePath) : File(livePath);
  var movedAside = false;
  if (await live.exists()) {
    await live.rename(asidePath);
    movedAside = true;
  }
  try {
    final staged = directory ? Directory(stagedPath) : File(stagedPath);
    if (await staged.exists()) {
      await staged.rename(livePath);
    }
  } catch (_) {
    if (movedAside) {
      final aside = directory ? Directory(asidePath) : File(asidePath);
      final current = directory ? Directory(livePath) : File(livePath);
      if (await aside.exists() && !await current.exists()) {
        await aside.rename(livePath);
      }
    }
    rethrow;
  }
}

Future<void> _restoreEntry({
  required Directory destination,
  required Directory staging,
  required Directory rollback,
  required String name,
  required bool directory,
}) async {
  final livePath = p.join(destination.path, name);
  final stagedPath = p.join(staging.path, name);
  final savedPath = p.join(rollback.path, name);
  final live = directory ? Directory(livePath) : File(livePath);
  final staged = directory ? Directory(stagedPath) : File(stagedPath);
  final saved = directory ? Directory(savedPath) : File(savedPath);

  if (!await staged.exists() && await live.exists() && await saved.exists()) {
    await live.rename(stagedPath);
  }
  if (await saved.exists() &&
      !await (directory ? Directory(livePath) : File(livePath)).exists()) {
    await saved.rename(livePath);
  }
}

Future<int> _treeBytes(Directory dir) async {
  if (!await dir.exists()) return 0;
  var total = 0;
  await for (final entity in dir.list(followLinks: false)) {
    final name = p.basename(entity.path);
    if (name == '.tmp') continue;
    if (entity is Directory) {
      total += await _treeBytes(entity);
    } else if (entity is File) {
      total += await entity.length();
    }
  }
  return total;
}

Future<void> _copyFile(
  File from,
  String to,
  void Function(int bytes)? onBytes,
) async {
  if (onBytes == null) {
    await from.copy(to);
    return;
  }
  final sink = File(to).openWrite();
  try {
    await for (final chunk in from.openRead()) {
      sink.add(chunk);
      onBytes(chunk.length);
    }
    await sink.flush();
    await sink.close();
  } catch (_) {
    try {
      await sink.close();
    } catch (_) {}
    final partial = File(to);
    if (await partial.exists()) await partial.delete();
    rethrow;
  }
}

Future<void> _copyTree(
  Directory from,
  Directory to, {
  void Function(int bytes)? onBytes,
}) async {
  if (!await from.exists()) return;
  await to.create(recursive: true);
  await for (final entity in from.list(followLinks: false)) {
    final name = p.basename(entity.path);
    if (name == '.tmp') continue;
    final target = p.join(to.path, name);
    if (entity is Directory) {
      await _copyTree(entity, Directory(target), onBytes: onBytes);
    } else if (entity is File) {
      await _copyFile(entity, target, onBytes);
    }
  }
}
