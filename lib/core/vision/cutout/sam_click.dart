import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:wardrobe/core/vision/onnx/onnx_runtime.dart';
import 'package:wardrobe/core/vision/onnx/model_assets.dart';

class PromptPoint {
  const PromptPoint({required this.x, required this.y, required this.positive});

  final int x;
  final int y;
  final bool positive;

  @override
  bool operator ==(Object other) {
    return other is PromptPoint &&
        other.x == x &&
        other.y == y &&
        other.positive == positive;
  }

  @override
  int get hashCode => Object.hash(x, y, positive);
}

abstract class ClickSegmenter {
  Future<void> encode(img.Image rgb);
  Future<img.Image> predict(List<PromptPoint> points);
  Future<void> dispose();
}

class SamClickSegmenter implements ClickSegmenter {
  static const encoderAsset = 'assets/models/mobile_sam_encoder.onnx';
  static const decoderAsset = 'assets/models/mobile_sam_decoder.onnx';
  static const _size = 1024;
  static const _embedCount = 1 * 256 * 64 * 64;

  bool _loaded = false;
  List<double>? _embedding;
  int _origWidth = 0;
  int _origHeight = 0;
  int _inputWidth = 0;
  int _inputHeight = 0;

  Future<void> _ensureLoaded() async {
    if (_loaded) return;
    if (!Platform.isWindows) {
      throw const FormatException('精修目前只支持 Windows');
    }
    final encoder = await materializeAssetModel(
      assetPath: encoderAsset,
      fileName: 'mobile_sam_encoder.onnx',
      minBytes: 1000000,
    );
    final decoder = await materializeAssetModel(
      assetPath: decoderAsset,
      fileName: 'mobile_sam_decoder.onnx',
      minBytes: 1000000,
    );
    OnnxRuntime.loadSession('sam_enc', encoder.path);
    OnnxRuntime.loadSession('sam_dec', decoder.path);
    _loaded = true;
  }

  @override
  Future<void> encode(img.Image rgb) async {
    await _ensureLoaded();
    _origWidth = rgb.width;
    _origHeight = rgb.height;
    final scale = _size / math.max(rgb.width, rgb.height);
    _inputWidth = math.max(1, (rgb.width * scale).round());
    _inputHeight = math.max(1, (rgb.height * scale).round());
    final resized = img.copyResize(
      rgb,
      width: _inputWidth,
      height: _inputHeight,
      interpolation: img.Interpolation.linear,
    );
    final pixels = _inputWidth * _inputHeight * 3;
    final input = List<double>.filled(pixels, 0);
    var i = 0;
    for (var y = 0; y < _inputHeight; y++) {
      for (var x = 0; x < _inputWidth; x++) {
        final p = resized.getPixel(x, y);
        input[i++] = p.r.toDouble();
        input[i++] = p.g.toDouble();
        input[i++] = p.b.toDouble();
      }
    }
    final out = OnnxRuntime.runSession(
      name: 'sam_enc',
      inputs: [
        OnnxTensor('input_image', [_inputHeight, _inputWidth, 3], input),
      ],
      outputNames: const ['image_embeddings'],
      outputCounts: const [_embedCount],
    );
    if (out.isEmpty || out.first.values.length < _embedCount) {
      throw const FormatException('SAM Encoder 输出不完整');
    }
    _embedding = out.first.values.take(_embedCount).toList();
  }

  @override
  Future<img.Image> predict(List<PromptPoint> points) async {
    await _ensureLoaded();
    final embedding = _embedding;
    if (embedding == null || points.isEmpty) {
      throw const FormatException('还没有分析这张图');
    }
    final n = points.length + 1;
    final coords = List<double>.filled(n * 2, 0);
    final labels = List<double>.filled(n, 0);
    for (var i = 0; i < points.length; i++) {
      final pt = points[i];
      coords[i * 2] = pt.x * _inputWidth / _origWidth;
      coords[i * 2 + 1] = pt.y * _inputHeight / _origHeight;
      labels[i] = pt.positive ? 1 : 0;
    }
    labels[points.length] = -1;
    final maskIn = List<double>.filled(256 * 256, 0);
    final maskCount = _origWidth * _origHeight * 4;
    final out = OnnxRuntime.runSession(
      name: 'sam_dec',
      inputs: [
        OnnxTensor('image_embeddings', const [1, 256, 64, 64], embedding),
        OnnxTensor('point_coords', [1, n, 2], coords),
        OnnxTensor('point_labels', [1, n], labels),
        OnnxTensor('mask_input', const [1, 1, 256, 256], maskIn),
        OnnxTensor('has_mask_input', const [1], const [0]),
        OnnxTensor(
          'orig_im_size',
          const [2],
          [_origHeight.toDouble(), _origWidth.toDouble()],
        ),
      ],
      outputNames: const ['masks'],
      outputCounts: [maskCount],
    );
    final values = out.first.values;
    final mask = img.Image(width: _origWidth, height: _origHeight, numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(0, 0, 0));
    final plane = _origWidth * _origHeight;
    final offset = values.length >= plane * 2 ? values.length - plane : 0;
    for (var i = 0; i < plane && i + offset < values.length; i++) {
      if (values[offset + i] <= 0) continue;
      final x = i % _origWidth;
      final y = i ~/ _origWidth;
      mask.setPixelRgb(x, y, 255, 255, 255);
    }
    return mask;
  }

  @override
  Future<void> dispose() async {
    if (_loaded) {
      OnnxRuntime.closeSession('sam_enc');
      OnnxRuntime.closeSession('sam_dec');
      _loaded = false;
    }
    _embedding = null;
  }
}

class FakeClickSegmenter implements ClickSegmenter {
  int _width = 0;
  int _height = 0;

  @override
  Future<void> encode(img.Image rgb) async {
    _width = rgb.width;
    _height = rgb.height;
  }

  @override
  Future<img.Image> predict(List<PromptPoint> points) async {
    final mask = img.Image(width: math.max(1, _width), height: math.max(1, _height), numChannels: 3);
    img.fill(mask, color: img.ColorRgb8(0, 0, 0));
    for (final point in points) {
      final color = point.positive ? 255 : 0;
      final radius = point.positive ? 18 : 14;
      for (var y = point.y - radius; y <= point.y + radius; y++) {
        for (var x = point.x - radius; x <= point.x + radius; x++) {
          if (x < 0 || y < 0 || x >= mask.width || y >= mask.height) continue;
          if ((x - point.x) * (x - point.x) + (y - point.y) * (y - point.y) > radius * radius) {
            continue;
          }
          mask.setPixelRgb(x, y, color, color, color);
        }
      }
    }
    return mask;
  }

  @override
  Future<void> dispose() async {}
}
