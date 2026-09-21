/// 衣架阴影挖补。当前**没有接到精修流程**，只留着方便以后加开关或更严的一版。
///
/// ## 当时做什么
/// 擦除 + 纹理填补之后，洞旁边常留下更深的衣架影子。这轮在擦除洞附近，把仍在
/// mask 里、比取样布更暗、但色相接近的像素抠掉，再由调用方用同一笔填补盖上。
///
/// 深蓝上 Lab ΔL 太紧，所以判断改成亮度（luma）+ 余弦色相。
///
/// ## 为什么摘掉
/// 深色印花、褶皱、真实阴影容易跟衣架影子一起被挖掉。精修改成点选 → 擦除 →
/// 取样/涂抹填补，不再自动第二轮。
///
/// ## 以后怎么接回去
/// 擦除前把 mask 存成 `beforeErase`，擦完存 `afterErase`。[patches] 用取样区域
/// （现在是 `FillStroke.sample`）：
///
/// ```dart
/// final punched = eraseDarkerShadows(
///   rgb,
///   mask,
///   beforeErase,
///   afterErase,
///   [for (final stroke in fills) stroke.sample],
///   palette: frozen,
/// );
/// if (punched > 0) {
///   for (final stroke in fills) {
///     applyFillPatch(rgb, mask, stroke, palette: frozen);
///   }
/// }
/// ```
///
/// [radius]：离擦除洞多远还要搜；[minDeltaY]：要比取样布暗多少；
/// [minHueCos]：色相要多接近。花纹多的衣服应把后两个调严。
library;

import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:wardrobe/core/vision/color_extract.dart';
import 'package:wardrobe/core/vision/color_guide.dart';
import 'package:wardrobe/core/vision/fill_patch.dart';
import 'package:wardrobe/core/vision/image_ops.dart';

const _dx = [-1, 0, 1, -1, 1, -1, 0, 1];
const _dy = [-1, -1, -1, 0, 0, 1, 1, 1];

/// Punch fabric that is clearly darker than the sampled cloth, near an erased
/// hole. Caller should fill those holes afterwards. See the library doc above.
int eraseDarkerShadows(
  img.Image rgb,
  img.Image mask,
  img.Image beforeErase,
  img.Image afterErase,
  List<FillPatch> patches, {
  List<RgbSwatch> palette = const [],
  int radius = 40,
  double minDeltaY = 12,
  double minHueCos = 0.9,
}) {
  if (patches.isEmpty) return 0;
  final w = math.min(rgb.width, math.min(mask.width, beforeErase.width));
  final h = math.min(rgb.height, math.min(mask.height, beforeErase.height));
  if (w <= 0 || h <= 0) return 0;
  final labs = [for (final swatch in palette) rgbToLab(swatch.r, swatch.g, swatch.b)];
  var meanY = 0.0;
  var meanR = 0.0;
  var meanG = 0.0;
  var meanBc = 0.0;
  var meanN = 0;
  for (final patch in patches) {
    final area = patch.bounds(w, h);
    for (var y = area.y; y < area.bottom && y < h; y++) {
      for (var x = area.x; x < area.right && x < w; x++) {
        if (!patch.contains(x, y)) continue;
        if (maskLevel(mask.getPixel(x, y)) < 128) continue;
        final p = rgb.getPixel(x, y);
        if (labs.isNotEmpty &&
            minDeltaE(p.r.toInt(), p.g.toInt(), p.b.toInt(), labs) > 32) {
          continue;
        }
        meanR += p.r.toDouble();
        meanG += p.g.toDouble();
        meanBc += p.b.toDouble();
        meanY += _luma(p.r.toInt(), p.g.toInt(), p.b.toInt());
        meanN++;
      }
    }
  }
  if (meanN == 0) return 0;
  meanR /= meanN;
  meanG /= meanN;
  meanBc /= meanN;
  meanY /= meanN;

  final maxDist = radius < 4 ? 4 : radius;
  const inf = 1 << 20;
  final dist = List<int>.filled(w * h, inf);
  final queue = <int>[];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (maskLevel(beforeErase.getPixel(x, y)) < 24) continue;
      if (maskLevel(afterErase.getPixel(x, y)) >= 128) continue;
      final i = y * w + x;
      dist[i] = 0;
      queue.add(i);
    }
  }
  if (queue.isEmpty) return 0;
  for (var q = 0; q < queue.length; q++) {
    final i = queue[q];
    final x = i % w;
    final y = i ~/ w;
    final nd = dist[i] + 1;
    if (nd > maxDist) continue;
    for (var k = 0; k < 8; k++) {
      final nx = x + _dx[k];
      final ny = y + _dy[k];
      if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
      final ni = ny * w + nx;
      if (dist[ni] <= nd) continue;
      dist[ni] = nd;
      queue.add(ni);
    }
  }

  bool darker(int x, int y, {required double minY}) {
    if (maskLevel(mask.getPixel(x, y)) < 128) return false;
    final p = rgb.getPixel(x, y);
    final r = p.r.toInt();
    final g = p.g.toInt();
    final b = p.b.toInt();
    final yv = _luma(r, g, b);
    if (meanY - yv < minY) return false;
    if (meanY < 1) return false;
    final k = yv / meanY;
    if (k < 0.22 || k > 0.88) return false;
    return _hueCos(r, g, b, meanR, meanG, meanBc) >= minHueCos;
  }

  final punch = List<bool>.filled(w * h, false);
  var count = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (dist[i] < 1 || dist[i] > maxDist) continue;
      if (!darker(x, y, minY: minDeltaY)) continue;
      punch[i] = true;
      count++;
    }
  }
  if (count == 0) return 0;

  final extra = <int>[];
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (!punch[i]) continue;
      for (var k = 0; k < 8; k++) {
        final nx = x + _dx[k];
        final ny = y + _dy[k];
        if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
        final ni = ny * w + nx;
        if (punch[ni]) continue;
        if (dist[ni] > maxDist) continue;
        if (!darker(nx, ny, minY: minDeltaY * 0.55)) continue;
        extra.add(ni);
      }
    }
  }
  for (final i in extra) {
    if (punch[i]) continue;
    punch[i] = true;
    count++;
  }

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      if (!punch[y * w + x]) continue;
      mask.setPixelRgb(x, y, 0, 0, 0);
    }
  }
  return count;
}

double _luma(int r, int g, int b) {
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _hueCos(int r, int g, int b, double mR, double mG, double mB) {
  final dot = r * mR + g * mG + b * mB;
  final n = math.sqrt(r * r + g * g + b * b + 1e-6);
  final m = math.sqrt(mR * mR + mG * mG + mB * mB + 1e-6);
  return dot / (n * m);
}
