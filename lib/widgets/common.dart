import 'dart:io';

import 'package:flutter/material.dart';
import 'package:wardrobe/core/sort.dart';
import 'package:wardrobe/core/theme.dart';

class LocalCover extends StatelessWidget {
  const LocalCover({
    super.key,
    required this.path,
    this.borderRadius = 20,
    this.placeholder,
  });

  final String? path;
  final double borderRadius;
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    final file = path == null || path!.isEmpty ? null : File(path!);
    if (file == null || !file.existsSync()) {
      return placeholder ??
          const Center(
            child: Icon(Icons.add, size: 42, color: AppColors.primary),
          );
    }
    return Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) =>
          placeholder ??
          const Center(
            child: Icon(Icons.broken_image_outlined, color: AppColors.textMuted),
          ),
    );
  }
}

class CountBadge extends StatelessWidget {
  const CountBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xCC3A3F4C),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count个',
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({
    super.key,
    required this.label,
    required this.count,
    required this.coverPath,
    required this.onTap,
  });

  final String label;
  final int count;
  final String? coverPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LocalCover(path: coverPath),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: CountBadge(count: count),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      ],
    );
  }
}

class ItemTile extends StatelessWidget {
  const ItemTile({
    super.key,
    required this.coverPath,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isCover = false,
  });

  final String? coverPath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isCover;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LocalCover(path: coverPath),
                  if (isCover)
                    const Positioned(
                      left: 10,
                      top: 10,
                      child: _CoverBadge(),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title.isEmpty ? '未命名' : title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (subtitle.isNotEmpty)
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
      ],
    );
  }
}

class _CoverBadge extends StatelessWidget {
  const _CoverBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        '封面',
        style: TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }
}

class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hint = '搜索',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
  });

  final String title;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 22, 28, 12),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: leading ?? const SizedBox.shrink(),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: trailing ?? const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class SortButton extends StatelessWidget {
  const SortButton({
    super.key,
    required this.value,
    required this.fields,
    required this.onChanged,
  });

  final ListSort value;
  final List<SortField> fields;
  final ValueChanged<ListSort> onChanged;

  @override
  Widget build(BuildContext context) {
    final descending = value.direction == SortDirection.desc;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value.fieldLabel,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w600,
          ),
        ),
        Tooltip(
          message: value.directionLabel,
          child: InkWell(
            onTap: () => onChanged(value.toggled),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                descending ? Icons.arrow_downward : Icons.arrow_upward,
                size: 16,
                color: AppColors.text,
              ),
            ),
          ),
        ),
        PopupMenuButton<SortField>(
          tooltip: '选择排序',
          initialValue: value.field,
          padding: EdgeInsets.zero,
          splashRadius: 16,
          offset: const Offset(0, 8),
          onSelected: (field) => onChanged(value.withField(field)),
          itemBuilder: (context) => [
            for (final field in fields)
              PopupMenuItem(
                value: field,
                child: Text(field.label),
              ),
          ],
          child: const Padding(
            padding: EdgeInsets.fromLTRB(0, 6, 6, 6),
            child: Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }
}

class ReadOnlyField extends StatelessWidget {
  const ReadOnlyField({super.key, required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    final trimmed = value?.trim() ?? '';
    final empty = trimmed.isEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 6),
        Text(
          empty ? '未填写' : trimmed,
          style: TextStyle(
            color: empty ? AppColors.textMuted : AppColors.text,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class DetailHeroImage extends StatelessWidget {
  const DetailHeroImage({super.key, required this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 380,
        child: LocalCover(
          path: path,
          placeholder: const Center(
            child: Icon(Icons.image_outlined, size: 48, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }
}

class DetailFormCard extends StatelessWidget {
  const DetailFormCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class AddFab extends StatelessWidget {
  const AddFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
      child: const Icon(Icons.add, size: 30),
    );
  }
}
