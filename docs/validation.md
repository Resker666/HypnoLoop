# 验证记录

2026-10-04，在此 Windows 项目目录实施。保留 minimal-sleep 源码，复用其 JDK 17、Gradle 8.13、API 36、Build Tools 35.0.0 和 Maven 缓存；ADB 复用 `D:/soft/platform-tools`。

## Flutter

22 项测试通过：参数校验、60Hz / 120Hz 时间推进、暂停和前后台切换、几何覆盖与横竖屏重算、实际像素颜色、全屏控件与返回顺序、平台调用失败退出、防抖保存、延迟写入、异常重试及应用重建恢复设置。

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

最终应用离线构建通过：`BUILD SUCCESSFUL in 23s`，111 项 Gradle task，Lint 报告 `No issues found.`。格式检查 19 个 Dart 文件无变化，`flutter analyze --no-pub` 无问题，完整 Flutter 测试 22/22 通过。统一入口为 `tools/Verify.ps1`。

APK：`E:/develop/github/HypnoLoop/build/app/outputs/flutter-apk/app-debug.apk`，146970487 字节（约 140 MiB）；SHA-256 `C1556D7D8AD3C08988BDB05D68A68EA33677D89FDC3C7589BD56C7F90D8041B4`。包名 `com.hypnoloop.app`，0.1.0 / versionCode 1，minSdk 24、targetSdk 36，arm64-v8a / armeabi-v7a / x86_64。

`apksigner verify --verbose --print-certs` 通过，v2 签名；标准 Android Debug 证书 SHA-256 `2e8842e7b6e160dca61f484b7fe7876f603dda6b755da9206672450755d7df94`。debug Manifest 包含 Flutter 调试需要的 INTERNET 权限；应用业务没有联网代码，release 主 Manifest 没有声明该权限。当前交付只核验 debug APK。

## 设备边界

ADB 只读检测到 Xiaomi 23127PN0CC（houji），API 36。当前尚未安装此应用；全屏系统栏、系统返回手势、常亮、离线实机恢复设置和帧耗时尚未实测。不宣称稳定 60fps。iOS / 桌面尚未构建。
