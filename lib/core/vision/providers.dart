import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wardrobe/core/vision/cutout/garment_pipeline.dart';
import 'package:wardrobe/core/vision/cutout/sam_click.dart';
import 'package:wardrobe/core/vision/cutout/u2net_segmenter.dart';
import 'package:wardrobe/core/vision/ocr/tag_ocr.dart';

final u2netSegmenterProvider = Provider<U2NetSegmenter>((ref) {
  final segmenter = U2NetSegmenter();
  ref.onDispose(segmenter.dispose);
  return segmenter;
});

final samClickSegmenterProvider = Provider<SamClickSegmenter>((ref) {
  final segmenter = SamClickSegmenter();
  ref.onDispose(segmenter.dispose);
  return segmenter;
});

final tagOcrProvider = Provider<TagOcr>((ref) {
  final ocr = TagOcr();
  ref.onDispose(ocr.dispose);
  return ocr;
});

final garmentPipelineProvider = Provider<GarmentPipeline>((ref) {
  return GarmentPipeline(
    ref.watch(u2netSegmenterProvider),
    clickSegmenter: ref.watch(samClickSegmenterProvider),
  );
});
