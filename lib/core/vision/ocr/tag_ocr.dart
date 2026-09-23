import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:wardrobe/core/serialization/tag_ocr_codec.dart';
import 'package:wardrobe/core/vision/model/onnx_session.dart';
import 'package:wardrobe/core/vision/onnx/onnx_runtime.dart';
import 'package:wardrobe/core/vision/cutout/image_ops.dart';
import 'package:wardrobe/core/vision/onnx/model_assets.dart';

class TagOcrResult {
  const TagOcrResult({
    this.lines = const [],
    this.brand,
    this.fabric,
    this.sizeLabel,
    this.measurements = const {},
  });

  final List<String> lines;
  final String? brand;
  final String? fabric;
  final String? sizeLabel;
  final Map<String, String> measurements;

  String get text =>
      lines.map((l) => l.trim()).where((l) => l.isNotEmpty).join('\n');

  bool get isEmpty =>
      text.isEmpty &&
      (brand == null || brand!.isEmpty) &&
      (fabric == null || fabric!.isEmpty) &&
      (sizeLabel == null || sizeLabel!.isEmpty) &&
      measurements.isEmpty;

  Map<String, Object?> toJson() => {
    'lines': lines,
    if (brand != null && brand!.isNotEmpty) 'brand': brand,
    if (fabric != null && fabric!.isNotEmpty) 'fabric': fabric,
    if (sizeLabel != null && sizeLabel!.isNotEmpty) 'sizeLabel': sizeLabel,
    if (measurements.isNotEmpty) 'measurements': measurements,
  };

  factory TagOcrResult.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'];
    final text = json['text'] as String?;
    return TagOcrResult(
      lines: [
        if (rawLines is List)
          for (final line in rawLines) '$line'
        else if (text != null)
          ...text.split('\n'),
      ],
      brand: json['brand'] as String?,
      fabric: json['fabric'] as String?,
      sizeLabel: json['sizeLabel'] as String?,
      measurements: {
        if (json['measurements'] is Map)
          for (final entry in (json['measurements'] as Map).entries)
            '${entry.key}': '${entry.value}',
      },
    );
  }

  factory TagOcrResult.decode(String raw) => decodeTagOcr(raw);

  String encode() => encodeTagOcr(this);
}

final _labeled = RegExp(r'(品牌|牌名|BRAND)\s*[:：]\s*(.+)');
final _fabricLabeled = RegExp(
  r'(成分|面料|材质|纖維|纤维|FABRIC|MATERIAL)\s*[:：]\s*(.+)',
);
final _sizeLabeled = RegExp(r'(尺码|號型|号型|SIZE|Size)\s*[:：]?\s*([A-Za-z0-9/]+)');
final _letterSize = RegExp(
  r'\b(XXXL|XXL|XL|XXS|XS|S|M|L|均码)\b',
  caseSensitive: false,
);
final _codeSize = RegExp(r'\b(\d{2,3}\s*/\s*\d{2,3}[A-Fa-f]?)\b');
final _measure = RegExp(
  r'(衣长|裤长|裙长|胸围|腰围|臀围|肩宽|下摆围|大腿围|裤脚围|鞋码|尺寸)\s*[:：]?\s*(\d+(?:\.\d+)?)',
);
final _fiber = RegExp(
  r'((?:棉|聚酯纤维|聚酯纖維|涤纶|滌綸|氨纶|氨綸|羊毛|尼龙|尼龍|腈纶|腈綸|粘胶|黏膠|莫代尔|莫代爾|桑蚕丝|桑蠶絲|亚麻|亞麻|锦纶|錦綸)[^，,;；]{0,12})',
);
final _skipBrand = {
  'SIZE',
  'MADE',
  'IN',
  'THE',
  'COTTON',
  'POLYESTER',
  'CARE',
  'WASH',
};

/// Pull brand / fabric / size out of OCR lines. No model.
TagOcrResult parseTagText(String raw) {
  final lines = [
    for (final line in raw.split(RegExp(r'[\n\r]+')))
      if (line.trim().isNotEmpty) line.trim(),
  ];
  String? brand;
  String? fabric;
  String? sizeLabel;
  final measurements = <String, String>{};

  for (final line in lines) {
    final brandHit = _labeled.firstMatch(line);
    if (brandHit != null) {
      brand ??= _cleanBrand(brandHit.group(2)!);
    }
    final fabricHit = _fabricLabeled.firstMatch(line);
    if (fabricHit != null) {
      fabric ??= _clean(fabricHit.group(2)!);
    }
    final sizeHit = _sizeLabeled.firstMatch(line);
    if (sizeHit != null) {
      sizeLabel ??= sizeHit.group(2)!.replaceAll(' ', '');
    }
    for (final m in _measure.allMatches(line)) {
      measurements.putIfAbsent(m.group(1)!, () => m.group(2)!);
    }
  }

  fabric ??= _joinFibers(lines);
  sizeLabel ??=
      _firstMatch(lines, _codeSize) ?? _firstMatch(lines, _letterSize);
  brand ??= _guessBrand(lines);

  return TagOcrResult(
    lines: lines,
    brand: brand,
    fabric: fabric,
    sizeLabel: sizeLabel,
    measurements: measurements,
  );
}

String? _joinFibers(List<String> lines) {
  final found = <String>[];
  for (final line in lines) {
    for (final m in _fiber.allMatches(line)) {
      final piece = _clean(m.group(1)!);
      if (piece.isNotEmpty && !found.contains(piece)) found.add(piece);
    }
  }
  if (found.isEmpty) return null;
  return found.join('，');
}

String? _guessBrand(List<String> lines) {
  for (final line in lines) {
    final latin = RegExp(r'\b([A-Z][A-Z0-9&\-]{1,19})\b').firstMatch(line);
    if (latin == null) continue;
    final word = latin.group(1)!;
    if (_skipBrand.contains(word)) continue;
    if (RegExp(r'^\d+$').hasMatch(word)) continue;
    return word;
  }
  return null;
}

String? _firstMatch(List<String> lines, RegExp pattern) {
  for (final line in lines) {
    final m = pattern.firstMatch(line);
    if (m != null) return m.group(1)!.replaceAll(' ', '');
  }
  return null;
}

String _clean(String raw) {
  return raw.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String? _cleanBrand(String raw) {
  final cleaned = _clean(raw);
  return cleaned.isEmpty ? null : cleaned;
}

/// PP-OCRv4 rec is blank + dict + space (6625 classes for ppocr_keys_v1).
int ocrCtcClassCount(int logitCount, int keyCount) {
  final withSpace = keyCount + 2;
  final without = keyCount + 1;
  if (logitCount > 0 && logitCount % withSpace == 0) return withSpace;
  if (logitCount > 0 && logitCount % without == 0) return without;
  return withSpace;
}

String ocrCtcDecode(
  List<double> logits,
  List<String> keys, {
  double minConfidence = 0,
}) {
  if (logits.isEmpty || keys.isEmpty) return '';
  final classes = ocrCtcClassCount(logits.length, keys.length);
  final steps = logits.length ~/ classes;
  if (steps <= 0) return '';
  final buf = StringBuffer();
  var prev = -1;
  var confSum = 0.0;
  var confN = 0;
  for (var t = 0; t < steps; t++) {
    var best = 0;
    var bestV = logits[t * classes];
    for (var c = 1; c < classes; c++) {
      final v = logits[t * classes + c];
      if (v > bestV) {
        bestV = v;
        best = c;
      }
    }
    if (best != 0 && best != prev) {
      confSum += bestV;
      confN++;
    }
    if (best == 0 || best == prev) {
      prev = best;
      continue;
    }
    prev = best;
    final i = best - 1;
    if (i >= 0 && i < keys.length) {
      buf.write(keys[i]);
    } else if (i == keys.length) {
      buf.write(' ');
    }
  }
  final text = buf.toString().trim();
  if (text.isEmpty) return '';
  // Rec already outputs probabilities in [0, 1]; logits are > 1 and must not be filtered.
  if (minConfidence > 0 && confN > 0) {
    final mean = confSum / confN;
    if (mean <= 1.0001 && mean < minConfidence) return '';
  }
  return text;
}

class TagOcr {
  static const detAsset = 'assets/models/ppocr_v4_det.onnx';
  static const recAsset = 'assets/models/ppocr_v4_rec.onnx';
  static const keysAsset = 'assets/models/ppocr_keys_v1.txt';

  final _det = OnnxSession('ocr_det');
  final _rec = OnnxSession('ocr_rec');
  bool _loaded = false;
  List<String> _keys = const [];
  String _detIn = 'x';
  String _detOut = 'fetch_name_0';
  String _recIn = 'x';
  String _recOut = 'fetch_name_0';

  Future<void> ensureLoaded() async {
    if (_loaded) return;
    if (!Platform.isWindows) {
      throw const FormatException('吊牌识别目前只支持 Windows');
    }
    final det = await materializeAssetModel(
      assetPath: detAsset,
      fileName: 'ppocr_v4_det.onnx',
      minBytes: 1000000,
    );
    final rec = await materializeAssetModel(
      assetPath: recAsset,
      fileName: 'ppocr_v4_rec.onnx',
      minBytes: 1000000,
    );
    final keysFile = await materializeAssetModel(
      assetPath: keysAsset,
      fileName: 'ppocr_keys_v1.txt',
      minBytes: 1000,
    );
    _keys = [
      for (final line in await keysFile.readAsLines())
        if (line.isNotEmpty) line,
    ];
    _det.load(det.path);
    _rec.load(rec.path);
    final detIo = _det.io;
    final recIo = _rec.io;
    if (detIo.inputs.isNotEmpty) _detIn = detIo.inputs.first;
    if (detIo.outputs.isNotEmpty) _detOut = detIo.outputs.first;
    if (recIo.inputs.isNotEmpty) _recIn = recIo.inputs.first;
    if (recIo.outputs.isNotEmpty) _recOut = recIo.outputs.first;
    _loaded = true;
  }

  void dispose() {
    if (!_loaded) return;
    _det.close();
    _rec.close();
    _loaded = false;
  }

  Future<TagOcrResult> recognize(img.Image source) async {
    await ensureLoaded();
    final rgb = _opaqueRgb(source);
    final boxes = await _detect(rgb);
    sortOcrBoxes(boxes);
    final lines = <String>[];
    if (boxes.isEmpty) {
      final line = await _recognize(_uprightLine(rgb));
      if (line.trim().isNotEmpty) lines.add(line.trim());
    } else {
      double? lastCy;
      var lastH = 8.0;
      for (final box in boxes) {
        final crop = _crop(rgb, box);
        if (crop.width < 4 || crop.height < 4) continue;
        final text = (await _recognize(_uprightLine(crop))).trim();
        if (text.isEmpty) continue;
        final cy = box.y + box.height / 2.0;
        if (lastCy != null &&
            lines.isNotEmpty &&
            (cy - lastCy).abs() < math.max(8, lastH * 0.6)) {
          lines[lines.length - 1] = '${lines.last} $text';
        } else {
          lines.add(text);
        }
        lastCy = cy;
        lastH = box.height.toDouble();
      }
    }
    return parseTagText(lines.join('\n'));
  }

  Future<List<PixelRect>> _detect(img.Image rgb) async {
    const limit = 960;
    final longest = math.max(rgb.width, rgb.height);
    final scale = longest > limit ? limit / longest : 1.0;
    var dw = math.max(32, (rgb.width * scale / 32).round() * 32);
    var dh = math.max(32, (rgb.height * scale / 32).round() * 32);
    dw = dw.clamp(32, 1280);
    dh = dh.clamp(32, 1280);
    final resized = img.copyResize(
      rgb,
      width: dw,
      height: dh,
      interpolation: img.Interpolation.linear,
    );
    final values = _nchw(
      resized,
      mean: const [0.5, 0.5, 0.5],
      std: const [0.5, 0.5, 0.5],
      bgr: true,
    );
    final out = _det.run(
      inputs: [
        OnnxTensor(_detIn, [1, 3, dh, dw], values),
      ],
      outputNames: [_detOut],
      outputCounts: [dw * dh * 2],
    );
    if (out.isEmpty || out.first.values.isEmpty) return const [];
    final map = out.first.values;
    final spatial = dw * dh;
    final offset = map.length >= spatial * 2 ? spatial : 0;
    final boxes = _boxesFromMap(map, dh, dw, offset: offset);
    final invX = rgb.width / dw;
    final invY = rgb.height / dh;
    final mapped = [
      for (final box in boxes)
        PixelRect(
          x: (box.x * invX).round().clamp(0, rgb.width - 1),
          y: (box.y * invY).round().clamp(0, rgb.height - 1),
          width: math.max(1, (box.width * invX).round()),
          height: math.max(1, (box.height * invY).round()),
        ),
    ];
    sortOcrBoxes(mapped);
    return mapped;
  }

  Future<String> _recognize(img.Image crop) async {
    const recH = 48;
    const maxW = 640;
    final srcW = math.max(1, crop.width);
    final srcH = math.max(1, crop.height);
    final resizedW = math.min(maxW, math.max(8, (srcW * recH / srcH).ceil()));
    final width = math.min(maxW, math.max(8, ((resizedW + 7) ~/ 8) * 8));
    final resized = img.copyResize(
      crop,
      width: resizedW,
      height: recH,
      interpolation: img.Interpolation.linear,
    );
    final canvas = img.Image(width: width, height: recH, numChannels: 3);
    img.fill(canvas, color: img.ColorRgb8(0, 0, 0));
    img.compositeImage(canvas, resized, dstX: 0, dstY: 0);
    final values = _nchw(
      canvas,
      mean: const [0.5, 0.5, 0.5],
      std: const [0.5, 0.5, 0.5],
      bgr: true,
    );
    final classes = _keys.length + 2;
    final maxT = math.max(160, (width ~/ 8) + 16);
    final out = _rec.run(
      inputs: [
        OnnxTensor(_recIn, [1, 3, recH, width], values),
      ],
      outputNames: [_recOut],
      outputCounts: [maxT * math.max(classes, 8)],
    );
    if (out.isEmpty) return '';
    return ocrCtcDecode(out.first.values, _keys, minConfidence: 0.25);
  }
}

img.Image _opaqueRgb(img.Image source) {
  if (source.numChannels == 3) return source;
  final out = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 3,
  );
  img.fill(out, color: img.ColorRgb8(255, 255, 255));
  img.compositeImage(out, source);
  return out;
}

img.Image _uprightLine(img.Image crop) {
  if (crop.height >= crop.width * 1.5) {
    return img.copyRotate(crop, angle: -90);
  }
  return crop;
}

List<double> _nchw(
  img.Image rgb, {
  required List<double> mean,
  required List<double> std,
  bool bgr = false,
}) {
  final w = rgb.width;
  final h = rgb.height;
  final out = List<double>.filled(3 * w * h, 0);
  final plane = w * h;
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = rgb.getPixel(x, y);
      final i = y * w + x;
      final r = p.r / 255.0;
      final g = p.g / 255.0;
      final b = p.b / 255.0;
      final c0 = bgr ? b : r;
      final c2 = bgr ? r : b;
      out[i] = (c0 - mean[0]) / std[0];
      out[plane + i] = (g - mean[1]) / std[1];
      out[plane * 2 + i] = (c2 - mean[2]) / std[2];
    }
  }
  return out;
}

img.Image _crop(img.Image rgb, PixelRect box) {
  final x = box.x.clamp(0, rgb.width - 1);
  final y = box.y.clamp(0, rgb.height - 1);
  final w = math.min(box.width, rgb.width - x);
  final h = math.min(box.height, rgb.height - y);
  return img.copyCrop(
    rgb,
    x: x,
    y: y,
    width: math.max(1, w),
    height: math.max(1, h),
  );
}

List<PixelRect> _boxesFromMap(
  List<double> map,
  int height,
  int width, {
  int offset = 0,
}) {
  final on = List<bool>.filled(width * height, false);
  for (var i = 0; i < width * height && offset + i < map.length; i++) {
    on[i] = map[offset + i] > 0.3;
  }
  final seen = List<bool>.filled(width * height, false);
  final boxes = <PixelRect>[];
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final start = y * width + x;
      if (!on[start] || seen[start]) continue;
      var x0 = x;
      var y0 = y;
      var x1 = x;
      var y1 = y;
      var area = 0;
      final queue = [start];
      seen[start] = true;
      for (var q = 0; q < queue.length; q++) {
        final i = queue[q];
        final cx = i % width;
        final cy = i ~/ width;
        area++;
        if (cx < x0) x0 = cx;
        if (cy < y0) y0 = cy;
        if (cx > x1) x1 = cx;
        if (cy > y1) y1 = cy;
        const nx = [-1, 1, 0, 0];
        const ny = [0, 0, -1, 1];
        for (var k = 0; k < 4; k++) {
          final px = cx + nx[k];
          final py = cy + ny[k];
          if (px < 0 || py < 0 || px >= width || py >= height) continue;
          final ni = py * width + px;
          if (seen[ni] || !on[ni]) continue;
          seen[ni] = true;
          queue.add(ni);
        }
      }
      if (area < 24 || (x1 - x0) < 6 || (y1 - y0) < 5) continue;
      final padX = math.max(2, ((x1 - x0 + 1) * 0.12).round());
      final padY = math.max(2, ((y1 - y0 + 1) * 0.22).round());
      boxes.add(
        PixelRect(
          x: math.max(0, x0 - padX),
          y: math.max(0, y0 - padY),
          width: math.min(width, x1 + padX + 1) - math.max(0, x0 - padX),
          height: math.min(height, y1 + padY + 1) - math.max(0, y0 - padY),
        ),
      );
    }
  }
  boxes.sort(ocrBoxReadingOrder);
  return boxes;
}

int ocrBoxReadingOrder(PixelRect a, PixelRect b) {
  final ay = a.y + a.height / 2;
  final by = b.y + b.height / 2;
  final lineH = math.max(8, math.min(a.height, b.height) * 0.6);
  final dy = ay - by;
  if (dy.abs() > lineH) return dy < 0 ? -1 : 1;
  return a.x.compareTo(b.x);
}

void sortOcrBoxes(List<PixelRect> boxes) {
  boxes.sort(ocrBoxReadingOrder);
}
