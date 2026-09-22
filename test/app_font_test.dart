import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/app_font.dart';

void main() {
  test('unknown font names fall back to DengXian', () {
    expect(resolveAppFont(null), defaultAppFontFamily);
    expect(resolveAppFont('  '), defaultAppFontFamily);
    expect(resolveAppFont('Comic Sans MS'), defaultAppFontFamily);
    expect(resolveAppFont('KaiTi'), 'KaiTi');
    expect(resolveAppFont(' DengXian '), 'DengXian');
  });
}
