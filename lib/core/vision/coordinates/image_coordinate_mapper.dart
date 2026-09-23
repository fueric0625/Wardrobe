import 'dart:ui' show Offset, Rect;

import 'package:wardrobe/core/vision/cutout/contain_map.dart';
import 'package:wardrobe/core/vision/cutout/image_ops.dart';

/// A point in processed-image pixels.
class ImagePixelPoint {
  const ImagePixelPoint(this.x, this.y);

  final double x;
  final double y;
}

/// A point in the widget that displays the image.
class ViewportPoint {
  const ViewportPoint(this.x, this.y);

  factory ViewportPoint.fromOffset(Offset offset) =>
      ViewportPoint(offset.dx, offset.dy);

  final double x;
  final double y;

  Offset toOffset() => Offset(x, y);
}

class ImagePixelRect {
  const ImagePixelRect({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  PixelRect toPixelRect() =>
      PixelRect(x: x, y: y, width: width, height: height);
}

class ViewportRect {
  const ViewportRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;

  Rect toRect() => Rect.fromLTWH(left, top, width, height);
}

/// Maps between a `BoxFit.contain` viewport and image pixels.
class ImageCoordinateMapper {
  ImageCoordinateMapper({
    required int imageWidth,
    required int imageHeight,
    required double viewportWidth,
    required double viewportHeight,
  }) : imageWidth = imageWidth,
       imageHeight = imageHeight,
       layout = ContainLayout.of(
         boxWidth: viewportWidth,
         boxHeight: viewportHeight,
         imageWidth: imageWidth,
         imageHeight: imageHeight,
       );

  ImageCoordinateMapper.fromLayout({
    required this.imageWidth,
    required this.imageHeight,
    required this.layout,
  });

  final int imageWidth;
  final int imageHeight;
  final ContainLayout layout;

  bool contains(ViewportPoint point) => layout.contains(point.x, point.y);

  /// Rounded image pixel. Null when the point is in the letterbox.
  ImagePixelPoint? toImage(ViewportPoint point) {
    if (!contains(point)) return null;
    final pixel = layout.localToPixel(
      point.x,
      point.y,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    if (pixel == null) return null;
    return ImagePixelPoint(pixel.x.toDouble(), pixel.y.toDouble());
  }

  /// Floored image pixel, matching collage hit tests.
  ImagePixelPoint? toImageFloored(ViewportPoint point) {
    if (!contains(point) || layout.drawWidth <= 0 || layout.drawHeight <= 0) {
      return null;
    }
    final px = ((point.x - layout.offsetX) / layout.drawWidth * imageWidth)
        .floor();
    final py = ((point.y - layout.offsetY) / layout.drawHeight * imageHeight)
        .floor();
    return ImagePixelPoint(
      px.clamp(0, imageWidth - 1).toDouble(),
      py.clamp(0, imageHeight - 1).toDouble(),
    );
  }

  ViewportPoint toViewport(ImagePixelPoint point) {
    if (layout.drawWidth <= 0 ||
        layout.drawHeight <= 0 ||
        imageWidth <= 0 ||
        imageHeight <= 0) {
      return const ViewportPoint(0, 0);
    }
    return ViewportPoint(
      layout.offsetX + point.x / imageWidth * layout.drawWidth,
      layout.offsetY + point.y / imageHeight * layout.drawHeight,
    );
  }

  ImagePixelRect? toImageRect(ViewportPoint a, ViewportPoint b) {
    final dragged = layout.boxToPixelRect(
      x0: a.x,
      y0: a.y,
      x1: b.x,
      y1: b.y,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
    if (dragged == null) return null;
    return ImagePixelRect(
      x: dragged.x,
      y: dragged.y,
      width: dragged.width,
      height: dragged.height,
    );
  }

  ViewportRect imageBounds() {
    return ViewportRect(
      left: layout.offsetX,
      top: layout.offsetY,
      width: layout.drawWidth,
      height: layout.drawHeight,
    );
  }
}
