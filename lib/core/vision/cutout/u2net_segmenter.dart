import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:wardrobe/core/vision/onnx/onnx_runtime.dart';
import 'package:wardrobe/core/vision/cutout/image_ops.dart';
import 'package:wardrobe/core/vision/onnx/model_assets.dart';

abstract class ForegroundSegmenter {
  Future<img.Image> mask(img.Image rgb);
  Future<void> dispose();
}

class U2NetSegmenter implements ForegroundSegmenter {
  U2NetSegmenter();

  bool _loaded = false;
  static const _assetPath = 'assets/models/u2netp.onnx';
  static const _mean = [0.485, 0.456, 0.406];
  static const _std = [0.229, 0.224, 0.225];
  static const _outputCount = u2netInputSize * u2netInputSize;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    if (!Platform.isWindows) {
      throw const FormatException('抠图目前只支持 Windows');
    }
    final file = await materializeAssetModel(
      assetPath: _assetPath,
      fileName: 'u2netp.onnx',
    );
    OnnxRuntime.load(file.path);
    _loaded = true;
  }

  @override
  Future<img.Image> mask(img.Image rgb) async {
    await _ensureLoaded();
    final sized = resizeExact(rgb, u2netInputSize);
    final tensor = _toNchw(sized);
    final values = OnnxRuntime.run(tensor, _outputCount);
    final small = maskFromValues(values, u2netInputSize, u2netInputSize);
    return resizeMask(small, rgb.width, rgb.height);
  }

  List<double> _toNchw(img.Image image) {
    final plane = u2netInputSize * u2netInputSize;
    final data = List<double>.filled(3 * plane, 0);
    var maxPixel = 1.0;
    for (var y = 0; y < u2netInputSize; y++) {
      for (var x = 0; x < u2netInputSize; x++) {
        final p = image.getPixel(x, y);
        maxPixel = math.max(
          maxPixel,
          math.max(p.r.toDouble(), math.max(p.g.toDouble(), p.b.toDouble())),
        );
      }
    }
    for (var y = 0; y < u2netInputSize; y++) {
      for (var x = 0; x < u2netInputSize; x++) {
        final p = image.getPixel(x, y);
        final i = y * u2netInputSize + x;
        data[i] = (p.r / maxPixel - _mean[0]) / _std[0];
        data[plane + i] = (p.g / maxPixel - _mean[1]) / _std[1];
        data[2 * plane + i] = (p.b / maxPixel - _mean[2]) / _std[2];
      }
    }
    return data;
  }

  @override
  Future<void> dispose() async {
    if (_loaded) {
      OnnxRuntime.closeSession('u2net');
      _loaded = false;
    }
  }
}
