import 'package:image/image.dart' as img;
import 'package:wardrobe/core/vision/cutout/color_extract.dart';
import 'package:wardrobe/core/vision/cutout/color_guide.dart';
import 'package:wardrobe/core/vision/cutout/image_ops.dart';

class EraseStamp {
  const EraseStamp({required this.x, required this.y, required this.radius});

  final int x;
  final int y;
  final int radius;
}

class EraseStroke {
  const EraseStroke({required this.stamps, this.protectColor = true});

  final List<EraseStamp> stamps;
  final bool protectColor;
}

/// Punch [stroke] out of [mask]. When [protectColor] is on, pixels close to
/// [palette] stay. Returns how many foreground pixels were cleared.
int applyEraseStroke(
  img.Image rgb,
  img.Image mask,
  EraseStroke stroke, {
  List<RgbSwatch> palette = const [],
  double maxDeltaE = 32,
}) {
  if (stroke.stamps.isEmpty) return 0;
  final labs = [
    if (stroke.protectColor)
      for (final swatch in palette) rgbToLab(swatch.r, swatch.g, swatch.b),
  ];
  final w = mask.width;
  final h = mask.height;
  var cleared = 0;
  for (final stamp in stroke.stamps) {
    final radius = stamp.radius < 1 ? 1 : stamp.radius;
    final r2 = radius * radius;
    final x0 = (stamp.x - radius).clamp(0, w - 1);
    final y0 = (stamp.y - radius).clamp(0, h - 1);
    final x1 = (stamp.x + radius).clamp(0, w - 1);
    final y1 = (stamp.y + radius).clamp(0, h - 1);
    for (var y = y0; y <= y1; y++) {
      for (var x = x0; x <= x1; x++) {
        final dx = x - stamp.x;
        final dy = y - stamp.y;
        if (dx * dx + dy * dy > r2) continue;
        if (maskLevel(mask.getPixel(x, y)) < 24) continue;
        if (labs.isNotEmpty && x < rgb.width && y < rgb.height) {
          final p = rgb.getPixel(x, y);
          if (minDeltaE(p.r.toInt(), p.g.toInt(), p.b.toInt(), labs) <=
              maxDeltaE) {
            continue;
          }
        }
        mask.setPixelRgb(x, y, 0, 0, 0);
        cleared++;
      }
    }
  }
  return cleared;
}
