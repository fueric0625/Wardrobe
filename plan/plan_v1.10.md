# 工程计划 1.0

这是工程计划 1.0。下面四个阶段已经落地。产品行为以 [docs/current-state.md](../docs/current-state.md) 和 [docs/invariants.md](../docs/invariants.md) 为准。本文保留当时的结构建议，不再作为新一轮重构的任务单。

可以。基于目前的代码结构，我建议**不要立即做大规模重构**，而是围绕几个共享锚点逐步优化：数据库模型、图片坐标体系、Repository 接口、Riverpod 状态和版本迁移。

下面的建议是基于静态阅读代码后的结构性建议。

---

# 一、先明确必须保持的核心不变量

后续重构不能破坏这些行为：

1. **应用是本地优先的 Windows 桌面应用**
   - SQLite 保存结构化数据。
   - 图片保存到 `%APPDATA%\wardrobe\images\`。
   - ONNX 模型在本地运行，不依赖 Python、云服务或网络。

2. **衣物图片有多种角色**
   - `garment`：衣物照，可以作为主图和穿搭素材。
   - `tag`：吊牌照，不能作为封面，也不能参与穿搭拼图。

3. **图片处理存在三套坐标**
   - 原始图片像素坐标。
   - 处理后缩放图片坐标。
   - Flutter 界面显示坐标。

   点击抠图、擦除、填补、预览和保存必须使用同一套转换关系，不能在不同组件中各自近似计算。

4. **穿搭封面有明确优先关系**
   - `coverMode = photo`：使用全身照。
   - `coverMode = collage`：使用衣物拼图。
   - 删除其中一种封面后，需要根据剩余内容自动回退。

5. **关系表具有唯一性**
   - 一套穿搭中同一件衣物只能出现一次。
   - 同一套穿搭在同一天只能挂载一次。
   - 同一个分类的同级顺序应该稳定。

6. **用户填写内容不能被自动识别无条件覆盖**
   - OCR、颜色识别只填充空字段或提供建议。
   - 用户已有内容必须优先保留。

7. **数据库迁移必须可重复执行且不丢数据**
   - 已经发布的 schema 迁移不能重写。
   - 新版本只追加新的迁移步骤。

这些不变量建议写进 `docs/architecture.md` 或 `docs/invariants.md`，否则未来重构很容易误伤现有逻辑。

---

# 二、优先级最高的改进

## P0：拆分超大页面，特别是 `outfit_edit_page.dart`

目前：

```text
lib/features/outfits/outfit_edit_page.dart
```

大约 900 行，同时承担了：

- 页面状态
- 数据加载
- 图片上传
- 图片模式切换
- 衣物选择
- 拼图布局
- 表单编辑
- 保存和删除
- 路由返回
- 各种对话框
- 业务校验

这会导致后续修改非常容易引入状态同步问题。

建议拆成：

```text
lib/features/outfits/
├── presentation/
│   ├── outfit_edit_page.dart
│   ├── outfit_edit_controller.dart
│   ├── outfit_photo_step.dart
│   ├── outfit_detail_step.dart
│   ├── outfit_edit_header.dart
│   └── outfit_edit_dialogs.dart
├── domain/
│   ├── outfit_draft.dart
│   ├── outfit_validation.dart
│   └── outfit_cover_policy.dart
└── data/
    └── outfit_repository.dart
```

其中：

- `OutfitEditController` 管理编辑过程中的状态。
- `OutfitDraft` 表示尚未保存的穿搭。
- `outfit_cover_policy.dart` 统一处理“全身照 / 拼图”的封面策略。
- Widget 只负责显示和发送用户操作。

衣橱中的 `item_edit_page.dart` 也有类似问题，虽然没有穿搭页那么严重，也建议按“图片工作室”和“表单”拆开。

---

## P1：把业务规则从 Widget 中抽出来

目前许多规则很可能直接写在页面 `build()` 或事件处理函数中，例如：

- 哪张图片是主图；
- 哪类图片可以作为封面；
- 删除全身照后是否切换到拼图；
- OCR 是否覆盖已有字段；
- 分类删除是否允许；
- 穿搭中是否已经选择某件衣物。

这些规则建议集中成纯 Dart 类或函数。

例如：

```text
lib/features/wardrobe/domain/item_photo_policy.dart
lib/features/outfits/domain/outfit_cover_policy.dart
lib/features/outfits/domain/outfit_selection_policy.dart
lib/core/catalog/domain/category_policy.dart
```

示例：

```dart
String? preferredItemDisplayPath({
  required String? legacyImagePath,
  required List<ClothingItemImage> images,
}) {
  // 统一决定列表、详情、穿搭使用哪张图
}
```

这样可以避免目前不同页面分别实现类似逻辑，最终产生不一致。

---

# 三、Repository 和数据层建议

## 1. 明确 Repository 的边界

现在 Repository 已经存在，这是一个好的基础：

- `LocalItemRepository`
- `LocalOutfitRepository`
- `LocalCalendarRepository`
- `LocalCategoryRepository`

但它们目前同时处理：

- Drift 数据库写入；
- 图片文件导入；
- 图片文件删除；
- 业务默认值；
- 关系表同步。

建议保留 Repository，但进一步明确分层：

```text
UI
 ↓
Controller / Notifier
 ↓
Use case / Service
 ↓
Repository
 ↓
Drift / ImageStore
```

例如衣物保存可以变成：

```text
SaveClothingItemUseCase
 ├── 校验表单
 ├── 导入图片
 ├── 保存图片记录
 ├── 更新主图
 └── 提交数据库事务
```

不建议让页面直接拼接 `ClothingItemsCompanion` 并处理所有保存细节。

---

## 2. 处理“数据库事务”和“文件系统操作”不具备原子性的问题

目前保存衣物时，数据库操作和图片复制是分开的。它们不能真正共享一个事务：

```text
复制图片成功
数据库写入失败
```

或者：

```text
数据库写入成功
图片复制失败
```

可能留下孤立文件或数据库中不存在的路径。

建议给 `ImageStore` 增加临时文件和提交机制：

```text
开始保存
  ↓
写入临时目录
  ↓
数据库事务成功
  ↓
移动到正式目录
  ↓
清理旧文件
```

或者至少实现：

```dart
final operation = await imageStore.beginImport(...);
try {
  await repository.save(...);
  await operation.commit();
} catch (_) {
  await operation.rollback();
  rethrow;
}
```

这对图片编辑和删除尤其重要。

---

## 3. 统一数据模型中的 JSON 字段

目前以下字段使用字符串保存 JSON：

- `measurements`
- `tags`
- `colorJson`
- `ocrJson`
- `collageLayout`
- `sizeFields`

这在原型阶段可接受，但建议不要在各个页面中直接 `jsonEncode/jsonDecode`。

可以统一放到：

```text
lib/core/serialization/
├── color_analysis_codec.dart
├── tag_ocr_codec.dart
├── collage_layout_codec.dart
├── measurement_codec.dart
└── category_size_fields_codec.dart
```

并为每种 JSON 定义强类型对象：

```dart
class CollageLayout {
  const CollageLayout({required this.placements});

  final List<CollagePlacement> placements;

  String encode() => ...;

  static CollageLayout decode(String? raw) => ...;
}
```

这样可以集中处理：

- 空字符串；
- 非法 JSON；
- 老版本字段；
- 缺省字段；
- 数字类型兼容；
- 未来 schema 变化。

---

# 四、图片和坐标系统建议

这是这个项目最值得优先规范的部分。

## 1. 统一图片会话模型

目前图片工作室、MobileSAM、擦除、填补和预览分别传递：

- 原图 bytes；
- Mask bytes；
- 图片路径；
- 缩放后的图片；
- 显示区域；
- 点击点；
- 笔刷点。

建议引入一个明确的图片编辑会话对象：

```dart
class ImageEditSession {
  final Uint8List originalBytes;
  final Uint8List? maskBytes;
  final int imageWidth;
  final int imageHeight;
  final ContainLayout layout;
  final List<RefineOperation> operations;
}
```

操作统一表示为：

```dart
sealed class RefineOperation {}

class ClickOperation extends RefineOperation {
  final PromptPoint point;
}

class EraseOperation extends RefineOperation {
  final List<EraseStamp> stamps;
}

class FillOperation extends RefineOperation {
  final List<EraseStamp> samples;
  final List<EraseStamp> paints;
}
```

这样撤销、重做、重建 Mask 都可以基于同一个操作列表完成，而不是分别维护多套状态。

---

## 2. 明确坐标类型，避免普通 `Offset` 混用

建议区分：

```dart
class ImagePixelPoint {
  final double x;
  final double y;
}

class ViewportPoint {
  final double x;
  final double y;
}

class ImagePixelRect {}
class ViewportRect {}
```

现在如果不同组件都使用 `Offset`，很容易把界面坐标误传给图片处理函数。

核心转换应该集中在一个地方：

```dart
class ImageCoordinateMapper {
  ImageCoordinateMapper({
    required this.imageSize,
    required this.viewportSize,
    required this.fit,
  });

  ImagePixelPoint toImage(Offset viewportPoint);
  Offset toViewport(ImagePixelPoint imagePoint);
}
```

`ContainLayout` 可以继续保留，但建议将它提升成明确的坐标映射基础设施，而不是只作为若干 Overlay 的辅助类。

---

## 3. 拼图布局也使用统一的归一化坐标

当前 `CollagePlacement` 使用：

```text
x, y, w, h, z
```

建议明确 `x/y/w/h` 是：

- 画布比例坐标；
- 还是像素坐标；
- 还是 0 到 1 的归一化坐标。

推荐使用 0 到 1 的归一化坐标：

```dart
class CollagePlacement {
  final double x; // 0..1
  final double y; // 0..1
  final double width; // 0..1
  final double height; // 0..1
  final int zIndex;
}
```

同时在编码时进行边界约束：

```dart
x = x.clamp(0, 1);
y = y.clamp(0, 1);
width = width.clamp(0.01, 1);
height = height.clamp(0.01, 1);
```

这样不同窗口尺寸、不同 DPI 和不同画布尺寸下，拼图都能稳定复现。

---

# 五、Riverpod 状态管理建议

目前 Provider 主要承担：

- Repository 注入；
- Stream 查询；
- 排序状态；
- 计算穿搭封面。

这是可以工作的，但页面内部仍保存了大量编辑状态。

建议采用以下规则：

## Provider 负责长期和共享状态

例如：

```text
clothingItemsProvider
outfitsProvider
calendarProvider
categoryProvider
imageRowsProvider
```

## Notifier/Controller 负责页面级编辑状态

例如：

```text
itemEditControllerProvider(itemId)
outfitEditControllerProvider(outfitId)
calendarDayControllerProvider(day)
```

## Widget 不直接承担复杂异步流程

例如不要让页面自己维护很多：

```dart
bool _busy;
String? _error;
List<EditableItemPhoto> _photos;
...
```

可以变成：

```dart
class ItemEditState {
  final ItemEditStage stage;
  final List<EditableItemPhoto> photos;
  final bool isSaving;
  final String? error;
}
```

这样加载、保存、OCR、抠图失败和取消编辑的状态会更容易控制。

---

# 六、ONNX 和视觉模块建议

## 1. 把模型会话配置集中管理

当前 `TagOcr` 和抠图模型各自有：

- 模型资产路径；
- 输入输出名称；
- 预处理逻辑；
- 输出数量；
- 生命周期管理。

建议抽象出：

```text
lib/core/vision/model/
├── model_asset.dart
├── model_session.dart
├── tensor_preprocessor.dart
└── model_errors.dart
```

并使用统一的模型状态：

```dart
enum ModelStatus {
  unloaded,
  loading,
  ready,
  failed,
}
```

这样 UI 可以区分：

- 模型还没加载；
- 模型正在加载；
- 模型不可用；
- 推理失败；
- 当前平台不支持。

## 2. 不要让 FFI 层暴露太多底层细节

`OnnxRuntime` 目前同时负责：

- 加载 DLL；
- 管理 session；
- 分配 native memory；
- 读写 tensor；
- 暴露输入输出名称；
- 处理错误。

建议拆成两层：

```text
OnnxRuntimeNative
  只负责 FFI 和内存

OnnxSession
  负责模型 session 的业务封装
```

例如：

```dart
final session = OnnxSession(
  name: 'ocr_rec',
  modelPath: path,
);
final output = session.run(...);
```

这样 `TagOcr` 不需要知道底层的 `Pointer<Float>`、输出缓冲区大小等细节。

---

# 七、错误处理规范

目前许多视觉流程使用了类似：

```dart
catch (_) {
  return resultWithError(...);
}
```

这能避免应用崩溃，但会丢失具体错误原因。

建议统一异常类型：

```dart
sealed class AppFailure implements Exception {}

class ImageDecodeFailure extends AppFailure {}
class ModelLoadFailure extends AppFailure {}
class InferenceFailure extends AppFailure {}
class StorageFailure extends AppFailure {}
class ValidationFailure extends AppFailure {}
```

然后分层处理：

```text
底层：保留原始异常和上下文
Repository：转换为领域错误
Controller：更新 UI 状态
页面：显示用户可理解的提示
```

至少不要在所有地方使用裸 `catch (_)`, 否则排查模型、图片或文件问题会比较困难。

---

# 八、数据库和版本规范

## 1. 统一版本来源

目前至少存在两套版本概念：

- `pubspec.yaml`：`1.9.0+1`
- `plan/`：已经描述到 v1.9

建议明确区分：

```text
产品版本：v1.9
应用构建版本：1.9.0+1
数据库版本：schema 9
```

可以在 `pubspec.yaml`、README 和版本计划中统一。

## 2. 清理过期文档

静态阅读时能看到一些版本说明仍描述旧 schema，而代码已经是 schema 9。

建议：

- 旧版本文档保留历史内容；
- 当前状态单独维护 `docs/current-state.md`；
- README 只引用当前版本；
- 明确标注“历史设计”与“已实现功能”。

## 3. 迁移测试放到明确的目录

`build.yaml` 中配置了：

```yaml
test_dir: test/drift/
```

建议确认这个目录和实际测试文件保持一致，并至少覆盖：

- 空库创建；
- schema 旧版本升级；
- 已有 OCR 字段的旧库升级；
- 重复执行迁移；
- 关系表数据保留；
- 图片路径数据保留。

---

# 九、代码规范建议

## 1. 增加项目级 `.editorconfig`

统一解决前面提到的编码和换行问题：

```ini
root = true

[*]
charset = utf-8
end_of_line = crlf
insert_final_newline = true
indent_style = space
indent_size = 2

[*.dart]
indent_size = 2
```

如果团队环境中同时使用 PowerShell 5 和 VS Code，这一点尤其有价值。

## 2. 开启更严格的 analyzer 规则

当前主要依赖默认的 `flutter_lints`，可以逐步增加：

```yaml
analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true

linter:
  rules:
    - always_declare_return_types
    - avoid_dynamic_calls
    - cancel_subscriptions
    - close_sinks
    - prefer_final_locals
    - unnecessary_lambdas
    - use_build_context_synchronously
```

不建议一次性开启大量规则，最好先处理现有警告，再逐步增加。

## 3. 文件命名和目录命名统一

目前 `features` 下已经有不错的按功能拆分，但 `core` 中同时存在：

```text
core/catalog
core/storage
core/vision
core/db
```

建议长期统一成：

```text
core/
├── database/
├── storage/
├── vision/
├── design_system/
└── utils/
```

`app_font.dart` 和 `theme.dart` 可以放入：

```text
core/design_system/
```

---

# 十、测试优先级

当前测试已经覆盖了不少纯逻辑，但建议按风险补充以下测试。

## 最高优先级

### 图片路径和删除

- 删除衣物时是否删除所有应用拥有的图片。
- 用户原始路径是否不会被误删。
- 替换图片后旧的 processed/mask 文件是否清理。
- 保存失败时是否留下孤立文件。

### 穿搭封面策略

覆盖以下组合：

| 全身照 | 拼图 | coverMode | 预期 |
|---|---|---|---|
| 有 | 有 | photo | 全身照 |
| 有 | 有 | collage | 拼图 |
| 有 | 无 | collage | 回退全身照 |
| 无 | 有 | photo | 回退拼图 |
| 无 | 无 | 任意 | 空状态 |

### 坐标转换

- 窄图、宽图；
- 高 DPI；
- 缩放；
- 滚动；
- 图片被裁剪或留白；
- 点击边界；
- 笔刷超出图片范围。

### 数据迁移

- schema 1 到 schema 9；
- schema 5 到 schema 9；
- 重复迁移；
- 已存在列或表；
- 迁移失败后的回滚。

---

# 推荐的实际实施顺序

我建议按以下顺序做，而不是全面重写：

## 第一阶段：规范和风险控制

1. 增加 `.editorconfig`。
2. 统一产品版本和 schema 文档。
3. 补充图片文件生命周期测试。
4. 补充穿搭封面策略测试。
5. 为 JSON 字段增加统一 codec。

## 第二阶段：拆状态

1. 把 `outfit_edit_page.dart` 拆成 Controller、Draft 和子页面。
2. 把 `item_edit_page.dart` 的图片工作室状态抽出来。
3. 让页面不再直接负责复杂保存流程。

## 第三阶段：统一坐标系统

1. 引入 `ImagePixelPoint`、`ViewportPoint`。
2. 集中实现 `ImageCoordinateMapper`。
3. 让点击、擦除、填补和预览全部使用它。
4. 明确拼图布局采用归一化坐标。

## 第四阶段：增强存储和模型层

1. 改进图片导入的临时文件和回滚。
2. 拆分 ONNX FFI 与业务模型 session。
3. 统一错误类型和模型状态。
4. 最后再考虑更大范围的目录重组。

## 已完成

四个阶段都已按本文落地，产品行为保持不变：

1. 规范和风险控制：`.editorconfig`、版本与 schema 文档、图片生命周期测试、封面策略测试、JSON codec。
2. 拆状态：穿搭编辑拆成 Controller、Draft 和子页面；衣物编辑抽出图片会话；页面不再直接拼保存用的数据库对象。
3. 统一坐标：`ImagePixelPoint`、`ViewportPoint`、`ImageCoordinateMapper`；点选、擦除、填补和拼图命中走同一映射。
4. 存储和模型层：图片临时导入与回滚、`OnnxSession`、`AppFailure`；`core/database` 与 `core/design_system` 已就位。

后续新功能按 [codex-cursor-Collaboration_Guidelines.md](codex-cursor-Collaboration_Guidelines.md) 小步做，不再重开这四个阶段。