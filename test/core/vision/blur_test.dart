import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wardrobe/core/vision/cutout/background_blur.dart';

void main() {
  test('blur keeps foreground pixels and changes the background', () {
    final source = img.Image(width: 30, height: 20, numChannels: 3);
    final mask = img.Image(width: 30, height: 20, numChannels: 3);
    for (var y = 0; y < source.height; y++) {
      for (var x = 0; x < source.width; x++) {
        if (x < 15) {
          source.setPixelRgb(x, y, 255, 0, 0);
          mask.setPixelRgb(x, y, 255, 255, 255);
        } else {
          source.setPixelRgb(x, y, 0, 0, 255);
          mask.setPixelRgb(x, y, 0, 0, 0);
        }
      }
    }

    final out = blurBackground(source, mask, radius: 8);
    final kept = out.getPixel(2, 10);
    expect(kept.r.toInt(), 255);
    expect(kept.g.toInt(), 0);
    expect(kept.b.toInt(), 0);

    final changed = out.getPixel(16, 10);
    final sameBlue =
        changed.r.toInt() == 0 &&
        changed.g.toInt() == 0 &&
        changed.b.toInt() == 255;
    expect(sameBlue, isFalse);
  });
}
