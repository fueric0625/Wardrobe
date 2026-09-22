import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:wardrobe/core/storage/app_paths.dart';

class AppFontChoice {
  const AppFontChoice({required this.label, required this.family});

  final String label;
  final String family;
}

/// Faces that ship with Windows. No downloaded font files.
const appFontChoices = <AppFontChoice>[
  AppFontChoice(label: '等线', family: 'DengXian'),
  AppFontChoice(label: '微软雅黑', family: 'Microsoft YaHei UI'),
  AppFontChoice(label: '黑体', family: 'SimHei'),
  AppFontChoice(label: '楷体', family: 'KaiTi'),
  AppFontChoice(label: '宋体', family: 'SimSun'),
];

const defaultAppFontFamily = 'DengXian';

String resolveAppFont(String? raw) {
  final name = raw?.trim() ?? '';
  for (final choice in appFontChoices) {
    if (choice.family == name) return name;
  }
  return defaultAppFontFamily;
}

class AppFontStore {
  static Future<File> _file() async {
    final dir = await AppPaths.ensureSupportDirectory();
    return File(p.join(dir.path, 'font.txt'));
  }

  static Future<String> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return defaultAppFontFamily;
      return resolveAppFont(await file.readAsString());
    } catch (_) {
      return defaultAppFontFamily;
    }
  }

  static Future<void> write(String family) async {
    final file = await _file();
    await file.writeAsString(resolveAppFont(family));
  }
}

final appFontSeedProvider = Provider<String>((ref) => defaultAppFontFamily);

class AppFontNotifier extends Notifier<String> {
  @override
  String build() => resolveAppFont(ref.watch(appFontSeedProvider));

  Future<void> select(String family) async {
    final next = resolveAppFont(family);
    state = next;
    await AppFontStore.write(next);
  }
}

final appFontProvider = NotifierProvider<AppFontNotifier, String>(AppFontNotifier.new);
