import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wardrobe/core/design_system/theme.dart';
import 'package:wardrobe/core/vision/coordinates/image_coordinate_mapper.dart';
import 'package:wardrobe/core/vision/cutout/contain_map.dart';
import 'package:wardrobe/core/vision/cutout/image_ops.dart';

class FillBoxOverlay extends StatefulWidget {
  const FillBoxOverlay({
    super.key,
    required this.imageWidth,
    required this.imageHeight,
    required this.onBox,
  });

  final int imageWidth;
  final int imageHeight;
  final ValueChanged<PixelRect> onBox;

  @override
  State<FillBoxOverlay> createState() => _FillBoxOverlayState();
}

class _FillBoxOverlayState extends State<FillBoxOverlay> {
  Offset? _from;
  Offset? _to;

  bool get _spaceHeld => HardwareKeyboard.instance.logicalKeysPressed.contains(
    LogicalKeyboardKey.space,
  );

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
        return ExcludeSemantics(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) {
              if (_spaceHeld) return;
              if (event.kind == PointerDeviceKind.mouse &&
                  event.buttons != kPrimaryMouseButton) {
                return;
              }
              setState(() {
                _from = event.localPosition;
                _to = event.localPosition;
              });
            },
            onPointerMove: (event) {
              if (_from == null || _spaceHeld) return;
              setState(() => _to = event.localPosition);
            },
            onPointerUp: (_) => _commit(layout),
            onPointerCancel: (_) => setState(() {
              _from = null;
              _to = null;
            }),
            child: CustomPaint(
              size: Size(constraints.maxWidth, constraints.maxHeight),
              painter: _FillBoxPainter(
                layout: layout,
                from: _from,
                to: _to,
                color: AppPalette.of(context).primary,
              ),
            ),
          ),
        );
      },
    );
  }

  void _commit(ContainLayout layout) {
    final a = _from;
    final b = _to;
    _from = null;
    _to = null;
    setState(() {});
    if (a == null || b == null || _spaceHeld) return;
    final rect = _pixelBox(layout, a, b);
    if (rect == null) return;
    widget.onBox(rect);
  }

  PixelRect? _pixelBox(ContainLayout layout, Offset a, Offset b) {
    final mapper = ImageCoordinateMapper.fromLayout(
      imageWidth: widget.imageWidth,
      imageHeight: widget.imageHeight,
      layout: layout,
    );
    final dragged = mapper.toImageRect(
      ViewportPoint.fromOffset(a),
      ViewportPoint.fromOffset(b),
    );
    if (dragged != null && dragged.width >= 2 && dragged.height >= 2) {
      return dragged.toPixelRect();
    }
    final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final pixel = layout.localToPixel(
      mid.dx,
      mid.dy,
      imageWidth: widget.imageWidth,
      imageHeight: widget.imageHeight,
    );
    if (pixel == null) return null;
    return clampPixelRect(
      PixelRect(x: pixel.x - 24, y: pixel.y - 24, width: 48, height: 48),
      widget.imageWidth,
      widget.imageHeight,
      minSize: 8,
    );
  }
}

class _FillBoxPainter extends CustomPainter {
  _FillBoxPainter({
    required this.layout,
    required this.from,
    required this.to,
    required this.color,
  });

  final ContainLayout layout;
  final Offset? from;
  final Offset? to;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (layout.drawWidth <= 0 || layout.drawHeight <= 0) return;
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
    final a = from;
    final b = to;
    if (a == null || b == null) return;
    final rect = Rect.fromPoints(a, b);
    canvas.drawRect(
      rect,
      Paint()
        ..color = color.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill,
    );
    canvas.drawRect(
      rect,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _FillBoxPainter oldDelegate) {
    return oldDelegate.from != from ||
        oldDelegate.to != to ||
        oldDelegate.color != color ||
        oldDelegate.layout.drawWidth != layout.drawWidth;
  }
}
