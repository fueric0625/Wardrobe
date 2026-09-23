/// A piece on the collage canvas.
///
/// [x], [y], [w] and [h] are fractions of the fixed 3:4 canvas. They may sit
/// outside `0..1` when a piece hangs off the canvas. Save and reload keep the
/// same numbers.
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

  CollagePlacement copyWith({
    double? x,
    double? y,
    double? w,
    double? h,
    int? z,
  }) {
    return CollagePlacement(
      clothingItemId: clothingItemId,
      x: x ?? this.x,
      y: y ?? this.y,
      w: w ?? this.w,
      h: h ?? this.h,
      z: z ?? this.z,
    );
  }
}
