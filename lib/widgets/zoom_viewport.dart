import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wardrobe/core/theme.dart';

class ZoomViewport extends StatefulWidget {
  const ZoomViewport({
    super.key,
    required this.child,
    this.resetKey,
    this.panWithSecondary = true,
  });

  final Widget child;
  final Object? resetKey;
  final bool panWithSecondary;

  @override
  State<ZoomViewport> createState() => _ZoomViewportState();
}

class _ZoomViewportState extends State<ZoomViewport> {
  static const _min = 1.0;
  static const _max = 8.0;

  double _scale = 1;
  Offset _offset = Offset.zero;
  Offset? _panFrom;
  Offset _panOrigin = Offset.zero;

  @override
  void didUpdateWidget(covariant ZoomViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey) {
      _scale = 1;
      _offset = Offset.zero;
    }
  }

  void _zoomAt(Offset focal, double next, Size size) {
    next = next.clamp(_min, _max);
    final content = Offset(
      (focal.dx - _offset.dx) / _scale,
      (focal.dy - _offset.dy) / _scale,
    );
    final offset = next <= _min + 0.001
        ? Offset.zero
        : _clampOffset(
            Offset(focal.dx - content.dx * next, focal.dy - content.dy * next),
            size,
            next,
          );
    setState(() {
      _scale = next;
      _offset = offset;
    });
  }

  Offset _clampOffset(Offset offset, Size size, double scale) {
    final extraX = size.width * (scale - 1);
    final extraY = size.height * (scale - 1);
    return Offset(
      extraX <= 0 ? 0 : offset.dx.clamp(-extraX, 0),
      extraY <= 0 ? 0 : offset.dy.clamp(-extraY, 0),
    );
  }

  bool _isPanButton(int buttons) {
    if ((buttons & kMiddleMouseButton) != 0) return true;
    if (_spaceHeld && (buttons & kPrimaryMouseButton) != 0) return true;
    return widget.panWithSecondary && (buttons & kSecondaryMouseButton) != 0;
  }

  bool get _spaceHeld =>
      HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.space);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              onPointerSignal: (event) {
                if (event is! PointerScrollEvent) return;
                final factor = event.scrollDelta.dy > 0 ? 1 / 1.18 : 1.18;
                _zoomAt(event.localPosition, _scale * factor, size);
              },
              onPointerDown: (event) {
                if (!_isPanButton(event.buttons) || _scale <= 1) return;
                _panFrom = event.localPosition;
                _panOrigin = _offset;
              },
              onPointerMove: (event) {
                final from = _panFrom;
                if (from == null) return;
                setState(() {
                  _offset = _clampOffset(
                    _panOrigin + (event.localPosition - from),
                    size,
                    _scale,
                  );
                });
              },
              onPointerUp: (_) => _panFrom = null,
              onPointerCancel: (_) => _panFrom = null,
              child: ClipRect(
                child: Transform(
                  transform: Matrix4.identity()
                    ..translateByDouble(_offset.dx, _offset.dy, 0, 1)
                    ..scaleByDouble(_scale, _scale, 1, 1),
                  alignment: Alignment.topLeft,
                  child: widget.child,
                ),
              ),
            ),
            Positioned(
              right: 10,
              top: 10,
              child: ExcludeSemantics(
                child: Material(
                color: const Color(0xEEFFFFFF),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: '缩小',
                      onPressed: _scale <= _min
                          ? null
                          : () => _zoomAt(
                                Offset(size.width / 2, size.height / 2),
                                _scale / 1.25,
                                size,
                              ),
                      icon: const Icon(Icons.remove, size: 18),
                    ),
                    Text(
                      '${(_scale * 100).round()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: '放大',
                      onPressed: _scale >= _max
                          ? null
                          : () => _zoomAt(
                                Offset(size.width / 2, size.height / 2),
                                _scale * 1.25,
                                size,
                              ),
                      icon: const Icon(Icons.add, size: 18),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: '适配',
                      onPressed: _scale == 1
                          ? null
                          : () => setState(() {
                                _scale = 1;
                                _offset = Offset.zero;
                              }),
                      icon: const Icon(Icons.fit_screen, size: 18),
                    ),
                  ],
                ),
              ),
              ),
            ),
          ],
        );
      },
    );
  }
}
