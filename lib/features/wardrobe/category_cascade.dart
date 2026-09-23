import 'package:flutter/material.dart';
import 'package:wardrobe/core/catalog/catalogs.dart';
import 'package:wardrobe/core/catalog/category_tree.dart';
import 'package:wardrobe/core/database/app_database.dart';
import 'package:wardrobe/core/design_system/theme.dart';

/// Pick a clothing category from the root down, one dropdown per layer.
class CategoryCascadePicker extends StatelessWidget {
  const CategoryCascadePicker({
    super.key,
    required this.categories,
    required this.value,
    required this.onChanged,
  });

  final List<Category> categories;
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final dropdowns = categories.isEmpty ? const <Widget>[] : _levels();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '分类',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 6),
        if (categories.isEmpty)
          const Text('暂无分类', style: TextStyle(color: AppColors.textMuted))
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < dropdowns.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(child: dropdowns[i]),
              ],
            ],
          ),
      ],
    );
  }

  List<Widget> _levels() {
    final selected = categoryById(categories, value);
    final chain = selected == null
        ? const <Category>[]
        : ancestorsAndSelf(categories, selected);
    final dropdowns = <Widget>[];
    String? parentId;
    for (var level = 0; level <= maxCategoryDepth; level++) {
      final options = childrenOf(categories, parentId);
      if (options.isEmpty) break;

      String? selectedAtLevel;
      if (level < chain.length) {
        final id = chain[level].id;
        if (options.any((c) => c.id == id)) selectedAtLevel = id;
      }

      final stayOnParent = level > 0 ? parentId : null;
      final mappedValue =
          selectedAtLevel ?? (stayOnParent == null ? null : _stay);
      final items = <DropdownMenuItem<String>>[
        if (stayOnParent != null)
          const DropdownMenuItem(value: _stay, child: Text('-')),
        for (final category in options)
          DropdownMenuItem(value: category.id, child: Text(category.label)),
      ];
      dropdowns.add(
        InputDecorator(
          decoration: const InputDecoration(),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _itemValue(items, mappedValue),
              isExpanded: true,
              hint: Text(level == 0 ? '选择大类' : '-'),
              items: items,
              onChanged: (id) {
                if (id == null) return;
                if (id == _stay) {
                  onChanged(stayOnParent ?? uncategorizedClothingId);
                  return;
                }
                onChanged(id);
              },
            ),
          ),
        ),
      );

      if (selectedAtLevel == null) break;
      parentId = selectedAtLevel;
    }
    return dropdowns;
  }

  static String? _itemValue(List<DropdownMenuItem<String>> items, String? id) {
    if (id == null) return null;
    for (final item in items) {
      if (item.value == id) return id;
    }
    return null;
  }
}

const _stay = '__stay__';
