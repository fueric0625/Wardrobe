import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/widgets/common.dart';
import 'package:wardrobe/widgets/piece_collage.dart';

/// Drag a cutout by its opaque pixels. The wheel scales the piece under the cursor.
class OutfitCollageBoard extends StatefulWidget {
  const OutfitCollageBoard({
    super.key,
    required this.placements,
    required this.paths,
    required this.onChanged,
  });

  final List<CollagePlacement> placements;
  final Map<String, String> paths;
  final ValueChanged<List<CollagePlacement>> onChanged;

  @override
  State<OutfitCollageBoard> createState() => _OutfitCollageBoardState();
}

class _CutoutMask {
  const _CutoutMask(this.width, this.height, this.alpha);

  final int width;
  final int height;

  /// Null when every pixel of the contained image should count as a hit.
  final Uint8List? alpha;
}

class _OutfitCollageBoardState extends State<OutfitCollageBoard> {
  late List<CollagePlacement> _items = [...widget.placements];
  final Map<String, _CutoutMask> _masks = {};
  final Set<String> _loading = {};
  bool _dragging = false;
  String? _activeId;
  String? _hoverId;
  double _width = 1;
  double _height = 1;

  @override
  void initState() {
    super.initState();
    _ensureMasks();
  }

  @override
  void didUpdateWidget(covariant OutfitCollageBoard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging) _items = [...widget.placements];
    _ensureMasks();
  }

  List<CollagePlacement> get _visible {
    final shown = [
      for (final item in _items)
        if ((widget.paths[item.clothingItemId] ?? '').isNotEmpty) item,
    ]..sort((a, b) => a.z.compareTo(b.z));
    return shown;
  }

  void _ensureMasks() {
    for (final path in widget.paths.values) {
      if (path.isEmpty || _masks.containsKey(path) || _loading.contains(path)) {
        continue;
      }
      _loading.add(path);
      _loadMask(path);
    }
  }

  Future<void> _loadMask(String path) async {
    _CutoutMask mask;
    try {
      final bytes = await File(path).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        mask = const _CutoutMask(0, 0, null);
      } else {
        const maxSide = 320;
        var sample = decoded;
        if (decoded.width > maxSide || decoded.height > maxSide) {
          sample = decoded.width >= decoded.height
              ? img.copyResize(decoded, width: maxSide)
              : img.copyResize(decoded, height: maxSide);
        }
        Uint8List? alpha;
        if (sample.numChannels >= 4) {
          alpha = Uint8List(sample.width * sample.height);
          var anyClear = false;
          for (var y = 0; y < sample.height; y++) {
            for (var x = 0; x < sample.width; x++) {
              final value = sample.getPixel(x, y).a.toInt();
              alpha[y * sample.width + x] = value;
              if (value <= 20) anyClear = true;
            }
          }
          if (!anyClear) alpha = null;
        }
        mask = _CutoutMask(sample.width, sample.height, alpha);
      }
    } catch (_) {
      mask = const _CutoutMask(0, 0, null);
    }
    _loading.remove(path);
    if (!mounted) return;
    setState(() => _masks[path] = mask);
  }

  void _replace(CollagePlacement next) {
    setState(() {
      _items = [
        for (final item in _items)
          if (item.clothingItemId == next.clothingItemId) next else item,
      ];
    });
  }

  void _raise(String id) {
    final top = _items.fold<int>(
      0,
      (maxZ, piece) => piece.z > maxZ ? piece.z : maxZ,
    );
    final index = _items.indexWhere((piece) => piece.clothingItemId == id);
    if (index < 0 || _items[index].z == top) return;
    _items = [
      for (final piece in _items)
        if (piece.clothingItemId == id) piece.copyWith(z: top + 1) else piece,
    ];
  }

  String? _hit(Offset local) {
    if (_width <= 0 || _height <= 0) return null;
    for (final item in _visible.reversed) {
      final box = Rect.fromLTWH(
        item.x * _width,
        item.y * _height,
        item.w * _width,
        item.h * _height,
      );
      if (!box.contains(local)) continue;
      final path = widget.paths[item.clothingItemId];
      final mask = path == null ? null : _masks[path];
      if (mask == null || mask.width <= 0) continue;
      final inside = cutoutPixelHit(
        x: local.dx - box.left,
        y: local.dy - box.top,
        boxWidth: box.width,
        boxHeight: box.height,
        imageWidth: mask.width,
        imageHeight: mask.height,
        alpha: mask.alpha,
      );
      if (inside) return item.clothingItemId;
    }
    return null;
  }

  void _commit() {
    _dragging = false;
    _activeId = null;
    widget.onChanged(_items);
  }

  void _scaleUnder(Offset local, double deltaY) {
    final id = _hit(local);
    if (id == null) return;
    final current = _items.cast<CollagePlacement?>().firstWhere(
      (piece) => piece!.clothingItemId == id,
      orElse: () => null,
    );
    if (current == null) return;
    final factor = math.exp(-deltaY / 700);
    final w = (current.w * factor).clamp(0.08, 1.6).toDouble();
    final h = (current.h * factor).clamp(0.08, 1.6).toDouble();
    final cx = current.x + current.w / 2;
    final cy = current.y + current.h / 2;
    _raise(id);
    _replace(
      current.copyWith(
        x: cx - w / 2,
        y: cy - h / 2,
        w: w,
        h: h,
        z: _items.firstWhere((piece) => piece.clothingItemId == id).z,
      ),
    );
    widget.onChanged(_items);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _visible;
    final cursor = _dragging
        ? SystemMouseCursors.grabbing
        : _hoverId == null
        ? MouseCursor.defer
        : SystemMouseCursors.grab;
    return ColoredBox(
      color: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) {
          _width = constraints.maxWidth;
          _height = constraints.maxHeight;
          if (_width <= 0 || _height <= 0) return const SizedBox.shrink();
          return MouseRegion(
            cursor: cursor,
            onHover: (event) {
              if (_dragging) return;
              final id = _hit(event.localPosition);
              if (id == _hoverId) return;
              setState(() => _hoverId = id);
            },
            onExit: (_) {
              if (_hoverId == null) return;
              setState(() => _hoverId = null);
            },
            child: Listener(
              onPointerSignal: (event) {
                if (event is! PointerScrollEvent) return;
                _scaleUnder(event.localPosition, event.scrollDelta.dy);
              },
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onPanStart: (details) {
                  final id = _hit(details.localPosition);
                  if (id == null) {
                    _activeId = null;
                    return;
                  }
                  _dragging = true;
                  _activeId = id;
                  _raise(id);
                  setState(() => _hoverId = id);
                },
                onPanUpdate: (details) {
                  final id = _activeId;
                  if (id == null) return;
                  final current = _items.cast<CollagePlacement?>().firstWhere(
                    (piece) => piece!.clothingItemId == id,
                    orElse: () => null,
                  );
                  if (current == null) return;
                  final x = (current.x + details.delta.dx / _width)
                      .clamp(-current.w + 0.12, 1 - 0.12)
                      .toDouble();
                  final y = (current.y + details.delta.dy / _height)
                      .clamp(-current.h + 0.12, 1 - 0.12)
                      .toDouble();
                  _replace(current.copyWith(x: x, y: y));
                },
                onPanEnd: (_) {
                  if (_activeId == null) return;
                  _commit();
                },
                onPanCancel: () {
                  if (_activeId == null) return;
                  _commit();
                },
                child: Stack(
                  children: [
                    for (final item in shown)
                      Positioned(
                        left: item.x * _width,
                        top: item.y * _height,
                        width: item.w * _width,
                        height: item.h * _height,
                        child: IgnorePointer(
                          child: LocalCover(
                            path: widget.paths[item.clothingItemId],
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
