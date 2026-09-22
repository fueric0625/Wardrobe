import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/vision/cutout/image_ops.dart';
import 'package:wardrobe/core/vision/ocr/tag_ocr.dart';

void main() {
  test('parseTagText reads labeled brand fabric size and measures', () {
    final result = parseTagText('''
品牌：UNIQLO
成分：棉 100%
尺码：M
衣长 70
胸围 108
''');
    expect(result.brand, 'UNIQLO');
    expect(result.fabric, contains('棉'));
    expect(result.sizeLabel, 'M');
    expect(result.measurements['衣长'], '70');
    expect(result.measurements['胸围'], '108');
  });

  test('parseTagText guesses latin brand and fiber mix', () {
    final result = parseTagText('NIKE\nSIZE M\n聚酯纤维 92% 氨纶 8%');
    expect(result.brand, 'NIKE');
    expect(result.sizeLabel, 'M');
    expect(result.fabric, contains('聚酯纤维'));
    expect(result.fabric, contains('氨纶'));
  });

  test('parseTagText reads 170/88A', () {
    final result = parseTagText('号型 170/88A');
    expect(result.sizeLabel, '170/88A');
  });

  test('ocrCtcClassCount uses blank plus space (6625)', () {
    expect(ocrCtcClassCount(40 * 6625, 6623), 6625);
    expect(ocrCtcClassCount(80 * 6624, 6623), 6624);
  });

  test('ocrCtcDecode skips blanks, repeats, and can emit space', () {
    const keys = ['A', 'B', 'C'];
    List<double> step(int best) => [
          for (var c = 0; c < 5; c++) c == best ? 8.0 : 0.0,
        ];
    final logits = [
      ...step(1),
      ...step(1),
      ...step(0),
      ...step(2),
      ...step(4),
      ...step(3),
    ];
    expect(ocrCtcDecode(logits, keys), 'AB C');
  });

  test('ocrCtcDecode drops low-confidence noise', () {
    const keys = ['A', 'B', 'C'];
    List<double> step(int best, double v) => [
          for (var c = 0; c < 5; c++) c == best ? v : 0.0,
        ];
    final logits = [...step(1, 0.12), ...step(2, 0.11), ...step(3, 0.10)];
    expect(ocrCtcDecode(logits, keys), 'ABC');
    expect(ocrCtcDecode(logits, keys, minConfidence: 0.45), '');
  });

  test('sortOcrBoxes reads top-to-bottom then left-to-right', () {
    final boxes = [
      const PixelRect(x: 80, y: 10, width: 40, height: 12),
      const PixelRect(x: 50, y: 200, width: 40, height: 12),
      const PixelRect(x: 10, y: 80, width: 60, height: 12),
      const PixelRect(x: 20, y: 198, width: 20, height: 12),
    ];
    sortOcrBoxes(boxes);
    expect(boxes.map((b) => b.x).toList(), [80, 10, 20, 50]);
    expect(boxes.first.y, 10);
  });

  test('TagOcrResult json round-trips', () {
    const result = TagOcrResult(
      lines: ['品牌：A', '衣长 70'],
      brand: 'A',
      fabric: '棉',
      sizeLabel: 'M',
      measurements: {'衣长': '70'},
    );
    final decoded = TagOcrResult.decode(result.encode());
    expect(decoded.brand, 'A');
    expect(decoded.fabric, '棉');
    expect(decoded.sizeLabel, 'M');
    expect(decoded.measurements['衣长'], '70');
    expect(decoded.text, contains('衣长 70'));
    expect(TagOcrResult.decode('').isEmpty, isTrue);
  });
}
