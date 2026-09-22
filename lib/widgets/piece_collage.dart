import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:wardrobe/core/theme.dart';
import 'package:wardrobe/widgets/common.dart';

const outfitCoverPhoto = 'photo';
const outfitCoverCollage = 'collage';

/// Saved when the user removes the collage. Distinct from a missing layout.
const collageRemovedLayout = '';

bool isCollageRemoved(String? layout) => layout == collageRemovedLayout;

/// Width / height of every collage canvas, so a layout looks the same everywhere.
const collageCoverAspect = 3 / 4;

/// Centers [child] in a [collageCoverAspect] box inside the available space.
class CollageCoverBox extends StatelessWidget {
  const CollageCoverBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;
        if (maxWidth <= 0 || maxHeight <= 0) return const SizedBox.shrink();
        var width = maxWidth;
        var height = width / collageCoverAspect;
        if (height > maxHeight) {
          height = maxHeight;
          width = height * collageCoverAspect;
        }
        return Center(
          child: SizedBox(width: width, height: height, child: child),
        );
      },
    );
  }
}

class CollagePlacement {
  const CollagePlacement({
    required this.clothingItemId,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.z,
  });

  final String clothingItemId;
  final double x;
  final double y;
  final double w;
  final double h;
  final int z;

  CollagePlacement copyWith({double? x, double? y, double? w, double? h, int? z}) {
    return CollagePlacement(
      clothingItemId: clothingItemId,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      z: z ?? this.z,
    );
  }

  Map<String, Object> toJson() => {
        'id': clothingItemId,
        'x': x,
        'y': y,
        'w': w,
        'h': h,
        'z': z,
      };
}

class CollagePiece {
  const CollagePiece({required this.path, required this.placement});

  final String path;
  final CollagePlacement placement;
}

List<CollagePlacement> decodeCollageLayout(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const [];
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    final placements = <CollagePlacement>[];
    for (final entry in decoded) {
      if (entry is! Map) continue;
      final id = entry['id'];
      if (id is! String || id.isEmpty) continue;
      placements.add(
        CollagePlacement(
          clothingItemId: id,
          x: _num(entry['x']),
          y: _num(entry['y']),
          w: _num(entry['w'], fallback: 0.4).clamp(0.12, 1),
          h: _num(entry['h'], fallback: 0.4).clamp(0.12, 1),
          z: (entry['z'] as num?)?.round() ?? placements.length,
        ),
      );
    }
    return placements;
  } catch (_) {
    return const [];
  }
}

String? encodeCollageLayout(List<CollagePlacement> placements) {
  if (placements.isEmpty) return null;
  return jsonEncode([for (final placement in placements) placement.toJson()]);
}

double _num(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return fallback;
}

/// Starting grid. Two columns until the fifth piece, then three.
List<CollagePlacement> autoPlacements(List<String> ids) {
  if (ids.isEmpty) return const [];
  final cols = ids.length == 1 ? 1 : (ids.length <= 4 ? 2 : 3);
  final rows = (ids.length / cols).ceil();
  return [
    for (var i = 0; i < ids.length; i++)
      CollagePlacement(
        clothingItemId: ids[i],
        x: (i % cols) / cols,
        y: (i ~/ cols) / rows,
        w: 1 / cols,
        h: 1 / rows,
        z: i,
      ),
  ];
}

/// Keeps a saved arrangement and drops clothes that are no longer linked.
/// Clothes without a saved spot get a small overlapping start position.
List<CollagePlacement> mergeCollageLayout(
  List<CollagePlacement> saved,
  List<String> ids,
) {
  if (ids.isEmpty) return const [];
  final kept = [
    for (final placement in saved)
      if (ids.contains(placement.clothingItemId)) placement,
  ];
  if (kept.isEmpty) return autoPlacements(ids);
  final have = {for (final placement in kept) placement.clothingItemId};
  final missing = [for (final id in ids) if (!have.contains(id)) id];
  var z = kept.fold<int>(0, (maxZ, placement) => math.max(maxZ, placement.z));
  return [
    ...kept,
    for (var i = 0; i < missing.length; i++)
      CollagePlacement(
        clothingItemId: missing[i],
        x: 0.08 + (i % 3) * 0.05,
        y: 0.08 + (i % 3) * 0.05,
        w: 0.42,
        h: 0.42,
        z: ++z,
      ),
  ];
}

/// Click-cutout when one exists, otherwise the item's cover image.
String? preferCutoutPath({
  required String? imagePath,
  required Iterable<({String role, bool isPrimary, String? processedPath})> images,
}) {
  String? fallback;
  for (final image in images) {
    if (image.role == 'tag') continue;
    final processed = image.processedPath;
    if (processed == null || processed.isEmpty) continue;
    if (image.isPrimary) return processed;
    fallback ??= processed;
  }
  if (fallback != null) return fallback;
  if (imagePath != null && imagePath.isNotEmpty) return imagePath;
  return null;
}

/// Whether [x], [y] inside a piece box lands on the contained image.
/// [alpha] is row-major and matches [imageWidth] by [imageHeight]. Null means
/// the whole contained image is opaque, such as a photo without a cutout.
bool cutoutPixelHit({
  required double x,
  required double y,
  required double boxWidth,
  required double boxHeight,
  required int imageWidth,
  required int imageHeight,
  Uint8List? alpha,
  int alphaThreshold = 20,
}) {
  if (boxWidth <= 0 || boxHeight <= 0 || imageWidth <= 0 || imageHeight <= 0) {
    return false;
  }
  final scale = math.min(boxWidth / imageWidth, boxHeight / imageHeight);
  final drawWidth = imageWidth * scale;
  final drawHeight = imageHeight * scale;
  final left = (boxWidth - drawWidth) / 2;
  final top = (boxHeight - drawHeight) / 2;
  if (x < left || y < top || x > left + drawWidth || y > top + drawHeight) {
    return false;
  }
  if (alpha == null) return true;
  final px = ((x - left) / drawWidth * imageWidth).floor().clamp(0, imageWidth - 1);
  final py = ((y - top) / drawHeight * imageHeight).floor().clamp(0, imageHeight - 1);
  final index = py * imageWidth + px;
  if (index < 0 || index >= alpha.length) return false;
  return alpha[index] > alphaThreshold;
}

bool outfitUsesCollage({
  required String? imagePath,
  required String coverMode,
  required bool hasPieces,
}) {
  final hasPhoto = imagePath != null && imagePath.isNotEmpty;
  return hasPieces && (coverMode == outfitCoverCollage || !hasPhoto);
}

class OutfitCoverModel {
  const OutfitCoverModel({
    required this.usesCollage,
    required this.pieces,
  });

  final bool usesCollage;
  final List<CollagePiece> pieces;
}

Widget? outfitCoverArt(OutfitCoverModel? model) {
  if (model == null || !model.usesCollage || model.pieces.isEmpty) return null;
  return OutfitPieceCollage(pieces: model.pieces);
}

class LabeledCoverCard extends StatelessWidget {
  const LabeledCoverCard({
    super.key,
    required this.label,
    required this.child,
    this.onDelete,
  });

  final String label;
  final Widget child;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            if (onDelete != null)
              IconButton(
                tooltip: '删除',
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
              ),
          ],
        ),
        AspectRatio(
          aspectRatio: collageCoverAspect,
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      ],
    );
  }
}

class OutfitPieceCollage extends StatelessWidget {
  const OutfitPieceCollage({super.key, required this.pieces});

  final List<CollagePiece> pieces;

  @override
  Widget build(BuildContext context) {
    final ordered = [...pieces]
      ..sort((a, b) => a.placement.z.compareTo(b.placement.z));
    return ColoredBox(
      color: AppColors.surface,
      child: CollageCoverBox(
        child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return Stack(
            children: [
              for (final piece in ordered)
                Positioned(
                  left: piece.placement.x * width,
                  top: piece.placement.y * height,
                  width: piece.placement.w * width,
                  height: piece.placement.h * height,
                  child: LocalCover(path: piece.path, fit: BoxFit.contain),
                ),
            ],
          );
        },
      ),
      ),
    );
  }
}
