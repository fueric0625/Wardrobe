import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/storage/wardrobe_backup.dart';

void main() {
  test(
    'export copies data and images and skips models and temp files',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'wardrobe-backup-test',
      );
      addTearDown(() => root.delete(recursive: true));
      final source = Directory('${root.path}\\source')..createSync();
      final parent = Directory('${root.path}\\out')..createSync();
      File('${source.path}\\wardrobe.sqlite').writeAsStringSync('db');
      File('${source.path}\\appearance.json').writeAsStringSync('{"font":"a"}');
      File('${source.path}\\models\\u2netp.onnx').createSync(recursive: true);
      File('${source.path}\\images\\coat.png').createSync(recursive: true);
      File('${source.path}\\images\\.tmp\\new.png').createSync(recursive: true);

      var checkpointed = false;
      final dest = await exportWardrobeBackup(
        source: source,
        destinationParent: parent,
        now: DateTime(2026, 9, 30, 15, 22),
        beforeCopy: () async {
          checkpointed = true;
        },
      );

      expect(checkpointed, isTrue);
      expect(dest.path, endsWith('wardrobe-backup-20260930-1522'));
      expect(File('${dest.path}\\wardrobe.sqlite').readAsStringSync(), 'db');
      expect(
        File('${dest.path}\\appearance.json').readAsStringSync(),
        '{"font":"a"}',
      );
      expect(File('${dest.path}\\images\\coat.png').existsSync(), isTrue);
      expect(File('${dest.path}\\images\\.tmp\\new.png').existsSync(), isFalse);
      expect(Directory('${dest.path}\\models').existsSync(), isFalse);
      expect(File('${dest.path}\\说明.txt').existsSync(), isTrue);
    },
  );

  test('a second export in the same minute gets another folder', () async {
    final root = await Directory.systemTemp.createTemp('wardrobe-backup-test');
    addTearDown(() => root.delete(recursive: true));
    final source = Directory('${root.path}\\source')..createSync();
    final parent = Directory('${root.path}\\out')..createSync();
    File('${source.path}\\wardrobe.sqlite').writeAsStringSync('db');
    final now = DateTime(2026, 9, 30, 15, 22);

    final first = await exportWardrobeBackup(
      source: source,
      destinationParent: parent,
      now: now,
    );
    final second = await exportWardrobeBackup(
      source: source,
      destinationParent: parent,
      now: now,
    );

    expect(first.path, isNot(second.path));
    expect(second.path, endsWith('wardrobe-backup-20260930-1522-2'));
  });

  test(
    'import replaces data and drops leftover wal without touching models',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'wardrobe-backup-test',
      );
      addTearDown(() => root.delete(recursive: true));
      final data = Directory('${root.path}\\data')..createSync();
      final backup = Directory('${root.path}\\backup')..createSync();
      File('${data.path}\\wardrobe.sqlite').writeAsStringSync('old');
      File('${data.path}\\wardrobe.sqlite-wal').writeAsStringSync('wal');
      File('${data.path}\\detail_layout.json')
          .writeAsStringSync('{"old":true}');
      File('${data.path}\\images\\old.png').createSync(recursive: true);
      File('${data.path}\\models\\u2netp.onnx')
        ..createSync(recursive: true)
        ..writeAsStringSync('model');
      File('${backup.path}\\wardrobe.sqlite').writeAsStringSync('new');
      File('${backup.path}\\appearance.json').writeAsStringSync('{"font":"b"}');
      File('${backup.path}\\images\\coat.png').createSync(recursive: true);
      File('${backup.path}\\images\\.tmp\\new.png').createSync(recursive: true);
      File('${backup.path}\\说明.txt').writeAsStringSync('note');

      await stageWardrobeImport(backup: backup, destination: data);
      await commitWardrobeImport(destination: data);

      expect(File('${data.path}\\wardrobe.sqlite').readAsStringSync(), 'new');
      expect(File('${data.path}\\wardrobe.sqlite-wal').existsSync(), isFalse);
      expect(File('${data.path}\\detail_layout.json').existsSync(), isFalse);
      expect(
        File('${data.path}\\appearance.json').readAsStringSync(),
        '{"font":"b"}',
      );
      expect(File('${data.path}\\images\\coat.png').existsSync(), isTrue);
      expect(File('${data.path}\\images\\old.png').existsSync(), isFalse);
      expect(File('${data.path}\\images\\.tmp\\new.png').existsSync(), isFalse);
      expect(
        File('${data.path}\\models\\u2netp.onnx').readAsStringSync(),
        'model',
      );
      expect(File('${data.path}\\说明.txt').existsSync(), isFalse);
      expect(Directory('${data.path}\\import-staging').existsSync(), isFalse);
      final rollback = Directory(data.path)
          .listSync()
          .whereType<Directory>()
          .where((dir) => dir.path.contains('import-rollback'))
          .toList();
      expect(rollback, isNotEmpty);
      expect(
        File('${rollback.single.path}\\images\\old.png').existsSync(),
        isTrue,
      );

      await deleteAbandonedRollbacks(data);
      expect(
        Directory(data.path)
            .listSync()
            .whereType<Directory>()
            .any((dir) => dir.path.contains('import-rollback')),
        isFalse,
      );
    },
  );

  test('a failed import puts the previous files back', () async {
    final root = await Directory.systemTemp.createTemp('wardrobe-backup-test');
    addTearDown(() => root.delete(recursive: true));
    final data = Directory('${root.path}\\data')..createSync();
    final backup = Directory('${root.path}\\backup')..createSync();
    File('${data.path}\\wardrobe.sqlite').writeAsStringSync('old');
    File('${data.path}\\images\\old.png').createSync(recursive: true);
    File('${backup.path}\\wardrobe.sqlite').writeAsStringSync('new');
    File('${backup.path}\\images\\coat.png').createSync(recursive: true);

    await stageWardrobeImport(backup: backup, destination: data);
    await expectLater(
      commitWardrobeImport(
        destination: data,
        beforeCleanup: () async => throw StateError('stop'),
      ),
      throwsA(isA<StateError>()),
    );

    expect(File('${data.path}\\wardrobe.sqlite').readAsStringSync(), 'old');
    expect(File('${data.path}\\images\\old.png').existsSync(), isTrue);
    expect(File('${data.path}\\images\\coat.png').existsSync(), isFalse);
  });

  test('a folder without a database is refused', () async {
    final root = await Directory.systemTemp.createTemp('wardrobe-backup-test');
    addTearDown(() => root.delete(recursive: true));
    final data = Directory('${root.path}\\data')..createSync();
    final backup = Directory('${root.path}\\backup')..createSync();
    File('${data.path}\\wardrobe.sqlite').writeAsStringSync('old');

    await expectLater(
      stageWardrobeImport(backup: backup, destination: data),
      throwsA(isA<StateError>()),
    );
    expect(File('${data.path}\\wardrobe.sqlite').readAsStringSync(), 'old');
  });

  test('import progress reaches the full size and skips temp files', () async {
    final root = await Directory.systemTemp.createTemp('wardrobe-backup-test');
    addTearDown(() => root.delete(recursive: true));
    final data = Directory('${root.path}\\data')..createSync();
    final backup = Directory('${root.path}\\backup')..createSync();
    File('${backup.path}\\wardrobe.sqlite')
        .writeAsBytesSync(List.filled(20, 1));
    File('${backup.path}\\images\\coat.png').createSync(recursive: true);
    File('${backup.path}\\images\\coat.png')
        .writeAsBytesSync(List.filled(100, 2));
    File('${backup.path}\\images\\.tmp\\new.png').createSync(recursive: true);
    File('${backup.path}\\images\\.tmp\\new.png')
        .writeAsBytesSync(List.filled(50, 3));

    var total = 0;
    final steps = <int>[];
    await stageWardrobeImport(
      backup: backup,
      destination: data,
      onProgress: (copied, all) {
        total = all;
        steps.add(copied);
      },
    );

    expect(total, 120);
    expect(steps.first, 0);
    expect(steps.last, 120);
    for (var i = 1; i < steps.length; i++) {
      expect(steps[i], greaterThanOrEqualTo(steps[i - 1]));
    }
  });

  test('a staged import is applied before the next open', () async {
    final root = await Directory.systemTemp.createTemp('wardrobe-backup-test');
    addTearDown(() => root.delete(recursive: true));
    final data = Directory('${root.path}\\data')..createSync();
    final backup = Directory('${root.path}\\backup')..createSync();
    File('${data.path}\\wardrobe.sqlite').writeAsStringSync('old');
    File('${data.path}\\images\\old.png').createSync(recursive: true);
    File('${backup.path}\\wardrobe.sqlite').writeAsStringSync('new');
    File('${backup.path}\\images\\coat.png').createSync(recursive: true);

    await stageWardrobeImport(backup: backup, destination: data);
    expect(await applyPendingWardrobeImport(data), isTrue);
    expect(await applyPendingWardrobeImport(data), isFalse);

    expect(File('${data.path}\\wardrobe.sqlite').readAsStringSync(), 'new');
    expect(File('${data.path}\\images\\coat.png').existsSync(), isTrue);
    expect(File('${data.path}\\images\\old.png').existsSync(), isFalse);
    expect(
      Directory('${data.path}\\import-staging\\wardrobe.sqlite').existsSync(),
      isFalse,
    );
  });
}
