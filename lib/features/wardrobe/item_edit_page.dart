import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:wardrobe/core/storage/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/catalogs.dart';
import 'package:wardrobe/core/category_tree.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/theme.dart';

class ItemEditPage extends ConsumerStatefulWidget {
  const ItemEditPage({super.key, this.itemId, this.categoryId});

  final String? itemId;
  final String? categoryId;

  @override
  ConsumerState<ItemEditPage> createState() => _ItemEditPageState();
}

class _ItemEditPageState extends ConsumerState<ItemEditPage> {
  final _type = TextEditingController();
  final _style = TextEditingController();
  final _color = TextEditingController();
  final _fabric = TextEditingController();
  final _brand = TextEditingController();
  final _price = TextEditingController();
  final _purchaseInfo = TextEditingController();
  final _location = TextEditingController();
  final _tags = TextEditingController();
  final _note = TextEditingController();
  final _measureControllers = <String, TextEditingController>{};

  String _categoryId = 'uncategorized';
  String? _imagePath;
  String? _originalImagePath;
  DateTime? _purchasedAt;
  DateTime? _createdAt;
  final Set<String> _seasons = {};
  bool _loaded = false;
  bool _saving = false;

  bool get _isEditing => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId ?? 'uncategorized';
    _ensureMeasureControllers();
    if (_isEditing) {
      _load();
    } else {
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _type.dispose();
    _style.dispose();
    _color.dispose();
    _fabric.dispose();
    _brand.dispose();
    _price.dispose();
    _purchaseInfo.dispose();
    _location.dispose();
    _tags.dispose();
    _note.dispose();
    for (final c in _measureControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _ensureMeasureControllers([List<Category> categories = const []]) {
    for (final field in allSizeFieldNames()) {
      _measureControllers.putIfAbsent(field, TextEditingController.new);
    }
    for (final category in categories) {
      for (final field in decodeSizeFields(category.sizeFields)) {
        _measureControllers.putIfAbsent(field, TextEditingController.new);
      }
    }
  }

  Future<void> _load() async {
    final item = await ref.read(itemRepositoryProvider).getById(widget.itemId!);
    if (!mounted) return;
    if (item == null) {
      context.go('/wardrobe');
      return;
    }
    _type.text = item.type;
    _style.text = item.style;
    _color.text = item.color;
    _fabric.text = item.fabric;
    _brand.text = item.brand;
    _price.text = item.price == null ? '' : _trimNumber(item.price!);
    _purchaseInfo.text = item.purchaseInfo;
    _location.text = item.location;
    _tags.text = item.tags;
    _note.text = item.note;
    _categoryId = item.categoryId;
    _imagePath = item.imagePath;
    _originalImagePath = item.imagePath;
    _purchasedAt = item.purchasedAt;
    _createdAt = item.createdAt;
    _seasons
      ..clear()
      ..addAll(
        item.season.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty),
      );
    final measures = decodeMeasurements(item.measurements);
    for (final entry in measures.entries) {
      _measureControllers.putIfAbsent(entry.key, TextEditingController.new).text =
          entry.value;
    }
    setState(() => _loaded = true);
  }

  String _trimNumber(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  Future<void> _pickImage() async {
    final path = await pickImagePath();
    if (path == null) return;
    setState(() => _imagePath = path);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final images = ref.read(imageStoreProvider);
      var storedPath = _imagePath;
      if (storedPath != null && storedPath != _originalImagePath) {
        storedPath = await images.importFile(storedPath);
        if (_originalImagePath != null) {
          await images.deleteIfOwned(_originalImagePath);
        }
      }

      final categories = ref.read(clothingCategoryRowsProvider);
      final selectedId = categoryById(categories, _categoryId)?.id ??
          uncategorizedClothingId;
      final node = categoryById(categories, selectedId);
      final fields = node == null ? <String>[] : inheritedSizeFields(categories, node);
      final measures = <String, String>{};
      for (final field in fields) {
        final value = _measureControllers[field]?.text.trim() ?? '';
        if (value.isNotEmpty) measures[field] = value;
      }

      final now = DateTime.now();
      final id = widget.itemId ?? const Uuid().v4();
      final priceText = _price.text.trim();
      await ref.read(itemRepositoryProvider).upsert(
            ClothingItemsCompanion(
              id: Value(id),
              categoryId: Value(selectedId),
              imagePath: Value(storedPath),
              type: Value(_type.text.trim()),
              style: Value(_style.text.trim()),
              color: Value(_color.text.trim()),
              season: Value(_seasons.join(',')),
              fabric: Value(_fabric.text.trim()),
              brand: Value(_brand.text.trim()),
              price: Value(priceText.isEmpty ? null : double.tryParse(priceText)),
              measurements: Value(jsonEncode(measures)),
              purchasedAt: Value(_purchasedAt),
              purchaseInfo: Value(_purchaseInfo.text.trim()),
              location: Value(_location.text.trim()),
              tags: Value(_tags.text.trim()),
              note: Value(_note.text.trim()),
              createdAt: Value(_createdAt ?? now),
              updatedAt: Value(now),
            ),
          );
      if (mounted) context.go('/wardrobe/item/$id');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这件衣物？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(itemRepositoryProvider).delete(widget.itemId!);
    if (mounted) context.go('/wardrobe');
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchasedAt ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _purchasedAt = picked);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final categories = ref.watch(clothingCategoryRowsProvider);
    _ensureMeasureControllers(categories);
    final selectedId = categoryById(categories, _categoryId)?.id ??
        (categories.isEmpty ? _categoryId : uncategorizedClothingId);
    final node = categoryById(categories, selectedId);
    final sizeFields = node == null ? <String>[] : inheritedSizeFields(categories, node);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 28, 8),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 16),
                  label: const Text('返回'),
                ),
                const Expanded(
                  child: Text(
                    '编辑单品信息',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                if (_isEditing)
                  TextButton(
                    onPressed: _delete,
                    child: const Text('删除', style: TextStyle(color: Colors.redAccent)),
                  ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? '保存中' : '确定'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 320,
                      child: _ImagePicker(
                        path: _imagePath,
                        onPick: _pickImage,
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: _FormCard(
                        children: [
                          _DropdownRow(
                            label: '分类',
                            value: selectedId,
                            items: {
                              for (final c in flattenPreorder(categories))
                                c.id: categoryPath(categories, c.id),
                            },
                            onChanged: (v) => setState(() => _categoryId = v),
                          ),
                          _split(
                            _LabeledField(label: '类别', hint: '如衬衫、长裤', controller: _type),
                            _LabeledField(label: '款式', hint: '如阔腿裤、直筒裤', controller: _style),
                          ),
                          _split(
                            _LabeledField(label: '颜色', hint: '手填颜色', controller: _color),
                            _SeasonPicker(
                              selected: _seasons,
                              onChanged: (next) => setState(() {
                                _seasons
                                  ..clear()
                                  ..addAll(next);
                              }),
                            ),
                          ),
                          _split(
                            _LabeledField(label: '面料', hint: '手填面料', controller: _fabric),
                            _LabeledField(label: '品牌', hint: '手填品牌', controller: _brand),
                          ),
                          _split(
                            _LabeledField(
                              label: '价格',
                              hint: '元',
                              controller: _price,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                              ],
                            ),
                            _DateRow(
                              label: '购入时间',
                              value: _purchasedAt,
                              onTap: _pickDate,
                              onClear: () => setState(() => _purchasedAt = null),
                            ),
                          ),
                          if (sizeFields.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(top: 8, bottom: 4),
                              child: Text('尺码', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                for (final field in sizeFields)
                                  SizedBox(
                                    width: 160,
                                    child: _LabeledField(
                                      label: field,
                                      hint: field,
                                      controller: _measureControllers[field]!,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                          _LabeledField(
                            label: '购买信息',
                            hint: '商场专柜、淘宝、闲鱼等',
                            controller: _purchaseInfo,
                          ),
                          _LabeledField(
                            label: '存放位置',
                            hint: '输入存放位置',
                            controller: _location,
                          ),
                          _LabeledField(
                            label: '标签',
                            hint: '用逗号分隔',
                            controller: _tags,
                          ),
                          _LabeledField(
                            label: '备注',
                            hint: '输入备注信息',
                            controller: _note,
                            maxLines: 4,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _split(Widget left, Widget right) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

class _ImagePicker extends StatelessWidget {
  const _ImagePicker({required this.path, required this.onPick});

  final String? path;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPick,
        child: SizedBox(
          height: 380,
          child: path == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.primary),
                    SizedBox(height: 12),
                    Text('点击选择图片', style: TextStyle(color: AppColors.textMuted)),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(path!), fit: BoxFit.cover),
                    const Positioned(
                      right: 12,
                      bottom: 12,
                      child: Chip(
                        label: Text('更换图片'),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});

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
            if (i != children.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.hint,
    required this.controller,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(hintText: hint),
        ),
      ],
    );
  }
}

class _DropdownRow extends StatelessWidget {
  const _DropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 6),
        if (items.isEmpty)
          const Text('暂无分类', style: TextStyle(color: AppColors.textMuted))
        else
          DropdownButtonFormField<String>(
          key: ValueKey(value),
          initialValue: items.containsKey(value) ? value : items.keys.first,
          items: [
            for (final entry in items.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _SeasonPicker extends StatelessWidget {
  const _SeasonPicker({required this.selected, required this.onChanged});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('季节', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final season in seasons)
              FilterChip(
                label: Text(season),
                selected: selected.contains(season),
                selectedColor: AppColors.primarySoft,
                checkmarkColor: AppColors.primary,
                onSelected: (on) {
                  final next = {...selected};
                  if (on) {
                    next.add(season);
                  } else {
                    next.remove(season);
                  }
                  onChanged(next);
                },
              ),
          ],
        ),
      ],
    );
  }
}

class _DateRow extends StatelessWidget {
  const _DateRow({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: const InputDecoration(),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value == null ? '选择日期' : DateFormat('yyyy-MM-dd').format(value!),
                    style: TextStyle(
                      color: value == null ? AppColors.textMuted : AppColors.text,
                    ),
                  ),
                ),
                if (value != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: onClear,
                    icon: const Icon(Icons.close, size: 16),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
