# HypnoLoop

Flutter 开发的个人视觉小工具。首版面向 Android：全屏旋转螺旋、向外扩散的爱心，没有账号和后端。

## 使用

启动后预览效果，选择螺旋或爱心、配色、速度及形状参数，再点「开始全屏」。轻点全屏画面显示暂停、设置和退出按钮；无操作三秒后隐藏。返回先关闭设置，再退出全屏。

支持黑白、紫黑和粉紫预设，以及 RGB 调色。设置自动保存到手机本地；切后台时停止动画，返回前台保持之前的播放或暂停状态。

## 本机开发

使用 PowerShell，在项目根目录运行：

```powershell
. .\tools\Build-Android.ps1 -PrepareOnly
& .\.tools\flutter\bin\flutter.bat test --no-pub
& .\.tools\flutter\bin\flutter.bat analyze --no-pub
& .\tools\Build-Android.ps1
```

构建脚本默认离线，直接调用已有 Gradle 8.13。日志确认缺依赖时再加 `-Online`；它使用 Windows 已配置的代理，或显式 `-NetworkProxy http://127.0.0.1:7897`。Google Maven 使用官方备用下载端点，未设置 `MINIMAL_SLEEP_MAVEN_PROXY`。

完整验收可运行 `& .\tools\Verify.ps1`。已生成的 [Android 调试 APK](build/app/outputs/flutter-apk/app-debug.apk) 位于忽略目录，约 154 MiB，包含三个 ABI；文件只在本机存在。已在 Xiaomi 23127PN0CC（Android 16 / API 36）安装并验证主要操作，具体证据见验证记录。

运行到已授权的测试手机：先确认 `adb devices` 的设备 ID，再执行 `flutter run -d <设备ID>`。构建入口及共享工具的完整路径见 [环境文档](docs/development-setup.md)。

固定版本：Flutter 3.41.5 / Dart 3.11.3、AGP 8.13.2、Kotlin Android 2.3.21、Java 17、Gradle 8.13、compileSdk / targetSdk 36、Build Tools 35.0.0、minSdk 24、NDK 28.2.13676358、shared_preferences 2.5.5。Wrapper properties 记录 8.13 与 SHA-256；此机器直接复用安装版 Gradle。

## 平台与维护

当前工程只生成 Android 平台目录。动画、界面和设置存储都在 Dart 中；全屏和常亮的 Android 实现在一个小平台通道里。

iOS 为下一阶段，需要 Mac、Xcode 和 iOS 显示适配。Windows 等桌面平台为后续阶段，需要生成对应宿主工程并实现显示适配、键鼠操作和实机验证。现阶段未宣称 iOS 或桌面已经适配。

SDK、依赖缓存、签名和 APK 不进入 Git。调试 APK 使用本机标准 debug 签名，供个人测试；正式分发前需要单独配置发布签名。

测试范围与产物记录见 [验证记录](docs/validation.md)。参考项目来源和 MIT 许可见 [第三方声明](THIRD_PARTY_NOTICES.md)。
