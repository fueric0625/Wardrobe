import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/vision/coordinates/image_coordinate_mapper.dart';

void main() {
  test('wide and tall images letterbox clicks outside the image', () {
    final wide = ImageCoordinateMapper(
      imageWidth: 200,
      imageHeight: 50,
      viewportWidth: 100,
      viewportHeight: 100,
    );
    expect(wide.toImage(const ViewportPoint(50, 10)), isNull);
    final inside = wide.toImage(const ViewportPoint(50, 50));
    expect(inside, isNotNull);

    final tall = ImageCoordinateMapper(
      imageWidth: 50,
      imageHeight: 200,
      viewportWidth: 100,
      viewportHeight: 100,
    );
    expect(tall.toImage(const ViewportPoint(10, 50)), isNull);
    expect(tall.toImage(const ViewportPoint(50, 50)), isNotNull);
  });

  test('a click on the image edge maps back into the same pixel', () {
    final mapper = ImageCoordinateMapper(
      imageWidth: 4,
      imageHeight: 2,
      viewportWidth: 100,
      viewportHeight: 50,
    );
    final pixel = mapper.toImageFloored(const ViewportPoint(10, 10));
    expect(pixel, isNotNull);
    final back = mapper.toViewport(pixel!);
    final again = mapper.toImageFloored(back);
    expect(again!.x, pixel.x);
    expect(again.y, pixel.y);
  });

  test('points past the image are not a brush hit', () {
    final mapper = ImageCoordinateMapper(
      imageWidth: 10,
      imageHeight: 10,
      viewportWidth: 100,
      viewportHeight: 40,
    );
    expect(mapper.toImage(const ViewportPoint(10, 20)), isNull);
    expect(mapper.toImage(const ViewportPoint(150, 20)), isNull);
  });
}
