import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:wardrobe/core/vision/color_extract.dart';
import 'package:wardrobe/core/vision/color_guide.dart';
import 'package:wardrobe/core/vision/erase_brush.dart';
import 'package:wardrobe/core/vision/image_ops.dart';

class FillPatch {
  const FillPatch.box(this.box) : stamps = const [];

  const FillPatch.brush(this.stamps) : box = null;

  final PixelRect? box;
  final List<EraseStamp> stamps;

  bool contains(int x, int y) {
    final rect = box;
    if (rect != null) {
      return x >= rect.x && x < rect.right && y >= rect.y && y < rect.bottom;
    }
    for (final stamp in stamps) {
      final radius = stamp.radius < 1 ? 1 : stamp.radius;
      final dx = x - stamp.x;
      final dy = y - stamp.y;
      if (dx * dx + dy * dy <= radius * radius) return true;
    }
    return false;
  }

  PixelRect bounds(int width, int height) {
    final rect = box;
    if (rect != null) {
      return clampPixelRect(rect, width, height, minSize: 1);
    }
    if (stamps.isEmpty) {
      return const PixelRect(x: 0, y: 0, width: 1, height: 1);
    }
    var x0 = width;
    var y0 = height;
    var x1 = 0;
    var y1 = 0;
    for (final stamp in stamps) {
      final radius = stamp.radius < 1 ? 1 : stamp.radius;
      x0 = math.min(x0, stamp.x - radius);
      y0 = math.min(y0, stamp.y - radius);
      x1 = math.max(x1, stamp.x + radius);
      y1 = math.max(y1, stamp.y + radius);
    }
    return clampPixelRect(
      PixelRect(x: x0, y: y0, width: x1 - x0 + 1, height: y1 - y0 + 1),
      width,
      height,
      minSize: 1,
    );
  }
}

class FillStroke {
  const FillStroke({required this.sample, required this.paint});

  final FillPatch sample;
  final List<EraseStamp> paint;

  bool paints(int x, int y) {
    for (final stamp in paint) {
      final radius = stamp.radius < 1 ? 1 : stamp.radius;
      final dx = x - stamp.x;
      final dy = y - stamp.y;
      if (dx * dx + dy * dy <= radius * radius) return true;
    }
    return false;
  }
}

/// Clone texture from [stroke.sample] onto every pixel under [stroke.paint].
int applyFillPatch(
  img.Image rgb,
  img.Image mask,
  FillStroke stroke, {
  List<RgbSwatch> palette = const [],
}) {
  final w = math.min(rgb.width, mask.width);
  final h = math.min(rgb.height, mask.height);
  if (w <= 0 || h <= 0 || stroke.paint.isEmpty) return 0;
  final sample = stroke.sample;
  final area = sample.bounds(w, h);
  final labs = [for (final swatch in palette) rgbToLab(swatch.r, swatch.g, swatch.b)];

  var meanR = 0.0;
  var meanG = 0.0;
  var meanB = 0.0;
  var meanN = 0;
  for (var y = area.y; y < area.bottom && y < h; y++) {
    for (var x = area.x; x < area.right && x < w; x++) {
      if (!sample.contains(x, y)) continue;
      if (maskLevel(mask.getPixel(x, y)) < 128) continue;
      final p = rgb.getPixel(x, y);
      if (labs.isNotEmpty &&
          minDeltaE(p.r.toInt(), p.g.toInt(), p.b.toInt(), labs) > 32) {
        continue;
      }
      meanR += p.r.toDouble();
      meanG += p.g.toDouble();
      meanB += p.b.toDouble();
      meanN++;
    }
  }
  if (meanN == 0) {
    for (var y = area.y; y < area.bottom && y < h && meanN < 64; y++) {
      for (var x = area.x; x < area.right && x < w && meanN < 64; x++) {
        if (!sample.contains(x, y)) continue;
        final p = rgb.getPixel(x, y);
        meanR += p.r.toDouble();
        meanG += p.g.toDouble();
        meanB += p.b.toDouble();
        meanN++;
      }
    }
  }
  if (meanN > 0) {
    meanR /= meanN;
    meanG /= meanN;
    meanB /= meanN;
  }

  final toFill = List<bool>.filled(w * h, false);
  var seedCount = 0;
  var fillCx = 0;
  var fillCy = 0;
  var x0 = w;
  var y0 = h;
  var x1 = 0;
  var y1 = 0;
  for (final stamp in stroke.paint) {
    final radius = stamp.radius < 1 ? 1 : stamp.radius;
    final sx0 = (stamp.x - radius).clamp(0, w - 1);
    final sy0 = (stamp.y - radius).clamp(0, h - 1);
    final sx1 = (stamp.x + radius).clamp(0, w - 1);
    final sy1 = (stamp.y + radius).clamp(0, h - 1);
    final r2 = radius * radius;
    for (var y = sy0; y <= sy1; y++) {
      for (var x = sx0; x <= sx1; x++) {
        final dx = x - stamp.x;
        final dy = y - stamp.y;
        if (dx * dx + dy * dy > r2) continue;
        final i = y * w + x;
        if (toFill[i]) continue;
        toFill[i] = true;
        seedCount++;
        fillCx += x;
        fillCy += y;
        if (x < x0) x0 = x;
        if (y < y0) y0 = y;
        if (x + 1 > x1) x1 = x + 1;
        if (y + 1 > y1) y1 = y + 1;
      }
    }
  }
  if (seedCount == 0) return 0;

  final atlas = _TextureAtlas.build(
    rgb,
    mask,
    sample,
    area: area,
    w: w,
    h: h,
    toFill: toFill,
    labs: labs,
  );
  final shiftX = atlas == null ? 0 : atlas.cx - fillCx ~/ seedCount;
  final shiftY = atlas == null ? 0 : atlas.cy - fillCy ~/ seedCount;

  var filled = 0;
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final i = y * w + x;
      if (!toFill[i]) continue;
      late final int r;
      late final int g;
      late final int b;
      if (atlas != null) {
        final tex = atlas.at(x + shiftX, y + shiftY);
        r = tex.$1;
        g = tex.$2;
        b = tex.$3;
      } else if (meanN > 0) {
        r = meanR.round().clamp(0, 255);
        g = meanG.round().clamp(0, 255);
        b = meanB.round().clamp(0, 255);
      } else {
        continue;
      }
      rgb.setPixelRgb(x, y, r, g, b);
      mask.setPixelRgb(x, y, 255, 255, 255);
      filled++;
    }
  }
  return filled;
}

const _dx = [-1, 0, 1, -1, 1, -1, 0, 1];
const _dy = [-1, -1, -1, 0, 0, 1, 1, 1];

int _mod(int value, int modulo) {
  final n = value % modulo;
  return n < 0 ? n + modulo : n;
}

class _TextureAtlas {
  _TextureAtlas._({
    required this.ox,
    required this.oy,
    required this.tw,
    required this.th,
    required this.r,
    required this.g,
    required this.b,
    required this.cx,
    required this.cy,
  });

  final int ox;
  final int oy;
  final int tw;
  final int th;
  final List<int> r;
  final List<int> g;
  final List<int> b;
  final int cx;
  final int cy;

  static _TextureAtlas? build(
    img.Image rgb,
    img.Image mask,
    FillPatch patch, {
    required PixelRect area,
    required int w,
    required int h,
    required List<bool> toFill,
    required List<List<double>> labs,
  }) {
    final keep = <int>[];
    void collect({required bool Function(img.Pixel p) ok}) {
      if (keep.isNotEmpty) return;
      for (var y = area.y; y < area.bottom && y < h; y++) {
        for (var x = area.x; x < area.right && x < w; x++) {
          if (!patch.contains(x, y) || toFill[y * w + x]) continue;
          if (maskLevel(mask.getPixel(x, y)) < 128) continue;
          final p = rgb.getPixel(x, y);
          if (!ok(p)) continue;
          keep.add(y * w + x);
        }
      }
    }

    if (labs.isNotEmpty) {
      collect(
        ok: (p) => minDeltaE(p.r.toInt(), p.g.toInt(), p.b.toInt(), labs) <= 32,
      );
    }
    collect(ok: (_) => true);
    if (keep.isEmpty) return null;

    var x0 = w;
    var y0 = h;
    var x1 = 0;
    var y1 = 0;
    var sx = 0;
    var sy = 0;
    for (final i in keep) {
      final x = i % w;
      final y = i ~/ w;
      sx += x;
      sy += y;
      if (x < x0) x0 = x;
      if (y < y0) y0 = y;
      if (x + 1 > x1) x1 = x + 1;
      if (y + 1 > y1) y1 = y + 1;
    }
    final tw = math.max(1, x1 - x0);
    final th = math.max(1, y1 - y0);
    final r = List<int>.filled(tw * th, -1);
    final g = List<int>.filled(tw * th, 0);
    final b = List<int>.filled(tw * th, 0);
    final queue = <int>[];
    for (final i in keep) {
      final x = i % w;
      final y = i ~/ w;
      final gi = (y - y0) * tw + (x - x0);
      final p = rgb.getPixel(x, y);
      r[gi] = p.r.toInt();
      g[gi] = p.g.toInt();
      b[gi] = p.b.toInt();
      queue.add(gi);
    }
    for (var q = 0; q < queue.length; q++) {
      final gi = queue[q];
      final gx = gi % tw;
      final gy = gi ~/ tw;
      for (var k = 0; k < 8; k++) {
        final nx = gx + _dx[k];
        final ny = gy + _dy[k];
        if (nx < 0 || ny < 0 || nx >= tw || ny >= th) continue;
        final ni = ny * tw + nx;
        if (r[ni] >= 0) continue;
        r[ni] = r[gi];
        g[ni] = g[gi];
        b[ni] = b[gi];
        queue.add(ni);
      }
    }
    return _TextureAtlas._(
      ox: x0,
      oy: y0,
      tw: tw,
      th: th,
      r: r,
      g: g,
      b: b,
      cx: sx ~/ keep.length,
      cy: sy ~/ keep.length,
    );
  }

  (int, int, int) at(int x, int y) {
    final u = _mod(x - ox, tw);
    final v = _mod(y - oy, th);
    final i = v * tw + u;
    if (r[i] < 0) {
      return (r[0].clamp(0, 255), g[0], b[0]);
    }
    return (r[i], g[i], b[i]);
  }
}
