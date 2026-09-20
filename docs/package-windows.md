# 打包给另一台 Windows 电脑

不需要在对方电脑上装 Flutter、VS 或本仓库。拷贝发行目录（或 zip）即可。

## 现成包

本机已打好：

- 目录：`E:\wardrobe\dist\wardrobe-windows\`
- 压缩包：`E:\wardrobe\dist\wardrobe-windows.zip`（约 13 MB）

把 **整个文件夹** 或 zip 解压后的全部内容拷到 U 盘 / 网盘，发到另一台电脑。双击 `wardrobe.exe`。

不要只拷 `wardrobe.exe`。同级必须有：

- `flutter_windows.dll`
- `sqlite3.dll`
- `onnxruntime.dll`（以及同级的 `onnxruntime_providers_shared.dll`，若有）
- `data\`（资源与 AOT 库，含抠图模型）

## 对方电脑要求

- Windows 10 或 11，**64 位**
- 第一次打不开、提示缺 `VCRUNTIME140.dll` / `MSVCP140.dll` 时，安装 [Visual C++ 可再发行组件（x64）](https://learn.microsoft.com/zh-cn/cpp/windows/latest-supported-vc-redist)

数据仍写在那台电脑的 `%APPDATA%\wardrobe\`，和开发机数据不共用。

## 以后自己再打一次

开发机项目根目录：

```powershell
$env:PUB_HOSTED_URL = "https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL = "https://storage.flutter-io.cn"
flutter build windows --release
```

产物在 `build\windows\x64\runner\Release\`。可整夹复制，或打 zip：

```powershell
Compress-Archive -Path "build\windows\x64\runner\Release\*" -DestinationPath "dist\wardrobe-windows.zip" -Force
```
