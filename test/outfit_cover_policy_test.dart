import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/features/outfits/domain/outfit_cover_policy.dart';

void main() {
  test('cover falls back from the missing image', () {
    expect(
      outfitUsesCollage(
        imagePath: 'body.jpg',
        coverMode: outfitCoverPhoto,
        hasPieces: true,
      ),
      isFalse,
    );
    expect(
      outfitUsesCollage(
        imagePath: 'body.jpg',
        coverMode: outfitCoverCollage,
        hasPieces: true,
      ),
      isTrue,
    );
    expect(
      coverModeAfterChange(
        hasPhoto: true,
        hasCollage: false,
        coverMode: outfitCoverCollage,
      ),
      outfitCoverPhoto,
    );
    expect(
      coverModeAfterChange(
        hasPhoto: false,
        hasCollage: true,
        coverMode: outfitCoverPhoto,
      ),
      outfitCoverCollage,
    );
    expect(
      coverModeAfterChange(
        hasPhoto: false,
        hasCollage: false,
        coverMode: outfitCoverPhoto,
      ),
      outfitCoverPhoto,
    );
    expect(
      outfitUsesCollage(
        imagePath: null,
        coverMode: outfitCoverPhoto,
        hasPieces: false,
      ),
      isFalse,
    );
  });
}
