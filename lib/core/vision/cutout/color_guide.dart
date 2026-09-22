import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:wardrobe/core/vision/cutout/color_extract.dart';
import 'package:wardrobe/core/vision/cutout/image_ops.dart';

/// Sample garment RGB from the first cutout, ignoring thin edges (hangers, fringes).
List<RgbSwatch> extractPalette(
  img.Image image,
  img.Image mask, {
  int maxSwatches = 5,
  double minShare = 0.05,
}) {
  final dist = _fgDistance(mask);
  var samples = _sampleForeground(image, mask, dist, minDist: 8);
  if (samples.length < 24) {
    samples = _sampleForeground(image, mask, dist, minDist: 3);
  }
  if (samples.length < 24) {
    samples = _sampleForeground(image, mask, dist, minDist: 0);
  }
  if (samples.isEmpty) return const [];

  final k = math.min(maxSwatches, samples.length);
  final centroids = <List<double>>[
    for (var i = 0; i < k; i++)
      [
        samples[i * samples.length ~/ k][0].toDouble(),
        samples[i * samples.length ~/ k][1].toDouble(),
        samples[i * samples.length ~/ k][2].toDouble(),
      ],
  ];
  final counts = List<int>.filled(k, 0);

  for (var iter = 0; iter < 8; iter++) {
    final sums = List.generate(k, (_) => [0.0, 0.0, 0.0]);
    counts.fillRange(0, k, 0);
    for (final s in samples) {
      var best = 0;
      var bestD = double.infinity;
      for (var i = 0; i < k; i++) {
        final d = _rgbDist2(s, centroids[i]);
        if (d < bestD) {
          bestD = d;
          best = i;
        }
      }
      sums[best][0] += s[0];
      sums[best][1] += s[1];
      sums[best][2] += s[2];
      counts[best]++;
    }
    for (var i = 0; i < k; i++) {
      if (counts[i] == 0) continue;
      centroids[i][0] = sums[i][0] / counts[i];
      centroids[i][1] = sums[i][1] / counts[i];
      centroids[i][2] = sums[i][2] / counts[i];
    }
  }

  final ranked = [
    for (var i = 0; i < k; i++)
      if (counts[i] > 0) (i: i, n: counts[i]),
  ]..sort((a, b) => b.n.compareTo(a.n));

  final total = samples.length;
  final kept = <RgbSwatch>[
    for (final item in ranked)
      if (item.n / total >= minShare)
        RgbSwatch(
          centroids[item.i][0].round().clamp(0, 255),
          centroids[item.i][1].round().clamp(0, 255),
          centroids[item.i][2].round().clamp(0, 255),
        ),
  ];
  if (kept.isEmpty && ranked.isNotEmpty) {
    final i = ranked.first.i;
    kept.add(
      RgbSwatch(
        centroids[i][0].round().clamp(0, 255),
        centroids[i][1].round().clamp(0, 255),
        centroids[i][2].round().clamp(0, 255),
      ),
    );
  }
  return kept;
}

/// Punch out pixels that do not look like the garment; fill holes that do.
void guideMaskWithPalette(
  img.Image rgb,
  img.Image mask,
  List<RgbSwatch> palette, {
  double keepMaxDeltaE = 32,
}) {
  classifyMaskRegion(
    rgb,
    mask,
    PixelRect(x: 0, y: 0, width: rgb.width, height: rgb.height),
    palette,
    maxDeltaE: keepMaxDeltaE,
  );
}

void classifyMaskRegion(
  img.Image rgb,
  img.Image mask,
  PixelRect region,
  List<RgbSwatch> palette, {
  double maxDeltaE = 32,
}) {
  if (palette.isEmpty) {
    eraseMaskRegion(mask, region);
    return;
  }
  final labs = [for (final s in palette) rgbToLab(s.r, s.g, s.b)];
  final box = clampPixelRect(region, rgb.width, rgb.height, minSize: 1);
  final w = math.min(rgb.width, mask.width);
  final h = math.min(rgb.height, mask.height);
  final x1 = math.min(box.right, w);
  final y1 = math.min(box.bottom, h);
  for (var y = box.y; y < y1; y++) {
    for (var x = box.x; x < x1; x++) {
      final p = rgb.getPixel(x, y);
      final d = minDeltaE(p.r.toInt(), p.g.toInt(), p.b.toInt(), labs);
      if (d <= maxDeltaE) {
        mask.setPixelRgb(x, y, 255, 255, 255);
      } else {
        mask.setPixelRgb(x, y, 0, 0, 0);
      }
    }
  }
}

void eraseMaskRegion(img.Image mask, PixelRect region) {
  final box = clampPixelRect(region, mask.width, mask.height, minSize: 1);
  for (var y = box.y; y < box.bottom && y < mask.height; y++) {
    for (var x = box.x; x < box.right && x < mask.width; x++) {
      mask.setPixelRgb(x, y, 0, 0, 0);
    }
  }
}

/// Close small gaps in [region], fill tiny enclosed holes, and paint hanger pixels with nearby garment color.
img.Image fillRefineGaps(
  img.Image rgb,
  img.Image mask,
  PixelRect region,
  List<RgbSwatch> palette, {
  int radius = 14,
  int maxHoleArea = 5000,
}) {
  closeMaskRegion(mask, region, radius);
  fillEnclosedHoles(mask, region, maxHoleArea);
  final out = img.Image.from(rgb);
  inpaintUnmatched(out, mask, region, palette);
  return out;
}

void closeMaskRegion(img.Image mask, PixelRect region, int radius) {
  if (radius <= 0) return;
  final box = clampPixelRect(region, mask.width, mask.height, minSize: 1);
  final w = mask.width;
  final h = mask.height;
  final src = List<int>.filled(w * h, 0);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      src[y * w + x] = maskLevel(mask.getPixel(x, y));
    }
  }
  final dilated = List<int>.from(src);
  _boxMax(src, dilated, w, h, box, radius);
  final closed = List<int>.from(dilated);
  _boxMin(dilated, closed, w, h, box, radius);
  for (var y = box.y; y < box.bottom && y < h; y++) {
    for (var x = box.x; x < box.right && x < w; x++) {
      final g = closed[y * w + x].clamp(0, 255);
      mask.setPixelRgb(x, y, g, g, g);
    }
  }
}

void fillEnclosedHoles(img.Image mask, PixelRect region, int maxArea) {
  final box = clampPixelRect(region, mask.width, mask.height, minSize: 1);
  final w = mask.width;
  final h = mask.height;
  final x1 = math.min(box.right, w);
  final y1 = math.min(box.bottom, h);
  final seen = List<bool>.filled(w * h, false);
  bool isBg(int x, int y) => maskLevel(mask.getPixel(x, y)) < 128;

  void flood(int sx, int sy, {required bool fill}) {
    if (sx < box.x || sy < box.y || sx >= x1 || sy >= y1) return;
    if (seen[sy * w + sx] || !isBg(sx, sy)) return;
    final stack = <int>[sx, sy];
    seen[sy * w + sx] = true;
    while (stack.isNotEmpty) {
      final y = stack.removeLast();
      final x = stack.removeLast();
      if (fill) mask.setPixelRgb(x, y, 255, 255, 255);
      const n = [-1, 0, 1, 0, 0, -1, 0, 1];
      for (var i = 0; i < 8; i += 2) {
        final nx = x + n[i];
        final ny = y + n[i + 1];
        if (nx < box.x || ny < box.y || nx >= x1 || ny >= y1) continue;
        final idx = ny * w + nx;
        if (seen[idx] || !isBg(nx, ny)) continue;
        seen[idx] = true;
        stack
          ..add(nx)
          ..add(ny);
      }
    }
  }

  for (var x = box.x; x < x1; x++) {
    flood(x, box.y, fill: false);
    flood(x, y1 - 1, fill: false);
  }
  for (var y = box.y; y < y1; y++) {
    flood(box.x, y, fill: false);
    flood(x1 - 1, y, fill: false);
  }

  for (var y = box.y; y < y1; y++) {
    for (var x = box.x; x < x1; x++) {
      final idx = y * w + x;
      if (seen[idx] || !isBg(x, y)) continue;
      final blob = <int>[];
      final stack = <int>[x, y];
      seen[idx] = true;
      while (stack.isNotEmpty) {
        final cy = stack.removeLast();
        final cx = stack.removeLast();
        blob.add(cy * w + cx);
        const n = [-1, 0, 1, 0, 0, -1, 0, 1];
        for (var i = 0; i < 8; i += 2) {
          final nx = cx + n[i];
          final ny = cy + n[i + 1];
          if (nx < box.x || ny < box.y || nx >= x1 || ny >= y1) continue;
          final nidx = ny * w + nx;
          if (seen[nidx] || !isBg(nx, ny)) continue;
          seen[nidx] = true;
          stack
            ..add(nx)
            ..add(ny);
        }
      }
      if (blob.length > maxArea) continue;
      for (final i in blob) {
        final px = i % w;
        final py = i ~/ w;
        mask.setPixelRgb(px, py, 255, 255, 255);
      }
    }
  }
}

void inpaintUnmatched(
  img.Image rgb,
  img.Image mask,
  PixelRect region,
  List<RgbSwatch> palette, {
  double maxDeltaE = 32,
}) {
  if (palette.isEmpty) return;
  final labs = [for (final s in palette) rgbToLab(s.r, s.g, s.b)];
  final box = clampPixelRect(region, rgb.width, rgb.height, minSize: 1);
  final w = math.min(rgb.width, mask.width);
  final h = math.min(rgb.height, mask.height);
  final x1 = math.min(box.right, w);
  final y1 = math.min(box.bottom, h);
  bool trusted(int x, int y) {
    if (maskLevel(mask.getPixel(x, y)) < 128) return false;
    final p = rgb.getPixel(x, y);
    return minDeltaE(p.r.toInt(), p.g.toInt(), p.b.toInt(), labs) <= maxDeltaE;
  }

  final fallback = palette.first;
  for (var y = box.y; y < y1; y++) {
    for (var x = box.x; x < x1; x++) {
      if (maskLevel(mask.getPixel(x, y)) < 128) continue;
      if (trusted(x, y)) continue;
      var found = false;
      for (var r = 1; r <= 48 && !found; r++) {
        for (var ny = y - r; ny <= y + r && !found; ny++) {
          for (var nx = x - r; nx <= x + r; nx++) {
            if ((ny != y - r && ny != y + r) && (nx != x - r && nx != x + r)) {
              continue;
            }
            if (nx < 0 || ny < 0 || nx >= w || ny >= h) continue;
            if (!trusted(nx, ny)) continue;
            final p = rgb.getPixel(nx, ny);
            rgb.setPixelRgb(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt());
            found = true;
            break;
          }
        }
      }
      if (!found) {
        rgb.setPixelRgb(x, y, fallback.r, fallback.g, fallback.b);
      }
    }
  }
}

void _boxMax(
  List<int> src,
  List<int> dst,
  int w,
  int h,
  PixelRect box,
  int radius,
) {
  final tmp = List<int>.from(src);
  final x0 = box.x;
  final y0 = box.y;
  final x1 = math.min(box.right, w);
  final y1 = math.min(box.bottom, h);
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      var m = 0;
      for (var k = x - radius; k <= x + radius; k++) {
        if (k < 0 || k >= w) continue;
        final v = src[y * w + k];
        if (v > m) m = v;
      }
      tmp[y * w + x] = m;
    }
  }
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      var m = 0;
      for (var k = y - radius; k <= y + radius; k++) {
        if (k < 0 || k >= h) continue;
        final v = tmp[k * w + x];
        if (v > m) m = v;
      }
      dst[y * w + x] = m;
    }
  }
}

void _boxMin(
  List<int> src,
  List<int> dst,
  int w,
  int h,
  PixelRect box,
  int radius,
) {
  final tmp = List<int>.from(src);
  final x0 = box.x;
  final y0 = box.y;
  final x1 = math.min(box.right, w);
  final y1 = math.min(box.bottom, h);
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      var m = 255;
      for (var k = x - radius; k <= x + radius; k++) {
        if (k < 0 || k >= w) continue;
        final v = src[y * w + k];
        if (v < m) m = v;
      }
      tmp[y * w + x] = m;
    }
  }
  for (var y = y0; y < y1; y++) {
    for (var x = x0; x < x1; x++) {
      var m = 255;
      for (var k = y - radius; k <= y + radius; k++) {
        if (k < 0 || k >= h) continue;
        final v = tmp[k * w + x];
        if (v < m) m = v;
      }
      dst[y * w + x] = m;
    }
  }
}

double minDeltaE(int r, int g, int b, List<List<double>> paletteLab) {
  final lab = rgbToLab(r, g, b);
  var best = double.infinity;
  for (final other in paletteLab) {
    final d = deltaE(lab, other);
    if (d < best) best = d;
  }
  return best;
}

List<double> rgbToLab(int r, int g, int b) {
  double lin(int c) {
    final n = c / 255.0;
    return n > 0.04045 ? math.pow((n + 0.055) / 1.055, 2.4).toDouble() : n / 12.92;
  }

  final rl = lin(r);
  final gl = lin(g);
  final bl = lin(b);
  final x = (rl * 0.4124564 + gl * 0.3575761 + bl * 0.1804375) / 0.95047;
  final y = (rl * 0.2126729 + gl * 0.7151522 + bl * 0.0721750);
  final z = (rl * 0.0193339 + gl * 0.1191920 + bl * 0.9503041) / 1.08883;

  double f(double t) =>
      t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : (7.787 * t) + 16 / 116;

  final fx = f(x);
  final fy = f(y);
  final fz = f(z);
  return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)];
}

List<int> labToRgb(List<double> lab) {
  final fy = (lab[0] + 16) / 116;
  final fx = lab[1] / 500 + fy;
  final fz = fy - lab[2] / 200;
  double inv(double t) {
    final t3 = t * t * t;
    return t3 > 0.008856 ? t3 : (t - 16 / 116) / 7.787;
  }

  final x = inv(fx) * 0.95047;
  final y = inv(fy);
  final z = inv(fz) * 1.08883;
  double comp(double v) {
    final n = v <= 0.0031308 ? 12.92 * v : 1.055 * math.pow(v.clamp(0.0, 1.0), 1 / 2.4) - 0.055;
    return (n * 255).clamp(0, 255);
  }

  return [
    comp(3.2404542 * x - 1.5371385 * y - 0.4985314 * z).round(),
    comp(-0.9692660 * x + 1.8760108 * y + 0.0415560 * z).round(),
    comp(0.0556434 * x - 0.2040259 * y + 1.0572252 * z).round(),
  ];
}

double deltaE(List<double> a, List<double> b) {
  final dl = a[0] - b[0];
  final da = a[1] - b[1];
  final db = a[2] - b[2];
  return math.sqrt(dl * dl + da * da + db * db);
}

List<List<int>> _sampleForeground(
  img.Image image,
  img.Image mask,
  List<int> dist, {
  required int minDist,
}) {
  final samples = <List<int>>[];
  final w = math.min(image.width, mask.width);
  final h = math.min(image.height, mask.height);
  final pixels = w * h;
  final stride = math.max(1, pixels ~/ 14000);
  var i = 0;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      i++;
      if (i % stride != 0) continue;
      if (maskLevel(mask.getPixel(x, y)) < 128) continue;
      if (dist[y * w + x] < minDist) continue;
      final p = image.getPixel(x, y);
      samples.add([p.r.toInt(), p.g.toInt(), p.b.toInt()]);
    }
  }
  return samples;
}

List<int> _fgDistance(img.Image mask) {
  final w = mask.width;
  final h = mask.height;
  const inf = 1 << 20;
  final dist = List<int>.filled(w * h, 0);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      dist[y * w + x] = maskLevel(mask.getPixel(x, y)) < 128 ? 0 : inf;
    }
  }
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * w + x;
      if (dist[i] == 0) continue;
      if (x > 0) dist[i] = math.min(dist[i], dist[i - 1] + 1);
      if (y > 0) dist[i] = math.min(dist[i], dist[i - w] + 1);
      if (x > 0 && y > 0) dist[i] = math.min(dist[i], dist[i - w - 1] + 1);
      if (x + 1 < w && y > 0) dist[i] = math.min(dist[i], dist[i - w + 1] + 1);
    }
  }
  for (var y = h - 1; y >= 0; y--) {
    for (var x = w - 1; x >= 0; x--) {
      final i = y * w + x;
      if (dist[i] == 0) continue;
      if (x + 1 < w) dist[i] = math.min(dist[i], dist[i + 1] + 1);
      if (y + 1 < h) dist[i] = math.min(dist[i], dist[i + w] + 1);
      if (x + 1 < w && y + 1 < h) dist[i] = math.min(dist[i], dist[i + w + 1] + 1);
      if (x > 0 && y + 1 < h) dist[i] = math.min(dist[i], dist[i + w - 1] + 1);
    }
  }
  return dist;
}

double _rgbDist2(List<int> sample, List<double> centroid) {
  final dr = sample[0] - centroid[0];
  final dg = sample[1] - centroid[1];
  final db = sample[2] - centroid[2];
  return dr * dr + dg * dg + db * db;
}
