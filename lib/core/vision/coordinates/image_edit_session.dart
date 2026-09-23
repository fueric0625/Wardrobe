import 'package:wardrobe/core/vision/cutout/erase_brush.dart';
import 'package:wardrobe/core/vision/cutout/fill_patch.dart';
import 'package:wardrobe/core/vision/cutout/sam_click.dart';

sealed class RefineOperation {}

class ClickOperation extends RefineOperation {
  ClickOperation(this.point);

  final PromptPoint point;
}

class EraseOperation extends RefineOperation {
  EraseOperation(this.stamps);

  final List<EraseStamp> stamps;
}

class FillOperation extends RefineOperation {
  FillOperation({required this.samples, required this.paints});

  final List<EraseStamp> samples;
  final List<EraseStamp> paints;
}

/// One clothing photo's click, erase, and fill history.
class ImageEditSession {
  final points = <PromptPoint>[];
  final eraseStrokes = <EraseStroke>[];
  final fillStrokes = <FillStroke>[];
  final operations = <RefineOperation>[];

  bool get isEmpty => operations.isEmpty;

  void addClick(PromptPoint point) {
    points.add(point);
    operations.add(ClickOperation(point));
  }

  void addErase(EraseStroke stroke) {
    eraseStrokes.add(stroke);
    operations.add(EraseOperation(stroke.stamps));
  }

  void addFill(FillStroke stroke) {
    fillStrokes.add(stroke);
    operations.add(
      FillOperation(samples: stroke.sample.stamps, paints: stroke.paint),
    );
  }

  void undo() {
    if (operations.isEmpty) return;
    switch (operations.removeLast()) {
      case ClickOperation():
        if (points.isNotEmpty) points.removeLast();
      case EraseOperation():
        if (eraseStrokes.isNotEmpty) eraseStrokes.removeLast();
      case FillOperation():
        if (fillStrokes.isNotEmpty) fillStrokes.removeLast();
    }
  }

  void clear() {
    points.clear();
    eraseStrokes.clear();
    fillStrokes.clear();
    operations.clear();
  }
}
