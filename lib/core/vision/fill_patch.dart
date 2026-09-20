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

/// Clone texture from [patch] into holes and leftover junk.
///
/// The box or brush is a fabric sample: its knit/print is stamped onto
/// targets, with a short blend only at the seam.
int applyFillPatch(
  img.Image rgb,
  img.Image mask,
  FillPatch patch, {
  img.Image? beforeErase,
  List<RgbSwatch> palette = const [],
  int maxDist = 96,
  int rim = 2,
  double replaceDeltaE = 28,
}) {
  final w = math.min(rgb.width, mask.width);
  final h = math.min(rgb.height, mask.height);
  if (w <= 0 || h <= 0) return 0;
  final area = patch.bounds(w, h);
  final labs = [for (final swatch in palette) rgbToLab(swatch.r, swatch.g, swatch.b)];

  var meanR = 0.0;
  var meanG = 0.0;
  var meanB = 0.0;
  var meanN = 0;
  void sampleMean({required bool Function(int x, int y, img.Pixel p) keep}) {
    if (meanN > 0) return;
    for (var y = area.y; y < area.bottom && y < h; y++) {
      for (var x = area.x; x < area.right && x < w; x++) {
        if (!patch.contains(x, y)) continue;
        if (maskLevel(mask.getPixel(x, y)) < 128) continue;
        final p = rgb.getPixel(x, y);
        if (!keep(x, y, p)) continue;
        meanR += p.r.toDouble();
        meanG += p.g.toDouble();
        meanB += p.b.toDouble();
        meanN++;
      }
    }
  }

  if (labs.isNotEmpty) {
    sampleMean(
      keep: (_, _, p) =>
          minDeltaE(p.r.toInt(), p.g.toInt(), p.b.toInt(), labs) <= 32,
    );
  }
  sampleMean(keep: (_, _, _) => true);
  if (meanN == 0) {
    final pad = maxDist < 1 ? 1 : maxDist;
    final sx0 = math.max(0, area.x - pad);
    final sy0 = math.max(0, area.y - pad);
    final sx1 = math.min(w, area.right + pad);
    final sy1 = math.min(h, area.bottom + pad);
    for (var y = sy0; y < sy1 && meanN < 64; y++) {
      for (var x = sx0; x < sx1 && meanN < 64; x++) {
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
  }
  if (meanN > 0) {
    meanR /= meanN;
    meanG /= meanN;
    meanB /= meanN;
  }
  final meanLab = meanN > 0
      ? rgbToLab(meanR.round().clamp(0, 255), meanG.round().clamp(0, 255), meanB.round().clamp(0, 255))
      : null;

  final toFill = List<bool>.filled(w * h, false);
  var seedCount = 0;
  void mark(int x, int y) {
    final i = y * w + x;
    if (toFill[i]) return;
    toFill[i] = true;
    seedCount++;
  }

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final inside = patch.contains(x, y);
      final off = maskLevel(mask.getPixel(x, y)) < 128;
      if (off) {
        if (inside) mark(x, y);
        continue;
      }
      if (!inside || meanLab == null) continue;
      final p = rgb.getPixel(x, y);
      final d = deltaE(rgbToLab(p.r.toInt(), p.g.toInt(), p.b.toInt()), meanLab);
      if (d > replaceDeltaE) mark(x, y);
    }
  }
  if (beforeErase != null) {
    _markErasedHoles(mask, beforeErase, w, h, mark);
  }
  if (seedCount == 0) return 0;

  final atlas = _TextureAtlas.build(
    rgb,
    mask,
    patch,
    area: area,
    w: w,
    h: h,
    toFill: toFill,
    labs: labs,
  );
  var fillCx = 0;
  var fillCy = 0;
  var fillN = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!toFill[y * w + x]) continue;
      fillCx += x;
      fillCy += y;
      fillN++;
    }
  }
  final shiftX = atlas == null || fillN == 0 ? 0 : atlas.cx - fillCx ~/ fillN;
  final shiftY = atlas == null || fillN == 0 ? 0 : atlas.cy - fillCy ~/ fillN;

  var x0 = w;
  var y0 = h;
  var x1 = 0;
  var y1 = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!toFill[y * w + x]) continue;
      if (x < x0) x0 = x;
      if (y < y0) y0 = y;
      if (x + 1 > x1) x1 = x + 1;
      if (y + 1 > y1) y1 = y + 1;
    }
  }
  const workPad = 8;
  x0 = math.max(0, x0 - workPad);
  y0 = math.max(0, y0 - workPad);
  x1 = math.min(w, x1 + workPad);
  y1 = math.min(h, y1 + workPad);

  final grow = rim < 0 ? 0 : rim;
  for (var pass = 0; pass < grow; pass++) {
    final extra = <int>[];
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        final i = y * w + x;
        if (toFill[i] || maskLevel(mask.getPixel(x, y)) < 128) continue;
        if (_touchesFill(toFill, w, h, x, y)) extra.add(i);
      }
    }
    for (final i in extra) {
      toFill[i] = true;
    }
  }

  final dist = List<int>.filled(w * h, 1 << 20);
  final queue = <int>[];
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final i = y * w + x;
      if (toFill[i]) continue;
      if (maskLevel(mask.getPixel(x, y)) < 128) continue;
      dist[i] = 0;
      queue.add(i);
    }
  }
  for (var q = 0; q < queue.length; q++) {
    final i = queue[q];
    final x = i % w;
    final y = i ~/ w;
    final nd = dist[i] + 1;
    for (var k = 0; k < 8; k++) {
      final nx = x + _dx[k];
      final ny = y + _dy[k];
      if (nx < x0 || ny < y0 || nx >= x1 || ny >= y1) continue;
      final ni = ny * w + nx;
      if (!toFill[ni] || dist[ni] <= nd) continue;
      dist[ni] = nd;
      queue.add(ni);
    }
  }

  final order = <int>[];
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final i = y * w + x;
      if (toFill[i]) order.add(i);
    }
  }
  order.sort((a, b) => dist[a].compareTo(dist[b]));

  final done = List<bool>.filled(w * h, false);
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      final i = y * w + x;
      done[i] = !toFill[i] && maskLevel(mask.getPixel(x, y)) >= 128;
    }
  }

  var filled = 0;
  for (final i in order) {
    final x = i % w;
    final y = i ~/ w;
    var sumR = 0.0;
    var sumG = 0.0;
    var sumB = 0.0;
    var sumW = 0.0;
    for (var r = 1; r <= 6 && sumW == 0; r++) {
      for (var ny = y - r; ny <= y + r; ny++) {
        for (var nx = x - r; nx <= x + r; nx++) {
          if ((ny != y - r && ny != y + r) && (nx != x - r && nx != x + r)) {
            continue;
          }
          if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
          final ni = ny * w + nx;
          if (!done[ni]) continue;
          final d2 = (nx - x) * (nx - x) + (ny - y) * (ny - y);
          final weight = 1.0 / (d2 + 0.5);
          final p = rgb.getPixel(nx, ny);
          sumR += p.r.toDouble() * weight;
          sumG += p.g.toDouble() * weight;
          sumB += p.b.toDouble() * weight;
          sumW += weight;
        }
      }
    }
    var r = meanR;
    var g = meanG;
    var b = meanB;
    if (atlas != null) {
      final tex = atlas.at(x + shiftX, y + shiftY);
      r = tex.$1.toDouble();
      g = tex.$2.toDouble();
      b = tex.$3.toDouble();
      if (sumW > 0 && dist[i] <= 2) {
        final t = dist[i] <= 1 ? 0.4 : 0.18;
        r = r * (1 - t) + sumR / sumW * t;
        g = g * (1 - t) + sumG / sumW * t;
        b = b * (1 - t) + sumB / sumW * t;
      }
    } else if (sumW > 0 && meanN > 0) {
      r = sumR / sumW * 0.82 + meanR * 0.18;
      g = sumG / sumW * 0.82 + meanG * 0.18;
      b = sumB / sumW * 0.82 + meanB * 0.18;
    } else if (sumW > 0) {
      r = sumR / sumW;
      g = sumG / sumW;
      b = sumB / sumW;
    } else if (meanN == 0) {
      continue;
    }
    rgb.setPixelRgb(
      x,
      y,
      r.round().clamp(0, 255),
      g.round().clamp(0, 255),
      b.round().clamp(0, 255),
    );
    mask.setPixelRgb(x, y, 255, 255, 255);
    done[i] = true;
    filled++;
  }
  if (filled == 0) return 0;
  return filled;
}

const _dx = [-1, 0, 1, -1, 1, -1, 0, 1];
const _dy = [-1, -1, -1, 0, 0, 1, 1, 1];

bool _touchesKeep(img.Image mask, int w, int h, int x, int y) {
  for (var k = 0; k < 8; k++) {
    final nx = x + _dx[k];
    final ny = y + _dy[k];
    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
    if (maskLevel(mask.getPixel(nx, ny)) >= 128) return true;
  }
  return false;
}

void _markErasedHoles(
  img.Image mask,
  img.Image beforeErase,
  int w,
  int h,
  void Function(int x, int y) mark,
) {
  final erased = List<bool>.filled(w * h, false);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (maskLevel(mask.getPixel(x, y)) >= 128) continue;
      if (maskLevel(beforeErase.getPixel(x, y)) < 24) continue;
      erased[y * w + x] = true;
    }
  }
  final queue = <int>[];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (!erased[i] || !_touchesKeep(mask, w, h, x, y)) continue;
      erased[i] = false;
      queue.add(i);
      mark(x, y);
    }
  }
  for (var q = 0; q < queue.length; q++) {
    final i = queue[q];
    final x = i % w;
    final y = i ~/ w;
    for (var k = 0; k < 8; k++) {
      final nx = x + _dx[k];
      final ny = y + _dy[k];
      if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
      final ni = ny * w + nx;
      if (!erased[ni]) continue;
      erased[ni] = false;
      queue.add(ni);
      mark(nx, ny);
    }
  }
}

bool _touchesFill(List<bool> toFill, int w, int h, int x, int y) {
  for (var k = 0; k < 8; k++) {
    final nx = x + _dx[k];
    final ny = y + _dy[k];
    if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
    if (toFill[ny * w + nx]) return true;
  }
  return false;
}

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
