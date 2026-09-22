import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wardrobe/core/theme.dart';
import 'package:wardrobe/core/vision/cutout/contain_map.dart';
import 'package:wardrobe/core/vision/cutout/sam_click.dart';

class ClickPromptOverlay extends StatefulWidget {
  const ClickPromptOverlay({
    super.key,
    required this.imageWidth,
    required this.imageHeight,
    required this.points,
    required this.onAdd,
  });

  final int imageWidth;
  final int imageHeight;
  final List<PromptPoint> points;
  final ValueChanged<PromptPoint> onAdd;

  @override
  State<ClickPromptOverlay> createState() => _ClickPromptOverlayState();
}

class _ClickPromptOverlayState extends State<ClickPromptOverlay> {
  Offset? _down;
  int _button = 0;

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
        return ExcludeSemantics(
          child: GestureDetector(
          onSecondaryTap: () {},
          behavior: HitTestBehavior.translucent,
          child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (event) {
            if (_spaceHeld) return;
            if (event.kind == PointerDeviceKind.mouse &&
                event.buttons != kPrimaryMouseButton &&
                event.buttons != kSecondaryMouseButton) {
              return;
            }
            _down = event.localPosition;
            _button = event.buttons;
          },
          onPointerUp: (event) {
            final from = _down;
            _down = null;
            if (from == null || _spaceHeld) return;
            if ((event.localPosition - from).distance > 8) return;
            if (!layout.contains(event.localPosition.dx, event.localPosition.dy)) {
              return;
            }
            final pixel = layout.localToPixel(
              event.localPosition.dx,
              event.localPosition.dy,
              imageWidth: widget.imageWidth,
              imageHeight: widget.imageHeight,
            );
            if (pixel == null) return;
            final maxX = widget.imageWidth <= 0 ? 0 : widget.imageWidth - 1;
            final maxY = widget.imageHeight <= 0 ? 0 : widget.imageHeight - 1;
            widget.onAdd(
              PromptPoint(
                x: pixel.x.clamp(0, maxX),
                y: pixel.y.clamp(0, maxY),
                positive: _button != kSecondaryMouseButton,
              ),
            );
          },
          onPointerCancel: (_) => _down = null,
          child: CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _ClickPromptPainter(
              layout: layout,
              imageWidth: widget.imageWidth,
              imageHeight: widget.imageHeight,
              points: List<PromptPoint>.of(widget.points),
            ),
          ),
        ),
        ),
        );
      },
    );
  }
}

class _ClickPromptPainter extends CustomPainter {
  _ClickPromptPainter({
    required this.layout,
    required this.imageWidth,
    required this.imageHeight,
    required this.points,
  });

  final ContainLayout layout;
  final int imageWidth;
  final int imageHeight;
  final List<PromptPoint> points;

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
    final hint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawRect(imageRect.deflate(0.5), hint);
    for (final point in points) {
      final local = Offset(
        layout.offsetX + point.x / imageWidth * layout.drawWidth,
        layout.offsetY + point.y / imageHeight * layout.drawHeight,
      );
      final color = point.positive ? AppColors.primary : const Color(0xFFE25555);
      canvas.drawCircle(local, 7, Paint()..color = color);
      canvas.drawCircle(
        local,
        7,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final tick = Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      if (point.positive) {
        canvas.drawLine(local.translate(0, -4), local.translate(0, 4), tick);
        canvas.drawLine(local.translate(-4, 0), local.translate(4, 0), tick);
      } else {
        canvas.drawLine(local.translate(-3.5, -3.5), local.translate(3.5, 3.5), tick);
        canvas.drawLine(local.translate(3.5, -3.5), local.translate(-3.5, 3.5), tick);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ClickPromptPainter oldDelegate) {
    return !listEquals(oldDelegate.points, points) ||
        oldDelegate.layout.drawWidth != layout.drawWidth ||
        oldDelegate.layout.drawHeight != layout.drawHeight ||
        oldDelegate.imageWidth != imageWidth ||
        oldDelegate.imageHeight != imageHeight;
  }
}
