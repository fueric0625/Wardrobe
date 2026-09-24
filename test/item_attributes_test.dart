import 'package:flutter_test/flutter_test.dart';
import 'package:wardrobe/features/wardrobe/item_attributes.dart';

void main() {
  test('style keeps known chips and older free text', () {
    expect(encodeStyle({'短袖', '直身', '阔腿裤'}), '直身,短袖,阔腿裤');
    expect(decodeStyle('直身,短袖'), {'直身', '短袖'});
  });

  test('care keeps one choice in a group', () {
    final once = toggleCare({'wash-40'}, careGroups.first, 'wash-30');
    expect(once, {'wash-30'});
    expect(toggleCare(once, careGroups.first, 'wash-30'), isEmpty);
    expect(encodeCare({'wash-30', 'iron-medium'}), 'wash-30,iron-medium');
  });
}
