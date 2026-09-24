# 当前状态

产品 **v1.0.13**，应用构建版本 **1.0.13+1**（`pubspec.yaml`），数据库 **schema 10**。版本沿革见 [plan/version_outline.md](../plan/version_outline.md)。不能破坏的行为见 [invariants.md](invariants.md)。

数据在 `%APPDATA%\wardrobe\`。改过数据库结构后必须完全重启，热重载不够。schema 1–9 是已发出的手写升级，不重写。schema 10 起走快照步骤。快照从版本 9 起，见 `drift_schemas/app_database/`。

## 代码格式

- `.editorconfig`：UTF-8、CRLF、文件末尾换行、2 空格。
- 改过 Dart 后运行 `dart format lib test`。
- `analysis_options.yaml` 在 Flutter 推荐规则之外打开了 `use_build_context_synchronously`、`cancel_subscriptions`、`close_sinks`。

## 目录

各板块的文件和依赖见 [code-structure.md](code-structure.md)。

```text
lib/core/database        Drift 库与 schema 10
lib/core/design_system   主题、字体、文字大小、主体色
lib/core/storage         图片暂存、提交、回滚
lib/core/serialization   拼图、颜色、OCR、测量的 JSON
lib/core/vision          坐标映射、抠图、OCR、ONNX 会话
lib/core/catalog         分类树与分类策略
lib/features/wardrobe    衣橱列表、详情、图片工作室
lib/features/outfits     穿搭向导、拼图、封面
lib/features/calendar    月历、日程、虚拟天气
```

## 现有功能

衣橱是分类树：大分类下最多两层小分类，「无分类」不能删。同一层不能重名。分类管理里用拖动手柄调整同一层的顺序，子分类跟着原来的父分类走，不能靠拖拽改到别的父分类下。删除子分类时衣物回到直接上一级。封面按子树，详情里可以设封面，顶栏可以移动到别的分类。

一件衣物的详情按这个顺序显示：品名、所在分类、号型、点选的款式、颜色、面料和季节、品牌、点选的洗涤维护、价格和购入时间、尺码测量、存放位置、标签、备注、吊牌原文。款式可以多选。洗涤分五组，每一组只留一个。选中的标签是浅色底，没有边框。类别和购买信息不再出现在页面上。没有品名时，列表先显示以前的类别。版式稿在 [design/item-detail.pen](../design/item-detail.pen)。库是 schema 10。

一件衣物可以有多张图。新增时先在图片工作室处理：点选抠外形、笔擦、取样后涂抹填补，再从 Mask 取颜色。吊牌照单独加，本机 OCR 建议填品牌、面料、尺码；已填写的字段不覆盖。吊牌不能当封面，也不能进穿搭拼图。

穿搭向导是关联衣物、OOTD、详情。OOTD 左边是全身照，右边是 3:4 拼图，用衣物的点选抠图来摆。封面可以选全身照或拼图。详情两张都显示，各自可删。

日历点某一天添加日程，同一天可以挂多套穿搭。天气按日期算出来，标「虚拟」，不联网。

侧栏底部进入设置。可以改字体、文字大小和主体颜色，选择会记在本机并立刻生效。五款字体里的「微软雅黑」是完整的微软雅黑。等线没有「橱」，缺这个字时只从微软雅黑补上。

## 还没做

- 吊牌原文按行修改、合并、删除，以及识别文字的自动矫正
- 列表排序条件写到本地（现在只在本次运行里）
- 详情页直接删除
- 批量选图添加
- 日历里的穿着记录，以及筛选
- 衣服类型分类模型
- 云同步、Android / iOS
