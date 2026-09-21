# Run on Windows

本机 Flutter：`D:\Environment\flutter`

## 启动

在项目根目录 `E:\wardrobe` 打开 PowerShell：

```powershell
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
flutter run -d windows
```

停应用：终端里按 `q`，或关掉衣橱窗口。

热重载：终端聚焦时按 `r`；热重启按 `R`。

## 找不到 flutter

新终端如果提示无法识别 `flutter`，先加 PATH 再跑：

```powershell
$env:PATH = "D:\Environment\flutter\bin;" + $env:PATH
```

或不改 PATH，直接用完整路径：

```powershell
D:\Environment\flutter\bin\flutter.bat run -d windows
```

改过用户 PATH 之后，必须**新开一个终端**才会生效。当前窗口还是旧环境。

## 一直卡在 Downloading packages

没设上面两条镜像时，`flutter` 会直连 `pub.dev`，国内经常很慢。

两条 `$env:...` 只对**当前 PowerShell**有效。想长期生效，可在 Windows 用户环境变量里加上：

| 变量 | 值 |
|---|---|
| `PUB_HOSTED_URL` | `https://pub.flutter-io.cn` |
| `FLUTTER_STORAGE_BASE_URL` | `https://storage.flutter-io.cn` |

设完同样要新开终端。

## 数据目录

本地库和图片在 `%APPDATA%\wardrobe\`。v2.2 的库是 schema 6，改过表结构后必须完全关掉窗口再开，热重载不够。抠图、精修和吊牌 OCR 模型会拷到 `%APPDATA%\wardrobe\models\`。

## 发给另一台电脑

`flutter build windows --release` 后拷贝整个 `build\windows\x64\runner\Release\`（或 `dist\wardrobe-windows.zip`）。说明见 [package-windows.md](package-windows.md)。
