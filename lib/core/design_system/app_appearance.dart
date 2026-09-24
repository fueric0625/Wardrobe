import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:wardrobe/core/design_system/app_font.dart';
import 'package:wardrobe/core/storage/app_paths.dart';

class AppTextSizeChoice {
  const AppTextSizeChoice({
    required this.id,
    required this.label,
    required this.scale,
  });

  final String id;
  final String label;
  final double scale;
}

const appTextSizeChoices = <AppTextSizeChoice>[
  AppTextSizeChoice(id: 'small', label: '小', scale: 0.9),
  AppTextSizeChoice(id: 'standard', label: '标准', scale: 1),
  AppTextSizeChoice(id: 'large', label: '大', scale: 1.15),
  AppTextSizeChoice(id: 'xlarge', label: '特大', scale: 1.3),
];

const defaultAppTextSizeId = 'standard';

class AppColorChoice {
  const AppColorChoice({
    required this.id,
    required this.label,
    required this.primary,
  });

  final String id;
  final String label;
  final Color primary;

  Color get primarySoft => Color.alphaBlend(
    primary.withValues(alpha: 0.14),
    const Color(0xFFFFFFFF),
  );
}

const appColorChoices = <AppColorChoice>[
  AppColorChoice(id: 'blue', label: '蓝', primary: Color(0xFF5B6CFF)),
  AppColorChoice(id: 'teal', label: '青', primary: Color(0xFF1F8A7A)),
  AppColorChoice(id: 'orange', label: '橙', primary: Color(0xFFE07A3D)),
  AppColorChoice(id: 'rose', label: '玫红', primary: Color(0xFFD4537E)),
  AppColorChoice(id: 'purple', label: '紫', primary: Color(0xFF7B61FF)),
];

const defaultAppColorId = 'blue';

class AppAppearance {
  const AppAppearance({
    required this.fontFamily,
    required this.textSizeId,
    required this.colorId,
  });

  final String fontFamily;
  final String textSizeId;
  final String colorId;

  static const fallback = AppAppearance(
    fontFamily: defaultAppFontFamily,
    textSizeId: defaultAppTextSizeId,
    colorId: defaultAppColorId,
  );

  double get textScale => resolveAppTextSize(textSizeId).scale;

  AppColorChoice get color => resolveAppColor(colorId);

  AppAppearance copyWith({
    String? fontFamily,
    String? textSizeId,
    String? colorId,
  }) {
    return AppAppearance(
      fontFamily: fontFamily ?? this.fontFamily,
      textSizeId: textSizeId ?? this.textSizeId,
      colorId: colorId ?? this.colorId,
    );
  }
}

AppTextSizeChoice resolveAppTextSize(String? raw) {
  final id = raw?.trim() ?? '';
  for (final choice in appTextSizeChoices) {
    if (choice.id == id) return choice;
  }
  return appTextSizeChoices[1];
}

AppColorChoice resolveAppColor(String? raw) {
  final id = raw?.trim() ?? '';
  for (final choice in appColorChoices) {
    if (choice.id == id) return choice;
  }
  return appColorChoices.first;
}

AppAppearance resolveAppAppearance({
  String? fontFamily,
  String? textSizeId,
  String? colorId,
}) {
  return AppAppearance(
    fontFamily: resolveAppFont(fontFamily),
    textSizeId: resolveAppTextSize(textSizeId).id,
    colorId: resolveAppColor(colorId).id,
  );
}

String encodeAppAppearance(AppAppearance appearance) {
  return jsonEncode({
    'font': appearance.fontFamily,
    'textSize': appearance.textSizeId,
    'color': appearance.colorId,
  });
}

AppAppearance decodeAppAppearance(String raw, {String? fontFallback}) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) {
      return resolveAppAppearance(
        fontFamily: '${decoded['font'] ?? fontFallback ?? ''}',
        textSizeId: '${decoded['textSize'] ?? ''}',
        colorId: '${decoded['color'] ?? ''}',
      );
    }
  } catch (_) {}
  return resolveAppAppearance(fontFamily: fontFallback);
}

class AppAppearanceStore {
  static Future<File> _file() async {
    final dir = await AppPaths.ensureSupportDirectory();
    return File(p.join(dir.path, 'appearance.json'));
  }

  static Future<AppAppearance> read() async {
    final fontFallback = await AppFontStore.read();
    try {
      final file = await _file();
      if (!await file.exists()) {
        return resolveAppAppearance(fontFamily: fontFallback);
      }
      return decodeAppAppearance(
        await file.readAsString(),
        fontFallback: fontFallback,
      );
    } catch (_) {
      return resolveAppAppearance(fontFamily: fontFallback);
    }
  }

  static Future<void> write(AppAppearance appearance) async {
    final file = await _file();
    await file.writeAsString(encodeAppAppearance(appearance));
    await AppFontStore.write(appearance.fontFamily);
  }
}

final appAppearanceSeedProvider = Provider<AppAppearance>(
  (ref) => AppAppearance.fallback,
);

class AppAppearanceNotifier extends Notifier<AppAppearance> {
  @override
  AppAppearance build() => ref.watch(appAppearanceSeedProvider);

  Future<void> selectFont(String family) =>
      _save(state.copyWith(fontFamily: resolveAppFont(family)));

  Future<void> selectTextSize(String id) =>
      _save(state.copyWith(textSizeId: resolveAppTextSize(id).id));

  Future<void> selectColor(String id) =>
      _save(state.copyWith(colorId: resolveAppColor(id).id));

  Future<void> _save(AppAppearance next) async {
    state = next;
    await AppAppearanceStore.write(next);
  }
}

final appAppearanceProvider =
    NotifierProvider<AppAppearanceNotifier, AppAppearance>(
      AppAppearanceNotifier.new,
    );
