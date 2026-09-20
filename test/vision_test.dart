import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:wardrobe/core/storage/image_picker.dart';
import 'package:wardrobe/core/vision/color_extract.dart';
import 'package:wardrobe/core/vision/color_guide.dart';
import 'package:wardrobe/core/vision/contain_map.dart';
import 'package:wardrobe/core/vision/erase_brush.dart';
import 'package:wardrobe/core/vision/fill_patch.dart';
import 'package:wardrobe/core/vision/garment_pipeline.dart';
import 'package:wardrobe/core/vision/image_ops.dart';
import 'package:wardrobe/core/vision/sam_click.dart';
import 'package:wardrobe/core/vision/shadow_heal.dart';
import 'package:wardrobe/core/vision/u2net_segmenter.dart';

void main() {
  test('colorNameFromRgb maps basic swatches', () {
    expect(colorNameFromRgb(250, 250, 250), '白');
    expect(colorNameFromRgb(8, 8, 8), '黑');
    expect(colorNameFromRgb(220, 30, 30), '红');
    expect(colorNameFromRgb(30, 80, 210), '蓝');
    expect(colorNameFromRgb(40, 110, 50), '绿');
  });

  test('labToRgb round-trips a navy swatch', () {
    const r = 18, g = 28, b = 48;
    final back = labToRgb(rgbToLab(r, g, b));
    expect(back[0], closeTo(r, 4));
    expect(back[1], closeTo(g, 4));
    expect(back[2], closeTo(b, 4));
  });

  test('extractColors reports the dominant named color', () {
    final image = img.Image(width: 20, height: 20, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(20, 70, 200));
    final analysis = extractColors(image);
    expect(analysis.label, '蓝');
    expect(analysis.colors.first.ratio, greaterThan(0.9));
  });

  test('extractColors ignores masked-out background', () {
    final image = img.Image(width: 20, height: 20, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(240, 240, 240));
    for (var y = 5; y < 15; y++) {
      for (var x = 5; x < 15; x++) {
        image.setPixelRgb(x, y, 200, 30, 30);
      }
    }
    final mask = img.Image(width: 20, height: 20, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(0, 0, 0));
    for (var y = 5; y < 15; y++) {
      for (var x = 5; x < 15; x++) {
        mask.setPixelRgb(x, y, 255, 255, 255);
      }
    }
    expect(extractColors(image, mask: mask).label, '红');
  });

  test('bakeAndScale shrinks the long edge', () {
    final source = img.Image(width: 3200, height: 800, numChannels: 3);
    final scaled = bakeAndScale(source, maxEdge: 1600);
    expect(scaled.width, 1600);
    expect(scaled.height, 400);
  });

  test('cropToMask tightens around the foreground', () {
    final image = img.Image(width: 100, height: 80, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(10, 10, 10));
    final mask = img.Image(width: 100, height: 80, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(0, 0, 0));
    for (var y = 20; y < 40; y++) {
      for (var x = 30; x < 50; x++) {
        mask.setPixelRgb(x, y, 255, 255, 255);
      }
    }
    final cropped = cropToMask(image, mask, padding: 0.05);
    expect(cropped.image.width, lessThan(100));
    expect(cropped.image.height, lessThan(80));
    expect(cropped.image.width, cropped.mask.width);
  });

  test('pipeline with a fake mask writes a cutout and color', () async {
    final image = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(255, 255, 255));
    for (var y = 10; y < 30; y++) {
      for (var x = 10; x < 30; x++) {
        image.setPixelRgb(x, y, 20, 90, 200);
      }
    }
    final bytes = Uint8List.fromList(img.encodePng(image));
    final pipeline = GarmentPipeline(_CenterRectSegmenter());
    final result = await pipeline.processBytes(bytes);
    expect(result.hasCutout, isTrue);
    expect(result.maskPng, isNotNull);
    expect(result.fullCutoutPng, isNotNull);
    expect(result.colors.label, '蓝');
    expect(result.colors.hasPalette, isTrue);
    expect(result.originalWidth, 40);
    expect(result.originalHeight, 40);
    final original = img.decodeImage(result.originalBytes)!;
    expect(original.width, 40);
    expect(original.height, 40);
    final full = img.decodeImage(result.fullCutoutPng!)!;
    expect(full.width, 40);
    expect(full.height, 40);
  });

  test('ingestBytes keeps the photo without a first-pass cutout', () async {
    final image = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(20, 90, 200));
    final pipeline = GarmentPipeline(_CenterRectSegmenter());
    final result = await pipeline.ingestBytes(Uint8List.fromList(img.encodePng(image)));
    expect(result.hasCutout, isFalse);
    expect(result.maskPng, isNull);
    expect(result.originalWidth, 40);
    expect(result.originalHeight, 40);
    expect(result.error, isNull);
  });

  test('cropRect clamps to the image', () {
    final image = img.Image(width: 50, height: 40, numChannels: 3);
    final cropped = cropRect(
      image,
      const PixelRect(x: 10, y: 5, width: 20, height: 20),
    );
    expect(cropped.width, 20);
    expect(cropped.height, 20);
  });

  test('PixelRect.fromCorners swaps inverted corners', () {
    final rect = PixelRect.fromCorners(30, 40, 10, 20);
    expect(rect.x, 10);
    expect(rect.y, 20);
    expect(rect.width, 20);
    expect(rect.height, 20);
  });

  test('pasteMask writes a local patch without clearing the rest', () {
    final dest = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(dest, color: img.ColorRgb8(0, 0, 0));
    for (var y = 0; y < 16; y++) {
      for (var x = 0; x < 16; x++) {
        dest.setPixelRgb(x, y, 255, 255, 255);
      }
    }
    final patch = img.Image(width: 16, height: 16, numChannels: 3);
    img.fill(patch, color: img.ColorRgb8(200, 200, 200));
    pasteMask(dest, patch, const PixelRect(x: 20, y: 20, width: 16, height: 16));
    expect(maskLevel(dest.getPixel(4, 4)), 255);
    expect(maskLevel(dest.getPixel(24, 24)), 200);
    expect(maskLevel(dest.getPixel(38, 8)), 0);
  });

  test('refineBytes pastes the boxed crop into the existing mask', () async {
    final image = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(240, 240, 240));
    for (var y = 40; y < 80; y++) {
      for (var x = 40; x < 80; x++) {
        image.setPixelRgb(x, y, 20, 90, 200);
      }
    }
    final existing = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(existing, color: img.ColorRgb8(0, 0, 0));
    for (var y = 8; y < 24; y++) {
      for (var x = 8; x < 24; x++) {
        existing.setPixelRgb(x, y, 255, 255, 255);
      }
    }
    final segmenter = _RecordingSegmenter();
    final pipeline = GarmentPipeline(segmenter);
    final result = await pipeline.refineBytes(
      originalBytes: Uint8List.fromList(img.encodePng(image)),
      maskBytes: Uint8List.fromList(img.encodePng(existing)),
      region: const PixelRect(x: 40, y: 40, width: 40, height: 40),
      palette: const [RgbSwatch(20, 90, 200)],
    );
    expect(result.originalWidth, 80);
    expect(result.originalHeight, 80);
    expect(result.fullCutoutPng, isNotNull);
    final mask = img.decodeImage(result.maskPng!)!;
    expect(mask.width, 80);
    expect(mask.height, 80);
    expect(maskLevel(mask.getPixel(12, 12)), greaterThan(200));
    expect(maskLevel(mask.getPixel(60, 60)), greaterThan(200));
    expect(maskLevel(mask.getPixel(4, 60)), lessThan(24));
  });

  test('extractPalette ignores a thin hanger-like stripe', () {
    final image = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(18, 28, 48));
    final mask = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    for (var y = 8; y < 12; y++) {
      for (var x = 16; x < 64; x++) {
        image.setPixelRgb(x, y, 210, 198, 176);
      }
    }
    final palette = extractPalette(image, mask);
    expect(palette, isNotEmpty);
    for (final swatch in palette) {
      expect(swatch.r, lessThan(80));
      expect(swatch.b, lessThan(90));
    }
  });

  test('guideMaskWithPalette punches out beige against a navy palette', () {
    final image = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(18, 28, 48));
    final mask = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    for (var y = 6; y < 14; y++) {
      for (var x = 8; x < 32; x++) {
        image.setPixelRgb(x, y, 210, 198, 176);
      }
    }
    guideMaskWithPalette(image, mask, const [RgbSwatch(18, 28, 48)]);
    expect(maskLevel(mask.getPixel(20, 20)), greaterThan(200));
    expect(maskLevel(mask.getPixel(20, 10)), lessThan(24));
  });

  test('fillRefineGaps closes a thin hanger gap with garment color', () {
    final image = img.Image(width: 48, height: 48, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(18, 28, 48));
    final mask = img.Image(width: 48, height: 48, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    for (var y = 20; y < 24; y++) {
      for (var x = 8; x < 40; x++) {
        image.setPixelRgb(x, y, 210, 198, 176);
        mask.setPixelRgb(x, y, 0, 0, 0);
      }
    }
    const palette = [RgbSwatch(18, 28, 48)];
    final filled = fillRefineGaps(
      image,
      mask,
      const PixelRect(x: 6, y: 16, width: 36, height: 14),
      palette,
      radius: 8,
    );
    expect(maskLevel(mask.getPixel(24, 22)), greaterThan(200));
    expect(filled.getPixel(24, 22).r.toInt(), lessThan(80));
  });

  test('fillEnclosedHoles leaves a large neck-like hole', () {
    final mask = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    for (var y = 10; y < 30; y++) {
      for (var x = 10; x < 30; x++) {
        mask.setPixelRgb(x, y, 0, 0, 0);
      }
    }
    fillEnclosedHoles(
      mask,
      const PixelRect(x: 0, y: 0, width: 40, height: 40),
      80,
    );
    expect(maskLevel(mask.getPixel(20, 20)), lessThan(24));
    expect(maskLevel(mask.getPixel(2, 2)), greaterThan(200));
  });

  test('refineBytes drops hanger pixels that do not match the garment palette', () async {
    final image = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(18, 28, 48));
    for (var y = 10; y < 18; y++) {
      for (var x = 20; x < 60; x++) {
        image.setPixelRgb(x, y, 210, 198, 176);
      }
    }
    final existing = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(existing, color: img.ColorRgb8(255, 255, 255));
    final pipeline = GarmentPipeline(_AllForegroundSegmenter());
    final result = await pipeline.refineBytes(
      originalBytes: Uint8List.fromList(img.encodePng(image)),
      maskBytes: Uint8List.fromList(img.encodePng(existing)),
      region: const PixelRect(x: 16, y: 6, width: 48, height: 24),
      palette: const [RgbSwatch(18, 28, 48)],
    );
    final mask = img.decodeImage(result.maskPng!)!;
    expect(maskLevel(mask.getPixel(40, 40)), greaterThan(200));
    expect(maskLevel(mask.getPixel(40, 14)), greaterThan(200));
    final full = img.decodeImage(result.fullCutoutPng!)!;
    expect(full.getPixel(40, 14).r.toInt(), lessThan(80));
    expect(full.getPixel(40, 14).b.toInt(), lessThan(90));
    expect(result.colors.palette, isNotEmpty);
  });

  test('refineBytes erase clears the boxed mask', () async {
    final image = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(18, 28, 48));
    final existing = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(existing, color: img.ColorRgb8(255, 255, 255));
    final pipeline = GarmentPipeline(_AllForegroundSegmenter());
    final result = await pipeline.refineBytes(
      originalBytes: Uint8List.fromList(img.encodePng(image)),
      maskBytes: Uint8List.fromList(img.encodePng(existing)),
      region: const PixelRect(x: 10, y: 10, width: 12, height: 12),
      palette: const [RgbSwatch(18, 28, 48)],
      op: RefineOp.erase,
    );
    final mask = img.decodeImage(result.maskPng!)!;
    expect(maskLevel(mask.getPixel(16, 16)), lessThan(24));
    expect(maskLevel(mask.getPixel(2, 2)), greaterThan(200));
  });

  test('ColorAnalysis round-trips palette through json', () {
    const analysis = ColorAnalysis(
      [ColorShare(name: '黑', ratio: 0.9)],
      palette: [RgbSwatch(18, 28, 48)],
    );
    final decoded = ColorAnalysis.decode(analysis.toJson());
    expect(decoded.label, '黑');
    expect(decoded.palette.single.r, 18);
    expect(decoded.palette.single.g, 28);
    expect(decoded.palette.single.b, 48);
    expect(ColorAnalysis.decode('{"colors":[]}').hasPalette, isFalse);
  });

  test('fake SAM keeps a disk around a positive click and replaces the mask', () async {
    final image = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(20, 90, 200));
    final bytes = Uint8List.fromList(img.encodePng(image));
    final pipeline = GarmentPipeline(
      _CenterRectSegmenter(),
      clickSegmenter: FakeClickSegmenter(),
    );
    await pipeline.prepareRefine(bytes);
    final result = await pipeline.refineWithClicks(
      originalBytes: bytes,
      points: const [PromptPoint(x: 5, y: 5, positive: true)],
    );
    final mask = img.decodeImage(result.maskPng!)!;
    expect(maskLevel(mask.getPixel(5, 5)), 255);
    expect(maskLevel(mask.getPixel(20, 20)), 0);
    expect(result.fullCutoutPng, isNotNull);
    expect(result.originalWidth, 40);
    expect(result.originalHeight, 40);
  });

  test('fake SAM negative click punches a hole in a positive disk', () async {
    final image = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(20, 90, 200));
    final bytes = Uint8List.fromList(img.encodePng(image));
    final pipeline = GarmentPipeline(
      _CenterRectSegmenter(),
      clickSegmenter: FakeClickSegmenter(),
    );
    await pipeline.prepareRefine(bytes);
    final result = await pipeline.refineWithClicks(
      originalBytes: bytes,
      points: const [
        PromptPoint(x: 20, y: 20, positive: true),
        PromptPoint(x: 20, y: 20, positive: false),
      ],
    );
    final mask = img.decodeImage(result.maskPng!)!;
    expect(maskLevel(mask.getPixel(20, 20)), 0);
    expect(maskLevel(mask.getPixel(36, 20)), 255);
  });

  test('erase stroke punches a disk and can protect garment color', () {
    final rgb = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(rgb, color: img.ColorRgb8(18, 28, 48));
    for (var y = 4; y < 12; y++) {
      for (var x = 4; x < 12; x++) {
        rgb.setPixelRgb(x, y, 210, 198, 176);
      }
    }
    final mask = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    const palette = [RgbSwatch(18, 28, 48)];
    final protected = applyEraseStroke(
      rgb,
      mask,
      const EraseStroke(
        stamps: [EraseStamp(x: 8, y: 8, radius: 8)],
      ),
      palette: palette,
    );
    expect(protected, greaterThan(0));
    expect(maskLevel(mask.getPixel(8, 8)), lessThan(24));
    expect(maskLevel(mask.getPixel(30, 30)), 255);
    applyEraseStroke(
      rgb,
      mask,
      const EraseStroke(
        stamps: [EraseStamp(x: 30, y: 30, radius: 6)],
        protectColor: false,
      ),
      palette: palette,
    );
    expect(maskLevel(mask.getPixel(30, 30)), lessThan(24));
  });

  test('eraseDarkerShadows punches a dark stain next to an erased hole', () {
    final rgb = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(rgb, color: img.ColorRgb8(18, 28, 48));
    final mask = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    final before = img.Image.from(mask);
    for (var y = 28; y < 36; y++) {
      for (var x = 20; x < 60; x++) {
        mask.setPixelRgb(x, y, 0, 0, 0);
      }
    }
    final after = img.Image.from(mask);
    for (var y = 36; y < 48; y++) {
      for (var x = 20; x < 60; x++) {
        rgb.setPixelRgb(x, y, 6, 10, 18);
      }
    }
    final punched = eraseDarkerShadows(
      rgb,
      mask,
      before,
      after,
      const [FillPatch.box(PixelRect(x: 4, y: 4, width: 16, height: 16))],
    );
    expect(punched, greaterThan(0));
    expect(maskLevel(mask.getPixel(40, 40)), lessThan(24));
    expect(maskLevel(mask.getPixel(8, 8)), 255);
    expect(rgb.getPixel(8, 8).b.toInt(), 48);
  });

  test('second fill after darker-shadow erase copies sample texture', () {
    final rgb = img.Image(width: 80, height: 80, numChannels: 3);
    final mask = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    for (var y = 0; y < 80; y++) {
      for (var x = 0; x < 80; x++) {
        if (x.isEven) {
          rgb.setPixelRgb(x, y, 18, 28, 48);
        } else {
          rgb.setPixelRgb(x, y, 18, 28, 96);
        }
      }
    }
    final before = img.Image.from(mask);
    for (var y = 28; y < 36; y++) {
      for (var x = 20; x < 60; x++) {
        mask.setPixelRgb(x, y, 0, 0, 0);
      }
    }
    final after = img.Image.from(mask);
    for (var y = 36; y < 48; y++) {
      for (var x = 20; x < 60; x++) {
        rgb.setPixelRgb(x, y, 6, 10, 18);
      }
    }
    const patch = FillPatch.box(PixelRect(x: 4, y: 4, width: 16, height: 16));
    final beforeShadow = img.Image.from(mask);
    eraseDarkerShadows(rgb, mask, before, after, const [patch]);
    applyFillPatch(rgb, mask, patch, beforeErase: beforeShadow);
    expect(maskLevel(mask.getPixel(40, 40)), 255);
    final a = rgb.getPixel(40, 40).b.toInt();
    final b = rgb.getPixel(41, 40).b.toInt();
    expect((a - b).abs(), greaterThan(20));
    expect(rgb.getPixel(40, 40).r.toInt(), lessThan(40));
  });

  test('refineEdits reapplies erase after a fake SAM click', () async {
    final image = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(20, 90, 200));
    for (var y = 6; y < 12; y++) {
      for (var x = 16; x < 24; x++) {
        image.setPixelRgb(x, y, 210, 198, 176);
      }
    }
    final bytes = Uint8List.fromList(img.encodePng(image));
    final existing = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(existing, color: img.ColorRgb8(255, 255, 255));
    final pipeline = GarmentPipeline(
      _CenterRectSegmenter(),
      clickSegmenter: FakeClickSegmenter(),
    );
    await pipeline.prepareRefine(bytes);
    final result = await pipeline.refineEdits(
      originalBytes: bytes,
      maskBytes: Uint8List.fromList(img.encodePng(existing)),
      points: const [PromptPoint(x: 20, y: 20, positive: true)],
      strokes: const [
        EraseStroke(
          stamps: [EraseStamp(x: 20, y: 9, radius: 5)],
        ),
      ],
      palette: const [RgbSwatch(20, 90, 200)],
    );
    final mask = img.decodeImage(result.maskPng!)!;
    expect(maskLevel(mask.getPixel(20, 20)), 255);
    expect(maskLevel(mask.getPixel(20, 9)), lessThan(24));
  });

  test('fill patch paints sampled garment color into a hole in the box', () {
    final rgb = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(rgb, color: img.ColorRgb8(18, 28, 48));
    final mask = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    for (var y = 8; y < 14; y++) {
      for (var x = 8; x < 14; x++) {
        mask.setPixelRgb(x, y, 0, 0, 0);
        rgb.setPixelRgb(x, y, 210, 198, 176);
      }
    }
    final filled = applyFillPatch(
      rgb,
      mask,
      const FillPatch.box(PixelRect(x: 4, y: 4, width: 24, height: 24)),
    );
    expect(filled, greaterThan(0));
    expect(maskLevel(mask.getPixel(10, 10)), 255);
    expect(rgb.getPixel(10, 10).b.toInt(), greaterThan(30));
    expect(rgb.getPixel(10, 10).r.toInt(), lessThan(80));
  });

  test('fill patch copies stripe texture from the sample', () {
    final rgb = img.Image(width: 40, height: 40, numChannels: 3);
    final mask = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    for (var y = 0; y < 40; y++) {
      for (var x = 0; x < 40; x++) {
        if (x.isEven) {
          rgb.setPixelRgb(x, y, 18, 28, 48);
        } else {
          rgb.setPixelRgb(x, y, 18, 28, 96);
        }
      }
    }
    for (var y = 12; y < 20; y++) {
      for (var x = 12; x < 20; x++) {
        mask.setPixelRgb(x, y, 0, 0, 0);
        rgb.setPixelRgb(x, y, 210, 198, 176);
      }
    }
    final before = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(before, color: img.ColorRgb8(255, 255, 255));
    applyFillPatch(
      rgb,
      mask,
      const FillPatch.box(PixelRect(x: 4, y: 4, width: 8, height: 8)),
      beforeErase: before,
    );
    expect(maskLevel(mask.getPixel(14, 14)), 255);
    final a = rgb.getPixel(14, 14).b.toInt();
    final b = rgb.getPixel(15, 14).b.toInt();
    expect((a - b).abs(), greaterThan(20));
  });

  test('fill patch skips a far-away hole outside the sample', () {
    final rgb = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(rgb, color: img.ColorRgb8(18, 28, 48));
    final mask = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    mask.setPixelRgb(2, 2, 0, 0, 0);
    applyFillPatch(
      rgb,
      mask,
      const FillPatch.box(PixelRect(x: 60, y: 60, width: 12, height: 12)),
      maxDist: 24,
    );
    expect(maskLevel(mask.getPixel(2, 2)), lessThan(24));
    expect(maskLevel(mask.getPixel(64, 64)), 255);
  });

  test('refineEdits fill restores an erased hole from nearby color', () async {
    final image = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(image, color: img.ColorRgb8(18, 28, 48));
    final existing = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(existing, color: img.ColorRgb8(255, 255, 255));
    final pipeline = GarmentPipeline(_AllForegroundSegmenter());
    final result = await pipeline.refineEdits(
      originalBytes: Uint8List.fromList(img.encodePng(image)),
      maskBytes: Uint8List.fromList(img.encodePng(existing)),
      strokes: const [
        EraseStroke(
          stamps: [EraseStamp(x: 8, y: 8, radius: 5)],
          protectColor: false,
        ),
      ],
      fills: const [
        FillPatch.box(PixelRect(x: 2, y: 2, width: 22, height: 22)),
      ],
      palette: const [RgbSwatch(18, 28, 48)],
    );
    final mask = img.decodeImage(result.maskPng!)!;
    expect(maskLevel(mask.getPixel(8, 8)), 255);
    final full = img.decodeImage(result.fullCutoutPng!)!;
    expect(full.getPixel(8, 8).b.toInt(), greaterThan(30));
  });

  test('fill still works when the box is mostly the hole', () {
    final rgb = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(rgb, color: img.ColorRgb8(18, 28, 48));
    final mask = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    for (var y = 10; y < 30; y++) {
      for (var x = 10; x < 30; x++) {
        mask.setPixelRgb(x, y, 0, 0, 0);
        rgb.setPixelRgb(x, y, 210, 198, 176);
      }
    }
    final filled = applyFillPatch(
      rgb,
      mask,
      const FillPatch.box(PixelRect(x: 8, y: 8, width: 24, height: 24)),
    );
    expect(filled, greaterThan(0));
    expect(maskLevel(mask.getPixel(20, 20)), 255);
    expect(rgb.getPixel(20, 20).r.toInt(), lessThan(80));
  });

  test('fill replaces leftover hanger color inside the sample box', () {
    final rgb = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(rgb, color: img.ColorRgb8(18, 28, 48));
    final mask = img.Image(width: 40, height: 40, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    for (var y = 8; y < 32; y++) {
      for (var x = 16; x < 22; x++) {
        rgb.setPixelRgb(x, y, 210, 198, 176);
      }
    }
    final filled = applyFillPatch(
      rgb,
      mask,
      const FillPatch.box(PixelRect(x: 10, y: 6, width: 22, height: 28)),
      palette: const [RgbSwatch(18, 28, 48)],
    );
    expect(filled, greaterThan(0));
    expect(maskLevel(mask.getPixel(18, 20)), 255);
    expect(rgb.getPixel(18, 20).r.toInt(), lessThan(80));
    expect(rgb.getPixel(18, 20).b.toInt(), greaterThan(30));
  });

  test('fill restores a far erased hole from sampled fabric', () {
    final rgb = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(rgb, color: img.ColorRgb8(18, 28, 48));
    final mask = img.Image(width: 80, height: 80, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(255, 255, 255));
    final before = img.Image.from(mask);
    for (var y = 6; y < 14; y++) {
      for (var x = 6; x < 14; x++) {
        mask.setPixelRgb(x, y, 0, 0, 0);
        rgb.setPixelRgb(x, y, 210, 198, 176);
      }
    }
    final filled = applyFillPatch(
      rgb,
      mask,
      const FillPatch.box(PixelRect(x: 60, y: 60, width: 12, height: 12)),
      beforeErase: before,
      palette: const [RgbSwatch(18, 28, 48)],
    );
    expect(filled, greaterThan(0));
    expect(maskLevel(mask.getPixel(8, 8)), 255);
    expect(rgb.getPixel(8, 8).r.toInt(), lessThan(80));
  });

  test('ContainLayout maps a click to original pixels', () {
    final layout = ContainLayout.of(
      boxWidth: 200,
      boxHeight: 100,
      imageWidth: 100,
      imageHeight: 100,
    );
    expect(layout.offsetX, 50);
    expect(layout.offsetY, 0);
    expect(layout.drawWidth, 100);
    expect(layout.drawHeight, 100);
    final rect = layout.boxToPixelRect(
      x0: 60,
      y0: 10,
      x1: 90,
      y1: 40,
      imageWidth: 100,
      imageHeight: 100,
    );
    expect(rect, isNotNull);
    expect(rect!.x, 10);
    expect(rect.y, 10);
    expect(rect.width, 30);
    expect(rect.height, 30);
    final local = layout.pixelRectToLocal(
      rect,
      imageWidth: 100,
      imageHeight: 100,
    );
    expect(local.left, closeTo(60, 0.001));
    expect(local.top, closeTo(10, 0.001));
    expect(local.width, closeTo(30, 0.001));
    expect(local.height, closeTo(30, 0.001));
    final roundTrip = layout.boxToPixelRect(
      x0: local.left,
      y0: local.top,
      x1: local.right,
      y1: local.bottom,
      imageWidth: 100,
      imageHeight: 100,
    );
    expect(roundTrip, isNotNull);
    expect(roundTrip!.x, 10);
    expect(roundTrip.y, 10);
    expect(roundTrip.width, 30);
    expect(roundTrip.height, 30);
    final pixel = layout.localToPixel(70, 20, imageWidth: 100, imageHeight: 100);
    expect(pixel, isNotNull);
    expect(pixel!.x, 20);
    expect(pixel.y, 20);
    expect(layout.contains(10, 10), isFalse);
    expect(layout.contains(70, 20), isTrue);
  });

  test('ContainLayout ignores a drag that stays in letterbox', () {
    final layout = ContainLayout.of(
      boxWidth: 200,
      boxHeight: 100,
      imageWidth: 100,
      imageHeight: 100,
    );
    expect(
      layout.boxToPixelRect(
        x0: 0,
        y0: 0,
        x1: 20,
        y1: 20,
        imageWidth: 100,
        imageHeight: 100,
      ),
      isNull,
    );
  });

  test('parseWindowsMultiSelect joins directory and file names', () {
    final units = Uint16List.fromList([
      ...'C:\\pics'.codeUnits,
      0,
      ...'a.jpg'.codeUnits,
      0,
      ...'b.png'.codeUnits,
      0,
      0,
    ]);
    expect(parseWindowsMultiSelect(units), [
      'C:\\pics\\a.jpg',
      'C:\\pics\\b.png',
    ]);
  });

  test('parseWindowsMultiSelect keeps a single full path', () {
    final units = Uint16List.fromList([...'D:\\one.png'.codeUnits, 0, 0]);
    expect(parseWindowsMultiSelect(units), ['D:\\one.png']);
  });
}

class _RecordingSegmenter extends _CenterRectSegmenter {
  int? lastWidth;
  int? lastHeight;

  @override
  Future<img.Image> mask(img.Image rgb) async {
    lastWidth = rgb.width;
    lastHeight = rgb.height;
    return super.mask(rgb);
  }
}

class _AllForegroundSegmenter implements ForegroundSegmenter {
  @override
  Future<img.Image> mask(img.Image rgb) async {
    final out = img.Image(width: rgb.width, height: rgb.height, numChannels: 3);
    img.fill(out, color: img.ColorRgb8(255, 255, 255));
    return out;
  }

  @override
  Future<void> dispose() async {}
}

class _CenterRectSegmenter implements ForegroundSegmenter {
  @override
  Future<img.Image> mask(img.Image rgb) async {
    final out = img.Image(width: rgb.width, height: rgb.height, numChannels: 3);
    img.fill(out, color: img.ColorRgb8(0, 0, 0));
    final x0 = rgb.width ~/ 4;
    final y0 = rgb.height ~/ 4;
    final x1 = rgb.width - x0;
    final y1 = rgb.height - y0;
    for (var y = y0; y < y1; y++) {
      for (var x = x0; x < x1; x++) {
        out.setPixelRgb(x, y, 255, 255, 255);
      }
    }
    return out;
  }

  @override
  Future<void> dispose() async {}
}
