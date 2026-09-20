import 'dart:math' as math;

import 'package:image/image.dart' as img;

const maxSourceEdge = 1600;
const u2netInputSize = 320;

int maskLevel(img.Pixel pixel) {
  return math.max(pixel.r.toInt(), math.max(pixel.g.toInt(), pixel.b.toInt()));
}

img.Image bakeAndScale(img.Image source, {int maxEdge = maxSourceEdge}) {
  var image = img.bakeOrientation(source);
  if (image.numChannels != 3) {
    image = image.convert(numChannels: 3, alpha: 255);
  }
  final longest = math.max(image.width, image.height);
  if (longest <= maxEdge) return image;
  final scale = maxEdge / longest;
  return img.copyResize(
    image,
    width: math.max(1, (image.width * scale).round()),
    height: math.max(1, (image.height * scale).round()),
    interpolation: img.Interpolation.linear,
  );
}

img.Image resizeExact(img.Image source, int size) {
  return img.copyResize(
    source,
    width: size,
    height: size,
    interpolation: img.Interpolation.linear,
  );
}

img.Image resizeMask(img.Image mask, int width, int height) {
  return img.copyResize(
    mask,
    width: width,
    height: height,
    interpolation: img.Interpolation.linear,
  );
}

class PixelRect {
  const PixelRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  int get right => x + width;
  int get bottom => y + height;

  static PixelRect fromCorners(int x0, int y0, int x1, int y1) {
    final left = math.min(x0, x1);
    final top = math.min(y0, y1);
    final right = math.max(x0, x1);
    final bottom = math.max(y0, y1);
    return PixelRect(
      x: left,
      y: top,
      width: math.max(1, right - left),
      height: math.max(1, bottom - top),
    );
  }
}

PixelRect clampPixelRect(
  PixelRect rect,
  int imageWidth,
  int imageHeight, {
  int minSize = 16,
}) {
  var x = rect.x.clamp(0, math.max(0, imageWidth - 1)).toInt();
  var y = rect.y.clamp(0, math.max(0, imageHeight - 1)).toInt();
  var w = rect.width;
  var h = rect.height;
  if (x + w > imageWidth) w = imageWidth - x;
  if (y + h > imageHeight) h = imageHeight - y;
  w = math.max(1, w);
  h = math.max(1, h);
  if (w < minSize && imageWidth >= minSize) {
    w = math.min(minSize, imageWidth);
    if (x + w > imageWidth) x = imageWidth - w;
  }
  if (h < minSize && imageHeight >= minSize) {
    h = math.min(minSize, imageHeight);
    if (y + h > imageHeight) y = imageHeight - h;
  }
  return PixelRect(x: x, y: y, width: w, height: h);
}

img.Image cropRect(img.Image image, PixelRect rect) {
  final r = clampPixelRect(rect, image.width, image.height);
  return img.copyCrop(image, x: r.x, y: r.y, width: r.width, height: r.height);
}

img.Image emptyMask(int width, int height) {
  final mask = img.Image(width: width, height: height, numChannels: 3);
  img.fill(mask, color: img.ColorRgb8(0, 0, 0));
  return mask;
}

img.Image maskMatchingOriginal(img.Image original, img.Image? mask) {
  if (mask != null && mask.width == original.width && mask.height == original.height) {
    if (mask.numChannels == 3) return img.Image.from(mask);
    return mask.convert(numChannels: 3, alpha: 255);
  }
  return emptyMask(original.width, original.height);
}

void pasteMask(img.Image dest, img.Image src, PixelRect at) {
  final r = clampPixelRect(at, dest.width, dest.height, minSize: 1);
  for (var y = 0; y < src.height && y < r.height; y++) {
    for (var x = 0; x < src.width && x < r.width; x++) {
      final dx = r.x + x;
      final dy = r.y + y;
      if (dx >= dest.width || dy >= dest.height) continue;
      final g = maskLevel(src.getPixel(x, y)).clamp(0, 255);
      dest.setPixelRgb(dx, dy, g, g, g);
    }
  }
}

class CroppedPair {
  const CroppedPair(this.image, this.mask);

  final img.Image image;
  final img.Image mask;
}

CroppedPair cropToMask(img.Image image, img.Image mask, {double padding = 0.06}) {
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;
  for (var y = 0; y < mask.height; y++) {
    for (var x = 0; x < mask.width; x++) {
      final p = mask.getPixel(x, y);
      if (maskLevel(p) < 24) continue;
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
    }
  }
  if (maxX < minX || maxY < minY) {
    return CroppedPair(image, mask);
  }
  final padX = math.max(4, (image.width * padding).round());
  final padY = math.max(4, (image.height * padding).round());
  minX = math.max(0, minX - padX);
  minY = math.max(0, minY - padY);
  maxX = math.min(image.width - 1, maxX + padX);
  maxY = math.min(image.height - 1, maxY + padY);
  final w = maxX - minX + 1;
  final h = maxY - minY + 1;
  return CroppedPair(
    img.copyCrop(image, x: minX, y: minY, width: w, height: h),
    img.copyCrop(mask, x: minX, y: minY, width: w, height: h),
  );
}

img.Image applyAlpha(img.Image rgb, img.Image mask) {
  final out = img.Image(width: rgb.width, height: rgb.height, numChannels: 4);
  for (var y = 0; y < rgb.height; y++) {
    for (var x = 0; x < rgb.width; x++) {
      final p = rgb.getPixel(x, y);
      final a = x < mask.width && y < mask.height
          ? maskLevel(mask.getPixel(x, y)).clamp(0, 255)
          : 0;
      out.setPixelRgba(
        x,
        y,
        p.r.toInt(),
        p.g.toInt(),
        p.b.toInt(),
        a.toInt(),
      );
    }
  }
  return out;
}

img.Image maskFromValues(List<double> values, int width, int height) {
  var min = double.infinity;
  var max = -double.infinity;
  for (final v in values) {
    if (v < min) min = v;
    if (v > max) max = v;
  }
  final span = (max - min).abs() < 1e-6 ? 1.0 : max - min;
  final mask = img.Image(width: width, height: height, numChannels: 3);
  for (var i = 0; i < values.length && i < width * height; i++) {
    final n = ((values[i] - min) / span).clamp(0.0, 1.0);
    final y = i ~/ width;
    final x = i % width;
    final g = (n * 255).round();
    mask.setPixelRgb(x, y, g, g, g);
  }
  return mask;
}
