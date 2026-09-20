import 'dart:math' as math;
import 'dart:ui' show Rect;

import 'package:wardrobe/core/vision/image_ops.dart';

/// How a `BoxFit.contain` image is laid out inside a widget box.
class ContainLayout {
  const ContainLayout({
    required this.offsetX,
    required this.offsetY,
    required this.drawWidth,
    required this.drawHeight,
  });

  final double offsetX;
  final double offsetY;
  final double drawWidth;
  final double drawHeight;

  static ContainLayout of({
    required double boxWidth,
    required double boxHeight,
    required int imageWidth,
    required int imageHeight,
  }) {
    if (boxWidth <= 0 || boxHeight <= 0 || imageWidth <= 0 || imageHeight <= 0) {
      return const ContainLayout(
        offsetX: 0,
        offsetY: 0,
        drawWidth: 0,
        drawHeight: 0,
      );
    }
    final scale = math.min(boxWidth / imageWidth, boxHeight / imageHeight);
    final drawWidth = imageWidth * scale;
    final drawHeight = imageHeight * scale;
    return ContainLayout(
      offsetX: (boxWidth - drawWidth) / 2,
      offsetY: (boxHeight - drawHeight) / 2,
      drawWidth: drawWidth,
      drawHeight: drawHeight,
    );
  }

  bool contains(double x, double y) {
    return x >= offsetX &&
        x <= offsetX + drawWidth &&
        y >= offsetY &&
        y <= offsetY + drawHeight;
  }

  PixelRect? boxToPixelRect({
    required double x0,
    required double y0,
    required double x1,
    required double y1,
    required int imageWidth,
    required int imageHeight,
  }) {
    if (drawWidth <= 0 || drawHeight <= 0) return null;
    final left = math.min(x0, x1);
    final top = math.min(y0, y1);
    final right = math.max(x0, x1);
    final bottom = math.max(y0, y1);
    int toX(double x) {
      final n = ((x - offsetX) / drawWidth * imageWidth).round();
      return n.clamp(0, imageWidth);
    }

    int toY(double y) {
      final n = ((y - offsetY) / drawHeight * imageHeight).round();
      return n.clamp(0, imageHeight);
    }

    final px = toX(left);
    final py = toY(top);
    final qx = toX(right);
    final qy = toY(bottom);
    if (qx <= px || qy <= py) return null;
    return PixelRect(x: px, y: py, width: qx - px, height: qy - py);
  }

  ({int x, int y})? localToPixel(
    double x,
    double y, {
    required int imageWidth,
    required int imageHeight,
  }) {
    if (drawWidth <= 0 || drawHeight <= 0) return null;
    final px = ((x - offsetX) / drawWidth * imageWidth).round().clamp(0, imageWidth);
    final py = ((y - offsetY) / drawHeight * imageHeight).round().clamp(0, imageHeight);
    return (x: px, y: py);
  }

  Rect pixelRectToLocal(
    PixelRect rect, {
    required int imageWidth,
    required int imageHeight,
  }) {
    if (drawWidth <= 0 || drawHeight <= 0 || imageWidth <= 0 || imageHeight <= 0) {
      return Rect.zero;
    }
    final left = offsetX + rect.x / imageWidth * drawWidth;
    final top = offsetY + rect.y / imageHeight * drawHeight;
    final width = rect.width / imageWidth * drawWidth;
    final height = rect.height / imageHeight * drawHeight;
    return Rect.fromLTWH(left, top, width, height);
  }
}
