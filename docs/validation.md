# 验证记录

以下为 0.1.0 的历史记录，APK 生成目录现已被新版覆盖。当前 0.1.1 的证据见 [A 版爱心验证记录](validation-heart-rings.md)。

2026-10-04，在此 Windows 项目目录实施。保留 minimal-sleep 源码，复用其 JDK 17、Gradle 8.13、API 36、Build Tools 35.0.0 和 Maven 缓存；ADB 复用 `D:/soft/platform-tools`。

## Flutter

25 项测试通过：参数校验、60Hz / 120Hz 时间推进、暂停和前后台切换、几何覆盖与横竖屏重算、实际像素颜色、全屏控件与返回顺序、平台调用失败退出、防抖保存、延迟写入、异常重试及应用重建恢复设置。

几何、绘制、页面和存储均先观察缺失实现导致的测试失败，再实现并通过。390×844 的实际应用入口测试发现标题溢出，已调整为可伸缩标题，并再次通过。PNG 使用本机字体做视觉检查，未将 Windows 字体打包到应用。

固定帧位于忽略目录 `.tools/previews/spiral.png`、`hearts.png`、`player.png`，已人工查看。它们来自 Flutter 测试渲染器，不能代替手机上的截图或性能测量。

## Android 构建

初次离线诊断缺少 Flutter Gradle 插件的 kotlin-dsl 5.2.0 与其他 Flutter 专用 Maven 依赖。只在确认缺项后联网解析，保留已有共享缓存。Google Maven 主地址的 TLS 握手在 Java / Python 直连及现有代理下均超时；官方 `dl-ssl.google.com/android/maven2` 可访问。`tools/Google-Maven.init.gradle` 仅将 Google 仓库改到该官方端点，覆盖 Flutter included build，所有版本不变。

Kotlin 2.3.21 拒绝 Flutter 模板旧的 `android.kotlinOptions.jvmTarget`，已按 [Kotlin 官方 compilerOptions 说明](https://kotlinlang.org/docs/gradle-compiler-options.html) 改为类型化 `JvmTarget.JVM_17`。

构建随后确认需要 NDK 28.2.13676358。现有共享 SDK 与常见用户 SDK 目录均没有该 NDK；官方清单的 Windows ZIP 为 748118221 字节，SHA-1 `086bba43ff2f5eb0e387b15c8278bb4e0d89ba1d`，核验后安装到项目 SDK 视图的 `ndk/28.2.13676358`。未重装 JDK、Gradle、API 36、Build Tools 或 ADB。

构建进一步确认缺 CMake 3.22.1；PATH 与常见安装目录未发现可复用版本。官方 Windows ZIP 为 16116742 字节，SHA-1 `292778f32a7d5183e1c49c7897b870653f2d2c1b`，核验后安装到项目 SDK 视图 `cmake/3.22.1`。Flutter 3.41 的 NDK 预检使用空 CMake 工程，因而该组件也被实际构建要求。

Flutter 的编译阶段会重写 local.properties，使 Windows 盘符冒号再次未转义，触发 Lint PropertyEscape；应用 Gradle 在 Flutter 编译后、Lint 读取前规范化此生成文件，没有关闭 Lint 检查。

Flutter 默认根工程未声明三个验收任务，裸任务名会同时选择应用和发布插件的开发测试。首次运行插件自带的 38 项 Robolectric 测试，其中 12 项 DataStore 测试因 Windows `File.renameTo` 不能覆盖已存在文件而失败，另外 26 项通过；这是插件测试运行于 Windows 文件系统的结果，不能用它宣称手机存储已经验证。错误与 [Android DataStore 官方问题记录](https://issuetracker.google.com/issues/203087070) 相符。

构建脚本使用明确的 `:app:lintDebug :app:testDebugUnitTest :app:assembleDebug` 入口，验收本应用。第三方插件测试未被篡改，其失败记录保留；应用存储由 Dart 测试及后续授权的手机测试验证。`:app:testDebugUnitTest` 为 NO-SOURCE，不作为测试通过数量。

审查修复后的应用离线构建通过：`BUILD SUCCESSFUL in 16s`，111 项 Gradle task（16 executed / 95 up-to-date），Lint 无错误或警告。格式检查 20 个 Dart 文件无变化，`flutter analyze --no-pub` 无问题，完整 Flutter 测试 25/25 通过。统一入口为 `tools/Verify.ps1`。首次在沙箱内运行时，Gradle 不能加载共享缓存的 native-platform.dll；在已授权的共享目录访问权限下重新构建成功，没有重新下载 Gradle。

APK：`E:/develop/github/HypnoLoop/build/app/outputs/flutter-apk/app-debug.apk`，161553416 字节（约 154 MiB）；SHA-256 `89A1E9F449B9CB58D27963DB2D2B9A706CD3091979112F1D723BF55939AAADC4`。包名 `com.hypnoloop.app`，0.1.0 / versionCode 1，minSdk 24、targetSdk 36，arm64-v8a / armeabi-v7a / x86_64。

`apksigner verify --verbose --print-certs` 通过，v2 签名；标准 Android Debug 证书 SHA-256 `2e8842e7b6e160dca61f484b7fe7876f603dda6b755da9206672450755d7df94`。debug Manifest 包含 Flutter 调试需要的 INTERNET 权限；应用业务没有联网代码，release 主 Manifest 没有声明该权限。当前交付只核验 debug APK。

## 独立审查与修复

完成一次独立代码审查（基础提交 8ac48c6，审查时 HEAD cbe6891），发现三个 Important 问题，无 Critical 或 deferred minor。先写复现测试，三个测试均观察到失败，再做一次修复并通过完整 25 项测试，没有重复派发审查。

- 全屏设置滑块触发构建期间通知异常：设置事件立即同步面板，外部更新在帧完成后同步。测试 `fullscreen sliders update the open sheet without build exceptions` RED→GREEN。
- RGB 对话框旋转到横屏后内容溢出：内容改为可滚动。测试 `RGB dialog stays scrollable when rotated to landscape` RED→GREEN。
- 较稀疏的爱心层在四秒边界提前消失，导致边缘变色：保留比例为 1 的外层，层数仍有上限。测试 `sparse heart layers keep edge colors continuous across a birth boundary` RED→GREEN。

## 真机验证

用户明确授权安装与测试。Xiaomi 23127PN0CC（houji），Android 16 / API 36，1200×2670，120Hz。ADB 安装新版返回 Success；最终换回 debug 包后，手机 `/data/app/.../base.apk` 的 SHA-256 与以上文件完全一致。

- 螺旋、爱心及紫黑／粉紫预设显示正常；预览与全屏均查看实际截图。
- 全屏截图没有状态栏与导航栏；单击可呼出三个控件，闲置后隐藏。播放窗口有 `KEEP_SCREEN_ON`，暂停与后台窗口没有该标志。
- 全屏设置速度从 0.5× 调到显示为 1.0×，没有构建异常；RGB 对话框打开时切到横屏，能够滚动到蓝色滑块并完成。测试后恢复原屏幕旋转设置（自动旋转 0、user_rotation 0）。
- 系统返回先关闭设置；从屏幕左边缘执行返回手势后回到预览。
- 暂停后切后台再回来仍显示「继续」，预览画布像素 SHA-256 一致：`13b39eb07d65a542e3f514322d67414d1ec17acf49d13c7a43b2e52eb949298d`，比较区域 `(80,390)-(1120,1240)`。
- 强制停止进程、重新冷启动后仍为爱心模式，速度显示 1.0×；实际 DataStore 文件 `FlutterSharedPreferences.preferences_pb` 已创建。短暂关闭 Wi-Fi 与移动数据（系统状态均为 0）后冷启动同样显示画面并恢复设置；网络状态随后恢复到测试前值。
- 最终启动进程的 Flutter / AndroidRuntime 日志未检出 Exception、Error、overflow 或 FATAL。最终停在暂停的预览页，解除常亮。

截图与窗口证据在忽略目录 `.tools/previews/device-*.png`、`device-window-*.txt`。测试中曾因用户切到其他应用而中断，随后增加每次操作前的应用焦点检查，再继续验证。

## 短时性能采样

profile 构建首次离线报告 Flutter profile 专用 Android 依赖未缓存；只解析实际缺项后恢复离线构建：`:app:assembleProfile` `BUILD SUCCESSFUL in 12s`，76 tasks。没有替换已有 JDK、Gradle 或 SDK 版本。

临时安装 profile APK，启用 Dart / Embedder VM timeline，Impeller Vulkan 后端。分别在竖屏全屏、速度显示 1.0× 时采样约 8 秒；螺旋为默认 4 条纹／疏密 3，爱心扩散间隔 1 秒。按时间线的 `Frame` 与 `GPURasterizer::Draw` begin/end 事件计算耗时。

| 动画 | UI / Raster 帧数 | UI P95 / 最大（ms） | Raster P95 / 最大（ms） |
| --- | --- | --- | --- |
| 螺旋 | 964 / 963 | 0.943 / 2.830 | 2.419 / 3.430 |
| 爱心 | 963 / 963 | 1.186 / 2.959 | 2.430 / 4.198 |

本次两个阶段的样本均未超过 8.33ms；这不能证明实际呈现从不掉帧，也不代表持续使用、极端参数或其他设备表现。原始时间线保留在 `.tools/previews/device-spiral-profile-timeline.json` 与 `device-hearts-profile-timeline.json`。采样后移除临时 ADB 转发，并重新安装以上 debug APK。

iOS / 桌面尚未构建；正式发布签名与长时间性能测试仍属后续工作。实施取舍记录见 [执行记录](execution-record.md)。
