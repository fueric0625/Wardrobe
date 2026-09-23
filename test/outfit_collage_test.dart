import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/widgets/piece_collage.dart';

void main() {
  test('auto placements fill a grid', () {
    final one = autoPlacements(const ['a']);
    expect(one.single.w, 1);
    expect(one.single.h, 1);

    final two = autoPlacements(const ['a', 'b']);
    expect(two.map((piece) => piece.clothingItemId), ['a', 'b']);
    expect(two.first.w, 0.5);
    expect(two.last.x, 0.5);
  });

  test('merge keeps a saved spot and adds a new piece', () {
    final saved = [
      const CollagePlacement(
        clothingItemId: 'a',
        x: 0.2,
        y: 0.3,
        w: 0.4,
        h: 0.5,
        z: 1,
      ),
    ];
    final merged = mergeCollageLayout(saved, const ['a', 'b']);
    expect(merged.first.x, 0.2);
    expect(
      merged.map((piece) => piece.clothingItemId),
      containsAll(['a', 'b']),
    );
    expect(mergeCollageLayout(saved, const ['b']).single.clothingItemId, 'b');
  });

  test('layout json round trip', () {
    final raw = encodeCollageLayout(autoPlacements(const ['shirt', 'pants']));
    final back = decodeCollageLayout(raw);
    expect(back.map((piece) => piece.clothingItemId), ['shirt', 'pants']);
    expect(decodeCollageLayout('not json'), isEmpty);
  });

  test('placements outside the canvas reload unchanged', () {
    const piece = CollagePlacement(
      clothingItemId: 'shirt',
      x: -0.25,
      y: 1.1,
      w: 1.4,
      h: 0.08,
      z: 4,
    );
    final back = decodeCollageLayout(encodeCollageLayout(const [piece])).single;
    expect(back.x, piece.x);
    expect(back.y, piece.y);
    expect(back.w, piece.w);
    expect(back.h, piece.h);
    expect(back.z, piece.z);
  });

  test('collage prefers the click cutout over the original photo', () {
    expect(
      preferCutoutPath(
        imagePath: 'original.jpg',
        images: const [
          (role: 'tag', isPrimary: false, processedPath: 'tag.png'),
          (role: 'garment', isPrimary: false, processedPath: 'other.png'),
          (role: 'garment', isPrimary: true, processedPath: 'cutout.png'),
        ],
      ),
      'cutout.png',
    );
    expect(
      preferCutoutPath(imagePath: 'original.jpg', images: const []),
      'original.jpg',
    );
  });

  test('hit testing stays on the cutout pixels', () {
    final alpha = Uint8List(4 * 2);
    alpha[0] = 255;
    expect(
      cutoutPixelHit(
        x: 10,
        y: 10,
        boxWidth: 100,
        boxHeight: 50,
        imageWidth: 4,
        imageHeight: 2,
        alpha: alpha,
      ),
      isTrue,
    );
    expect(
      cutoutPixelHit(
        x: 40,
        y: 10,
        boxWidth: 100,
        boxHeight: 50,
        imageWidth: 4,
        imageHeight: 2,
        alpha: alpha,
      ),
      isFalse,
    );
    expect(
      cutoutPixelHit(
        x: 10,
        y: 10,
        boxWidth: 100,
        boxHeight: 100,
        imageWidth: 4,
        imageHeight: 2,
        alpha: alpha,
      ),
      isFalse,
    );
  });

  test('cover choice can prefer the collage over a full-body photo', () {
    expect(
      outfitUsesCollage(
        imagePath: 'look.jpg',
        coverMode: outfitCoverPhoto,
        hasPieces: true,
      ),
      isFalse,
    );
    expect(
      outfitUsesCollage(
        imagePath: 'look.jpg',
        coverMode: outfitCoverCollage,
        hasPieces: true,
      ),
      isTrue,
    );
    expect(
      outfitUsesCollage(
        imagePath: null,
        coverMode: outfitCoverPhoto,
        hasPieces: true,
      ),
      isTrue,
    );
    expect(
      outfitUsesCollage(
        imagePath: null,
        coverMode: outfitCoverCollage,
        hasPieces: false,
      ),
      isFalse,
    );
  });
}
