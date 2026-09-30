import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:wardrobe/core/storage/app_paths.dart';
import 'package:wardrobe/features/wardrobe/detail_layout.dart';

class DetailLayoutStore {
  static Future<File> _file() async {
    final dir = await AppPaths.ensureSupportDirectory();
    return File(p.join(dir.path, 'detail_layout.json'));
  }

  static Future<DetailLayout> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return DetailLayout.standard;
      return decodeDetailLayout(await file.readAsString());
    } catch (_) {
      return DetailLayout.standard;
    }
  }

  static Future<void> write(DetailLayout layout) async {
    final file = await _file();
    await file.writeAsString(encodeDetailLayout(layout));
  }
}

final detailLayoutSeedProvider = Provider<DetailLayout>(
  (ref) => DetailLayout.standard,
);

class DetailLayoutNotifier extends Notifier<DetailLayout> {
  @override
  DetailLayout build() => ref.watch(detailLayoutSeedProvider);

  Future<void> move(int from, int to) {
    return _save(moveDetailSlot(state, from, to));
  }

  Future<void> setVisible(String id, bool visible) {
    return _save(setDetailSlotVisible(state, id, visible));
  }

  Future<bool> addCustom({
    required String label,
    required DetailSlotKind kind,
    required List<String> options,
  }) async {
    final slot = customDetailSlot(
      id: 'c_${const Uuid().v4()}',
      label: label,
      kind: kind,
      options: options,
    );
    if (slot == null) return false;
    await _save(appendCustomSlot(state, slot));
    return true;
  }

  Future<bool> removeCustom(String id) async {
    final next = removeCustomSlot(state, id);
    if (next.slots.length == state.slots.length) return false;
    await _save(next);
    return true;
  }

  Future<void> _save(DetailLayout next) async {
    state = next;
    await DetailLayoutStore.write(next);
  }
}

final detailLayoutProvider =
    NotifierProvider<DetailLayoutNotifier, DetailLayout>(
      DetailLayoutNotifier.new,
    );
