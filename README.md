# HypnoLoop

Flutter 开发的个人视觉小工具。当前版本 0.1.2，面向 Android：全屏旋转螺旋、向外移动的等距爱心环，支持四款桌面图标切换，没有账号和后端。

## 使用

启动后预览效果，选择螺旋或爱心、配色、速度及形状参数，再点「开始全屏」。轻点全屏画面显示暂停、设置和退出按钮；无操作三秒后隐藏。返回先关闭设置，再退出全屏。

支持黑白、紫黑和粉白预设，以及 RGB 调色。粉白为用户选定的 A 版效果：中心白色爱心保持清晰，亮粉色等距环向外移动，外圈逐渐变圆。选择粉白预设后，默认 0.5 倍速度下每 3 秒循环一次；仍可调节速度、扩散间隔及三种颜色。

设置自动保存到手机本地；切后台时停止动画，返回前台保持之前的播放或暂停状态。已保存的旧粉紫爱心预设会自动升级配色，保留速度、间隔等参数；自定义颜色不被替换。

向下滚动设置区可找到「桌面图标」，选择 A 粉白爱心环、B 渐变爱心旋涡、C 黑白螺旋爱心或 D 紫粉双环爱心。「恢复默认」切换回 B。当前选择由 Android 实际启用的入口读取，应用重开及覆盖安装后保留；桌面刷新可能需要片刻。此版本提供内置图标选择。

## 本机开发

使用 PowerShell，在项目根目录运行：

```powershell
. .\tools\Build-Android.ps1 -PrepareOnly
& .\.tools\flutter\bin\flutter.bat test --no-pub
& .\.tools\flutter\bin\flutter.bat analyze --no-pub
& .\tools\Build-Android.ps1
```

构建脚本默认离线，直接调用已有 Gradle 8.13。日志确认缺依赖时再加 `-Online`；它使用 Windows 已配置的代理，或显式 `-NetworkProxy http://127.0.0.1:7897`。Google Maven 使用官方备用下载端点，未设置 `MINIMAL_SLEEP_MAVEN_PROXY`。

完整验收可运行 `& .\tools\Verify.ps1`。已生成的 [Android 调试 APK](build/app/outputs/flutter-apk/app-debug.apk) 位于忽略目录，约 163 MiB，包含三个 ABI；文件只在本机存在。已在 Xiaomi 23127PN0CC（Android 16 / API 36）安装，具体版本与测试证据见验证记录。

运行到已授权的测试手机：`& .\tools\Run-Android.ps1 -DeviceId <设备ID>`，默认离线构建、安装并打开；已有最新 APK 时加 `-SkipBuild`，需要热重载时加 `-Attach`。脚本通过始终启用的 MainActivity 启动，避免 Flutter 3.41 在非默认图标下选择已禁用的 B 入口。构建入口及共享工具的完整路径见 [环境文档](docs/development-setup.md)。

固定版本：Flutter 3.41.5 / Dart 3.11.3、AGP 8.13.2、Kotlin Android 2.3.21、Java 17、Gradle 8.13、compileSdk / targetSdk 36、Build Tools 35.0.0、minSdk 24、NDK 28.2.13676358、shared_preferences 2.5.5。Wrapper properties 记录 8.13 与 SHA-256；此机器直接复用安装版 Gradle。

## 平台与维护

当前工程只生成 Android 平台目录。动画、界面和设置存储都在 Dart 中；全屏／常亮与桌面图标各使用一个小平台通道。四款原图位于 [assets/launcher_icons](assets/launcher_icons)，Flutter 直接预览，Gradle 从同一源图生成 Android 资源。Android 26 及以上使用自适应图标，24／25 使用位图回退。

iOS 为下一阶段，需要 Mac、Xcode 和 iOS 显示适配。Windows 等桌面平台为后续阶段，需要生成对应宿主工程并实现显示适配、键鼠操作和实机验证。现阶段未宣称 iOS 或桌面已经适配。

SDK、依赖缓存、签名和 APK 不进入 Git。调试 APK 使用本机标准 debug 签名，供个人测试；正式分发前需要单独配置发布签名。

当前图标切换的测试与产物记录见 [0.1.2 验证记录](docs/validation-launcher-icons.md)；[A 版爱心记录](docs/validation-heart-rings.md) 和 [首版记录](docs/validation.md) 保留历史证据。参考项目来源和 MIT 许可见 [第三方声明](THIRD_PARTY_NOTICES.md)。
