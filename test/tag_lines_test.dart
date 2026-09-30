import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/core/vision/ocr/tag_ocr.dart';

void main() {
  const original = TagOcrResult(
    lines: ['品牌：A', '棉100%', '   ', '175/92A'],
    brand: 'A',
    fabric: '棉100%',
    sizeLabel: '175/92A',
    measurements: {'衣长': '70'},
  );

  void expectFieldsUnchanged(TagOcrResult next) {
    expect(next.brand, 'A');
    expect(next.fabric, '棉100%');
    expect(next.sizeLabel, '175/92A');
    expect(next.measurements, {'衣长': '70'});
  }

  test('editing, merging, and deleting lines keeps parsed fields', () {
    final edited = replaceTagLines(
      original,
      editTagLine(original.lines, 0, '品牌：B'),
    );
    expect(edited.lines, ['品牌：B', '棉100%', '175/92A']);
    expectFieldsUnchanged(edited);

    final merged = replaceTagLines(
      original,
      mergeAdjacentTagLines(original.lines, 0),
    );
    expect(merged.lines, ['品牌：A棉100%', '175/92A']);
    expectFieldsUnchanged(merged);

    final removed = replaceTagLines(original, removeTagLine(original.lines, 1));
    expect(removed.lines, ['品牌：A', '175/92A']);
    expectFieldsUnchanged(removed);
  });

  test('enter splits one line into two and keeps parsed fields', () {
    final split = splitTagLine(const ['品牌：A', '棉100%'], 0, '品牌：', 'A');
    expect(split, ['品牌：', 'A', '棉100%']);
    final next = replaceTagLines(original, split, keepEmpty: true);
    expectFieldsUnchanged(next);

    expect(splitTagLine(const ['甲'], 0, '甲', ''), ['甲', '']);
    expect(replaceTagLines(original, const ['甲', '']).lines, ['甲']);
  });

  test('blank lines are not kept', () {
    expect(editTagLine(const ['甲', '乙'], 0, '   '), ['乙']);
    expect(keptTagLines(const ['', '  ', '丙']), ['丙']);
    expect(replaceTagLines(original, const ['', '留下']).lines, ['留下']);
  });
}
