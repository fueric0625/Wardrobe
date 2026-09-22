import 'package:image/image.dart' as img;
import 'package:wardrobe/core/vision/cutout/image_ops.dart';

/// Keep pixels where [mask] is foreground. Blur the rest.
img.Image blurBackground(img.Image source, img.Image mask, {int radius = 18}) {
  final aligned = mask.width == source.width && mask.height == source.height
      ? mask
      : resizeMask(mask, source.width, source.height);
  final blurred = img.gaussianBlur(img.Image.from(source), radius: radius);
  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      if (maskLevel(aligned.getPixel(x, y)) >= 128) {
        blurred.setPixel(x, y, source.getPixel(x, y));
      }
    }
  }
  return blurred;
}
