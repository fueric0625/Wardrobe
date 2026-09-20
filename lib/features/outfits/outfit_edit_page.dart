import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:wardrobe/core/storage/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:wardrobe/app/providers.dart';
import 'package:wardrobe/core/catalogs.dart';
import 'package:wardrobe/core/category_tree.dart';
import 'package:wardrobe/core/db/app_database.dart';
import 'package:wardrobe/core/theme.dart';

class OutfitEditPage extends ConsumerStatefulWidget {
  const OutfitEditPage({super.key, this.outfitId, this.categoryId});

  final String? outfitId;
  final String? categoryId;

  @override
  ConsumerState<OutfitEditPage> createState() => _OutfitEditPageState();
}

class _OutfitEditPageState extends ConsumerState<OutfitEditPage> {
  final _name = TextEditingController();
  final _note = TextEditingController();
  String _categoryId = 'uncategorized';
  String? _imagePath;
  String? _originalImagePath;
  DateTime? _createdAt;
  final Set<String> _seasons = {};
  bool _loaded = false;
  bool _saving = false;

  bool get _isEditing => widget.outfitId != null;

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId ?? 'uncategorized';
    if (_isEditing) {
      _load();
    } else {
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final item = await ref.read(outfitRepositoryProvider).getById(widget.outfitId!);
    if (!mounted) return;
    if (item == null) {
      context.go('/outfits');
      return;
    }
    _name.text = item.name;
    _note.text = item.note;
    _categoryId = item.categoryId;
    _imagePath = item.imagePath;
    _originalImagePath = item.imagePath;
    _createdAt = item.createdAt;
    _seasons
      ..clear()
      ..addAll(item.season.split(RegExp(r'[,，\s]+')).where((s) => s.isNotEmpty));
    setState(() => _loaded = true);
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
      final now = DateTime.now();
      final id = widget.outfitId ?? const Uuid().v4();
      final categories = ref.read(outfitCategoryRowsProvider);
      final selectedId = categoryById(categories, _categoryId)?.id ??
          uncategorizedClothingId;
      await ref.read(outfitRepositoryProvider).upsert(
            OutfitsCompanion(
              id: Value(id),
              categoryId: Value(selectedId),
              imagePath: Value(storedPath),
              name: Value(_name.text.trim()),
              season: Value(_seasons.join(',')),
              note: Value(_note.text.trim()),
              createdAt: Value(_createdAt ?? now),
              updatedAt: Value(now),
            ),
          );
      if (mounted) context.go('/outfits/item/$id');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这套穿搭？'),
        content: const Text('删除后无法恢复。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('删除')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(outfitRepositoryProvider).delete(widget.outfitId!);
    if (mounted) context.go('/outfits');
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final categories = ref.watch(outfitCategoryRowsProvider);
    final selectedId = categoryById(categories, _categoryId)?.id ??
        (categories.isEmpty ? _categoryId : uncategorizedClothingId);

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
                    '编辑穿搭',
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
                      child: Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: _pickImage,
                          child: SizedBox(
                            height: 380,
                            child: _imagePath == null
                                ? const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_photo_alternate_outlined,
                                        size: 48,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        '点击选择图片',
                                        style: TextStyle(color: AppColors.textMuted),
                                      ),
                                    ],
                                  )
                                : Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(File(_imagePath!), fit: BoxFit.cover),
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
                      ),
                    ),
                    const SizedBox(width: 28),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('分类', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(height: 6),
                            if (categories.isEmpty)
                              const Text('暂无分类', style: TextStyle(color: AppColors.textMuted))
                            else
                              DropdownButtonFormField<String>(
                                key: ValueKey(selectedId),
                                initialValue: selectedId,
                                items: [
                                  for (final c in flattenPreorder(categories))
                                    DropdownMenuItem(
                                      value: c.id,
                                      child: Text(categoryPath(categories, c.id)),
                                    ),
                                ],
                                onChanged: (v) {
                                  if (v != null) setState(() => _categoryId = v);
                                },
                              ),
                            const SizedBox(height: 12),
                            const Text('名称', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _name,
                              decoration: const InputDecoration(hintText: '给这套穿搭起个名字'),
                            ),
                            const SizedBox(height: 12),
                            const Text('季节', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final season in seasons)
                                  FilterChip(
                                    label: Text(season),
                                    selected: _seasons.contains(season),
                                    selectedColor: AppColors.primarySoft,
                                    checkmarkColor: AppColors.primary,
                                    onSelected: (on) {
                                      setState(() {
                                        if (on) {
                                          _seasons.add(season);
                                        } else {
                                          _seasons.remove(season);
                                        }
                                      });
                                    },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('备注', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _note,
                              maxLines: 5,
                              decoration: const InputDecoration(hintText: '输入备注信息'),
                            ),
                          ],
                        ),
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
}
