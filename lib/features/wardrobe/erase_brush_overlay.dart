import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wardrobe/core/vision/cutout/contain_map.dart';
import 'package:wardrobe/core/vision/cutout/erase_brush.dart';

class EraseBrushOverlay extends StatefulWidget {
  const EraseBrushOverlay({
    super.key,
    required this.imageWidth,
    required this.imageHeight,
    required this.radius,
    required this.onStroke,
    this.accent = const Color(0xFFE25555),
  });

  final int imageWidth;
  final int imageHeight;
  final int radius;
  final ValueChanged<List<EraseStamp>> onStroke;
  final Color accent;

  @override
  State<EraseBrushOverlay> createState() => _EraseBrushOverlayState();
}

class _EraseBrushOverlayState extends State<EraseBrushOverlay> {
  final _stamps = <EraseStamp>[];
  Offset? _cursor;
  ({int x, int y})? _lastPixel;

  bool get _spaceHeld =>
      HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.space);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = ContainLayout.of(
          boxWidth: constraints.maxWidth,
          boxHeight: constraints.maxHeight,
          imageWidth: widget.imageWidth,
          imageHeight: widget.imageHeight,
        );
        final localRadius = _localRadius(layout);
        return ExcludeSemantics(
          child: MouseRegion(
          cursor: SystemMouseCursors.none,
          onHover: (event) {
            if (_spaceHeld) return;
            setState(() => _cursor = event.localPosition);
          },
          onExit: (_) => setState(() => _cursor = null),
          child: GestureDetector(
            onSecondaryTap: () {},
            behavior: HitTestBehavior.translucent,
            child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              if (_spaceHeld) return;
              if (event.kind == PointerDeviceKind.mouse &&
                  event.buttons != kPrimaryMouseButton) {
                return;
              }
              _stamps.clear();
              _lastPixel = null;
              _paintAt(layout, event.localPosition);
            },
            onPointerMove: (event) {
              setState(() => _cursor = event.localPosition);
              if (_spaceHeld) return;
              if (_lastPixel == null) return;
              if (event.kind == PointerDeviceKind.mouse &&
                  (event.buttons & kPrimaryMouseButton) == 0) {
                return;
              }
              _paintAt(layout, event.localPosition);
            },
            onPointerUp: (_) => _commit(),
            onPointerCancel: (_) {
              _stamps.clear();
              _lastPixel = null;
              setState(() {});
            },
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _EraseBrushPainter(
                layout: layout,
                imageWidth: widget.imageWidth,
                imageHeight: widget.imageHeight,
                stamps: List<EraseStamp>.of(_stamps),
                cursor: _cursor,
                localRadius: localRadius,
                accent: widget.accent,
              ),
            ),
          ),
          ),
        ),
        );
      },
    );
  }

  double _localRadius(ContainLayout layout) {
    if (layout.drawWidth <= 0 || widget.imageWidth <= 0) return 8;
    return widget.radius / widget.imageWidth * layout.drawWidth;
  }

  ({int x, int y})? _pixelOf(ContainLayout layout, Offset local) {
    if (!layout.contains(local.dx, local.dy)) return null;
    final pixel = layout.localToPixel(
      local.dx,
      local.dy,
      imageWidth: widget.imageWidth,
      imageHeight: widget.imageHeight,
    );
    if (pixel == null) return null;
    final maxX = widget.imageWidth <= 0 ? 0 : widget.imageWidth - 1;
    final maxY = widget.imageHeight <= 0 ? 0 : widget.imageHeight - 1;
    return (x: pixel.x.clamp(0, maxX), y: pixel.y.clamp(0, maxY));
  }

  void _paintAt(ContainLayout layout, Offset local) {
    final pixel = _pixelOf(layout, local);
    if (pixel == null) return;
    final from = _lastPixel;
    _lastPixel = pixel;
    if (from == null) {
      _stamps.add(EraseStamp(x: pixel.x, y: pixel.y, radius: widget.radius));
      setState(() => _cursor = local);
      return;
    }
    final dx = pixel.x - from.x;
    final dy = pixel.y - from.y;
    final dist = dx.abs() > dy.abs() ? dx.abs() : dy.abs();
    final step = widget.radius < 2 ? 1 : (widget.radius * 0.4).clamp(1, 8).round();
    final n = dist <= 0 ? 1 : (dist / step).ceil();
    for (var i = 1; i <= n; i++) {
      final t = i / n;
      _stamps.add(
        EraseStamp(
          x: (from.x + dx * t).round(),
          y: (from.y + dy * t).round(),
          radius: widget.radius,
        ),
      );
    }
    setState(() => _cursor = local);
  }

  void _commit() {
    final stamps = List<EraseStamp>.of(_stamps);
    _stamps.clear();
    _lastPixel = null;
    setState(() {});
    if (stamps.isEmpty) return;
    widget.onStroke(stamps);
  }
}

class _EraseBrushPainter extends CustomPainter {
  _EraseBrushPainter({
    required this.layout,
    required this.imageWidth,
    required this.imageHeight,
    required this.stamps,
    required this.cursor,
    required this.localRadius,
    required this.accent,
  });

  final ContainLayout layout;
  final int imageWidth;
  final int imageHeight;
  final List<EraseStamp> stamps;
  final Offset? cursor;
  final double localRadius;
  final Color accent;

  Offset _toLocal(int x, int y) {
    return Offset(
      layout.offsetX + x / imageWidth * layout.drawWidth,
      layout.offsetY + y / imageHeight * layout.drawHeight,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.drawWidth <= 0 || layout.drawHeight <= 0 || imageWidth <= 0 || imageHeight <= 0) {
      return;
    }
    final imageRect = Rect.fromLTWH(
      layout.offsetX,
      layout.offsetY,
      layout.drawWidth,
      layout.drawHeight,
    );
    canvas.drawRect(
      imageRect.deflate(0.5),
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final stroke = Paint()
      ..color = accent.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    for (final stamp in stamps) {
      canvas.drawCircle(_toLocal(stamp.x, stamp.y), localRadius, stroke);
    }
    final hover = cursor;
    if (hover != null && layout.contains(hover.dx, hover.dy)) {
      canvas.drawCircle(
        hover,
        localRadius,
        Paint()
          ..color = accent.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        hover,
        localRadius,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EraseBrushPainter oldDelegate) {
    return oldDelegate.cursor != cursor ||
        oldDelegate.localRadius != localRadius ||
        oldDelegate.stamps.length != stamps.length ||
        oldDelegate.accent != accent ||
        oldDelegate.layout.drawWidth != layout.drawWidth;
  }
}
