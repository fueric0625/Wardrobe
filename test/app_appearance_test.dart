import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/design_system/app_appearance.dart';
import 'package:wardrobe/core/design_system/app_font.dart';

void main() {
  test('unknown appearance values fall back to defaults', () {
    final appearance = decodeAppAppearance('not json', fontFallback: 'KaiTi');
    expect(appearance.fontFamily, 'KaiTi');
    expect(appearance.textSizeId, defaultAppTextSizeId);
    expect(appearance.colorId, defaultAppColorId);
  });

  test('appearance json round-trips font size and color', () {
    const original = AppAppearance(
      fontFamily: 'KaiTi',
      textSizeId: 'large',
      colorId: 'rose',
    );
    final decoded = decodeAppAppearance(encodeAppAppearance(original));
    expect(decoded.fontFamily, 'KaiTi');
    expect(decoded.textSizeId, 'large');
    expect(decoded.colorId, 'rose');
    expect(decoded.textScale, 1.15);
  });

  test('a missing font in appearance json uses the font.txt fallback', () {
    final decoded = decodeAppAppearance(
      '{"textSize":"small","color":"teal"}',
      fontFallback: 'SimHei',
    );
    expect(decoded.fontFamily, 'SimHei');
    expect(decoded.textSizeId, 'small');
    expect(decoded.colorId, 'teal');
    expect(decoded.fontFamily, isNot(defaultAppFontFamily));
  });
}
