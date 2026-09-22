import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:wardrobe/core/vision/cutout/color_extract.dart';
import 'package:wardrobe/core/vision/cutout/color_guide.dart';
import 'package:wardrobe/core/vision/cutout/erase_brush.dart';
import 'package:wardrobe/core/vision/cutout/fill_patch.dart';
import 'package:wardrobe/core/vision/cutout/image_ops.dart';
import 'package:wardrobe/core/vision/cutout/sam_click.dart';
import 'package:wardrobe/core/vision/cutout/u2net_segmenter.dart';

class GarmentProcessResult {
  const GarmentProcessResult({
    required this.originalBytes,
    required this.originalExtension,
    required this.originalWidth,
    required this.originalHeight,
    this.cutoutPng,
    this.maskPng,
    this.fullCutoutPng,
    this.colors = ColorAnalysis.empty,
    this.error,
    this.filledCount = 0,
  });

  final Uint8List originalBytes;
  final String originalExtension;
  final int originalWidth;
  final int originalHeight;
  final Uint8List? cutoutPng;
  final Uint8List? maskPng;
  final Uint8List? fullCutoutPng;
  final ColorAnalysis colors;
  final String? error;
  final int filledCount;

  bool get hasCutout => cutoutPng != null && cutoutPng!.isNotEmpty;
}

enum RefineOp { keepColor, erase }

class GarmentPipeline {
  GarmentPipeline(this.segmenter, {this.clickSegmenter});

  final ForegroundSegmenter segmenter;
  final ClickSegmenter? clickSegmenter;

  Future<GarmentProcessResult> ingestBytes(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('无法解码这张图片');
    }
    final scaled = bakeAndScale(decoded);
    return GarmentProcessResult(
      originalBytes: Uint8List.fromList(img.encodeJpg(scaled, quality: 90)),
      originalExtension: '.jpg',
      originalWidth: scaled.width,
      originalHeight: scaled.height,
    );
  }

  Future<GarmentProcessResult> processBytes(Uint8List bytes) async {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('无法解码这张图片');
    }
    final scaled = bakeAndScale(decoded);
    try {
      return _finish(scaled, await _segment(scaled));
    } catch (_) {
      return GarmentProcessResult(
        originalBytes: Uint8List.fromList(img.encodeJpg(scaled, quality: 90)),
        originalExtension: '.jpg',
        originalWidth: scaled.width,
        originalHeight: scaled.height,
        error: '抠图失败，已保留原图',
      );
    }
  }

  Future<void> prepareRefine(Uint8List originalBytes) async {
    final click = clickSegmenter;
    if (click == null) {
      throw const FormatException('没有点选精修');
    }
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      throw const FormatException('无法解码这张图片');
    }
    await click.encode(bakeAndScale(decoded));
  }

  /// Replace the full mask using SAM clicks on the original photo.
  Future<GarmentProcessResult> refineWithClicks({
    required Uint8List originalBytes,
    required List<PromptPoint> points,
  }) {
    return refineEdits(originalBytes: originalBytes, points: points);
  }

  /// Rebuild the mask from optional SAM [points], then subtract [strokes]
  /// and stamp [fills] onto the painted pixels.
  Future<GarmentProcessResult> refineEdits({
    required Uint8List originalBytes,
    Uint8List? maskBytes,
    List<PromptPoint> points = const [],
    List<EraseStroke> strokes = const [],
    List<FillStroke> fills = const [],
    List<RgbSwatch> palette = const [],
  }) async {
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      throw const FormatException('无法解码这张图片');
    }
    final original = bakeAndScale(decoded);
    try {
      img.Image mask;
      if (points.isNotEmpty) {
        final click = clickSegmenter;
        if (click == null) {
          throw const FormatException('没有点选精修');
        }
        final predicted = await click.predict(points);
        mask = predicted.width == original.width && predicted.height == original.height
            ? predicted
            : resizeMask(predicted, original.width, original.height);
      } else {
        mask = maskMatchingOriginal(
          original,
          maskBytes == null ? null : img.decodeImage(maskBytes),
        );
      }
      final frozen = palette.isNotEmpty ? palette : extractPalette(original, mask);
      for (final stroke in strokes) {
        applyEraseStroke(original, mask, stroke, palette: frozen);
      }
      final rgb = img.Image.from(original);
      var filledCount = 0;
      for (final stroke in fills) {
        filledCount += applyFillPatch(
          rgb,
          mask,
          stroke,
          palette: frozen,
        );
      }
      final result = _finish(rgb, mask, palette: frozen);
      if (fills.isEmpty) return result;
      return GarmentProcessResult(
        originalBytes: result.originalBytes,
        originalExtension: result.originalExtension,
        originalWidth: result.originalWidth,
        originalHeight: result.originalHeight,
        cutoutPng: result.cutoutPng,
        maskPng: result.maskPng,
        fullCutoutPng: result.fullCutoutPng,
        colors: result.colors,
        error: result.error,
        filledCount: filledCount,
      );
    } catch (_) {
      return GarmentProcessResult(
        originalBytes: Uint8List.fromList(img.encodeJpg(original, quality: 90)),
        originalExtension: '.jpg',
        originalWidth: original.width,
        originalHeight: original.height,
        error: '精修失败，已保留上次结果',
      );
    }
  }

  /// Relabel [region] using first-cutout garment colors, or erase it.
  Future<GarmentProcessResult> refineBytes({
    required Uint8List originalBytes,
    Uint8List? maskBytes,
    required PixelRect region,
    List<RgbSwatch> palette = const [],
    RefineOp op = RefineOp.keepColor,
  }) async {
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      throw const FormatException('无法解码这张图片');
    }
    final original = bakeAndScale(decoded);
    final existing = maskBytes == null ? null : img.decodeImage(maskBytes);
    final mask = maskMatchingOriginal(original, existing);
    final box = clampPixelRect(region, original.width, original.height);
    final frozen = palette.isNotEmpty ? palette : extractPalette(original, mask);
    try {
      switch (op) {
        case RefineOp.erase:
          eraseMaskRegion(mask, box);
          return _finish(original, mask, palette: frozen);
        case RefineOp.keepColor:
          classifyMaskRegion(original, mask, box, frozen);
          final filled = fillRefineGaps(original, mask, box, frozen);
          return _finish(filled, mask, palette: frozen);
      }
    } catch (_) {
      return GarmentProcessResult(
        originalBytes: Uint8List.fromList(img.encodeJpg(original, quality: 90)),
        originalExtension: '.jpg',
        originalWidth: original.width,
        originalHeight: original.height,
        colors: ColorAnalysis(const [], palette: frozen),
        error: '精修失败，已保留上次结果',
      );
    }
  }

  Uint8List refinePreviewPng(
    Uint8List originalBytes,
    Uint8List? maskBytes, {
    List<RgbSwatch> palette = const [],
  }) {
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      throw const FormatException('无法解码这张图片');
    }
    final original = bakeAndScale(decoded);
    final existing = maskBytes == null ? null : img.decodeImage(maskBytes);
    if (existing != null &&
        existing.width == original.width &&
        existing.height == original.height) {
      final rgb = img.Image.from(original);
      if (palette.isNotEmpty) {
        inpaintUnmatched(
          rgb,
          existing,
          PixelRect(x: 0, y: 0, width: rgb.width, height: rgb.height),
          palette,
        );
      }
      return Uint8List.fromList(img.encodePng(applyAlpha(rgb, existing)));
    }
    return Uint8List.fromList(img.encodePng(original));
  }

  Future<img.Image> _segment(img.Image rgb) => segmenter.mask(rgb);

  GarmentProcessResult _finish(
    img.Image original,
    img.Image mask, {
    List<RgbSwatch>? palette,
  }) {
    final jpeg = Uint8List.fromList(img.encodeJpg(original, quality: 90));
    final cropped = cropToMask(original, mask);
    final tight = applyAlpha(cropped.image, cropped.mask);
    final full = applyAlpha(original, mask);
    final named = extractColors(cropped.image, mask: cropped.mask);
    final swatches = palette ?? extractPalette(original, mask);
    return GarmentProcessResult(
      originalBytes: jpeg,
      originalExtension: '.jpg',
      originalWidth: original.width,
      originalHeight: original.height,
      cutoutPng: Uint8List.fromList(img.encodePng(tight)),
      maskPng: Uint8List.fromList(img.encodePng(mask)),
      fullCutoutPng: Uint8List.fromList(img.encodePng(full)),
      colors: ColorAnalysis(named.colors, palette: swatches),
    );
  }
}
