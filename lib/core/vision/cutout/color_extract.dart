import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:wardrobe/core/serialization/color_analysis_codec.dart';
import 'package:wardrobe/core/vision/cutout/image_ops.dart';

class ColorShare {
  const ColorShare({required this.name, required this.ratio});

  final String name;
  final double ratio;

  Map<String, Object> toJson() => {'name': name, 'ratio': ratio};

  factory ColorShare.fromJson(Map<String, dynamic> json) {
    return ColorShare(
      name: json['name'] as String? ?? '',
      ratio: (json['ratio'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RgbSwatch {
  const RgbSwatch(this.r, this.g, this.b);

  final int r;
  final int g;
  final int b;

  Map<String, int> toJson() => {'r': r, 'g': g, 'b': b};

  factory RgbSwatch.fromJson(Map<String, dynamic> json) {
    return RgbSwatch(
      (json['r'] as num?)?.round() ?? 0,
      (json['g'] as num?)?.round() ?? 0,
      (json['b'] as num?)?.round() ?? 0,
    );
  }
}

class ColorAnalysis {
  const ColorAnalysis(this.colors, {this.palette = const []});

  static const empty = ColorAnalysis([]);

  final List<ColorShare> colors;
  final List<RgbSwatch> palette;

  bool get isEmpty => colors.isEmpty;

  bool get hasPalette => palette.isNotEmpty;

  String get label => colors.map((c) => c.name).join('、');

  String get detail =>
      colors.map((c) => '${c.name} ${(c.ratio * 100).round()}%').join(' · ');

  String toJson() => encodeColorAnalysis(this);

  factory ColorAnalysis.decode(String raw) => decodeColorAnalysis(raw);
}

/// Names a single sRGB pixel. Exposed for tests.
String colorNameFromRgb(int r, int g, int b) {
  final hsv = _rgbToHsv(r, g, b);
  final h = hsv[0];
  final s = hsv[1];
  final v = hsv[2];

  if (v < 0.16) return '黑';
  if (s < 0.12) {
    if (v > 0.86) return '白';
    if (v > 0.58) return '浅灰';
    return '灰';
  }
  if (h >= 18 && h < 50 && v < 0.52 && s >= 0.22 && s < 0.78) return '棕';
  if (h >= 28 && h < 58 && v >= 0.62 && s < 0.42) return '米';
  if ((h >= 320 || h < 18) && s < 0.55 && v > 0.72) return '粉';
  if (h < 18 || h >= 345) return '红';
  if (h < 40) return '橙';
  if (h < 68) return '黄';
  if (h < 165) return '绿';
  if (h < 195) return '青';
  if (h < 255) return '蓝';
  if (h < 320) return '紫';
  return '粉';
}

ColorAnalysis extractColors(
  img.Image image, {
  img.Image? mask,
  double minRatio = 0.08,
}) {
  final counts = <String, int>{};
  var total = 0;
  final pixels = image.width * image.height;
  final stride = math.max(1, pixels ~/ 24000);

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final i = y * image.width + x;
      if (i % stride != 0) continue;
      if (mask != null) {
        if (x >= mask.width || y >= mask.height) continue;
        if (maskLevel(mask.getPixel(x, y)) < 128) continue;
      } else if (image.numChannels >= 4 && image.getPixel(x, y).a < 128) {
        continue;
      }
      final p = image.getPixel(x, y);
      final name = colorNameFromRgb(p.r.toInt(), p.g.toInt(), p.b.toInt());
      counts[name] = (counts[name] ?? 0) + 1;
      total++;
    }
  }

  if (total == 0) return ColorAnalysis.empty;

  final merged = <String, int>{};
  for (final entry in counts.entries) {
    final name = entry.key == '浅灰' ? '灰' : entry.key;
    merged[name] = (merged[name] ?? 0) + entry.value;
  }

  final ranked = merged.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final shares = <ColorShare>[
    for (final entry in ranked)
      if (entry.value / total >= minRatio)
        ColorShare(name: entry.key, ratio: entry.value / total),
  ];
  if (shares.isEmpty) {
    final top = ranked.first;
    shares.add(ColorShare(name: top.key, ratio: top.value / total));
  }
  return ColorAnalysis(shares.take(3).toList());
}

List<double> _rgbToHsv(int r, int g, int b) {
  final rf = r / 255.0;
  final gf = g / 255.0;
  final bf = b / 255.0;
  final max = math.max(rf, math.max(gf, bf));
  final min = math.min(rf, math.min(gf, bf));
  final delta = max - min;
  var h = 0.0;
  if (delta != 0) {
    if (max == rf) {
      h = ((gf - bf) / delta) % 6;
    } else if (max == gf) {
      h = (bf - rf) / delta + 2;
    } else {
      h = (rf - gf) / delta + 4;
    }
    h *= 60;
    if (h < 0) h += 360;
  }
  final s = max == 0 ? 0.0 : delta / max;
  return [h, s, max];
}
