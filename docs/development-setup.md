# HypnoLoop 开发环境核验

核验日期：2026-10-04。已创建并测试 Flutter 应用；Android 实际构建结果见 [验证记录](validation.md)。复用现有工具，按实际构建缺项补充 Flutter、应用依赖及 NDK；未修改 minimal-sleep 源码。

## 已验证的可复用工具

| 工具 | 位置 | 核验结果 |
| --- | --- | --- |
| JDK | `E:\develop\github\minimal-sleep\.tools\jdk\jdk17.0.20_10` | `java -version`：17.0.20.1，Corretto |
| Android SDK | `E:\develop\github\minimal-sleep\.tools\android-sdk-ready` | Platform API 36，平台修订版 2；Build Tools 35.0.0 |
| Gradle | `E:\develop\github\minimal-sleep\.tools\gradle\gradle-8.13` | 使用上述 JDK 成功执行离线 `--version`，版本 8.13 |
| Gradle 缓存 | `E:\develop\github\minimal-sleep\.tools\gradle-home` | 存在 Gradle 8.13 缓存和 Maven 模块缓存 |
| ADB | `D:\soft\platform-tools\adb.exe` | `adb version`：Platform Tools 36.0.0 |
| Python | `D:\Develop\Python\python.exe` | 已用于官方 SDK 清单读取、NDK 下载和校验 |

缓存中已确认存在以下版本目录：AGP 8.13.2、Kotlin Gradle Plugin 2.3.21、Compose Compiler Gradle Plugin 2.3.21、Compose BOM 2026.05.00。存在缓存不等于新 Flutter 应用的所有依赖都已缓存，需以后用真实项目验证。

Gradle `--version` 输出的 Kotlin 2.0.21 是 Gradle 自带的 Kotlin，不能把它误认为项目的 Kotlin Android 插件版本。

Android 官方 AGP 8.13 文档列出的要求为 Gradle 8.13、JDK 17 和 Build Tools 35.0.0，支持 API 36；AGP 8.13.2 增加了 Kotlin 2.3 支持。这组工具符合 Android 层的版本要求。它们与最终选定的 Flutter SDK、Flutter 插件的兼容性仍需构建验证。

来源：[Android 官方 AGP 8.13 兼容说明](https://developer.android.com/build/releases/agp-8-13-0-release-notes)。

## 参考项目的实际要求与差异

参考：[Stand404/HypnosisAPP-New](https://github.com/Stand404/HypnosisAPP-New)。本次读取 main 的配置与两种动画源码，并用 `git ls-remote` 得到 main 提交 `a40eb29d35354f9b3be2be5c53fe922a07ebe53c`。

| 配置 | 参考项目实际值 | 对 HypnoLoop 的影响 |
| --- | --- | --- |
| Dart | `^3.10.7` | 整体复用原项目时需要对应 Dart 版本的 Flutter SDK；新项目应根据选定 SDK 声明版本 |
| AGP | 8.11.1 | 当前缓存已核验的是 8.13.2，不能假设参考项目可以直接离线构建 |
| Kotlin Android | 2.2.20 | 当前缓存已核验的是 2.3.21 |
| Java 编译与 Kotlin toolchain | 21 | 原配置不能直接使用现有 JDK 17；新项目建议明确使用 Java 17 |
| Gradle Wrapper | `file:///D:/env/gradle-8.14-all.zip` | 作者机器上的绝对路径；新项目应记录公开的 Gradle 8.13 分发地址及校验值 |
| Android SDK / NDK | 来自 Flutter SDK 的默认版本 | 选定 Flutter 后再核对，不提前下载新 SDK 或 NDK |
| Debug 签名 | 使用 release signingConfig，密钥来自 local.properties | 不适合直接沿用；新项目调试包应使用标准 debug 签名 |

源码依据：

- [pubspec.yaml](https://github.com/Stand404/HypnosisAPP-New/blob/a40eb29d35354f9b3be2be5c53fe922a07ebe53c/pubspec.yaml)
- [settings.gradle.kts](https://github.com/Stand404/HypnosisAPP-New/blob/a40eb29d35354f9b3be2be5c53fe922a07ebe53c/android/settings.gradle.kts)
- [app/build.gradle.kts](https://github.com/Stand404/HypnosisAPP-New/blob/a40eb29d35354f9b3be2be5c53fe922a07ebe53c/android/app/build.gradle.kts)
- [gradle-wrapper.properties](https://github.com/Stand404/HypnosisAPP-New/blob/a40eb29d35354f9b3be2be5c53fe922a07ebe53c/android/gradle/wrapper/gradle-wrapper.properties)

建议建立精简的 Flutter 项目，借鉴两种动画的绘制思路，按现有工具重新配置 Android 构建，而不是整体照搬参考项目的构建文件。Flutter 界面无需引入 Compose 插件和 Compose BOM。

## 尚未找到的组件

没有在 PATH、相关环境变量，以及以下位置找到 `flutter.bat` 或 Flutter 内的 `dart.exe`：`E:\develop`、`D:\Develop`、`D:\soft`、`C:\src`、`E:\src`、`E:\tools`、`C:\tools`、`C:\flutter`、`D:\flutter`、`E:\flutter`、用户 development、fvm、scoop Flutter 目录和本地 Pub Cache 等常见位置。此结论限定于已检查位置，不代表已扫描整台电脑。

现有 Android SDK 顶层只有 `platforms` 和 `build-tools`，未发现 cmdline-tools、licenses、platform-tools 或 NDK。独立 ADB 已可用，无需为 ADB 再安装一份 platform-tools。其他组件是否必需，由选定 Flutter SDK 和实际构建诊断决定。

Flutter SDK 的 Windows 官方发行清单请求本次返回 NoSuchKey。随后改用官方 GitHub 稳定版本标签获取 SDK，未依据发行计划猜测下载地址。

## 已补充的 Flutter SDK

用户确认使用 Flutter 后，比较了官方 3.47.5、3.41.5、3.38.9 标签的 Android 配置与版本校验。3.47.5 的最低 Gradle 要求为 8.14，不能直接复用现有 8.13；3.41.5 的最低 Gradle 要求为 8.3、警告阈值为 8.7，接受现有工具组合。因此固定 3.41.5，不升级共享 Android 工具。

通过官方仓库浅克隆 3.41.5 标签到 `E:\develop\github\HypnoLoop\.tools\flutter`，并成功运行 `flutter --version --machine`：

- Flutter：3.41.5，framework commit `2c9eb20739dfec95e2c74bd3dfa4601b0a8a36aa`。
- Dart：3.11.3。
- Engine：`052f31d115eceda8cbff1b3481fcde4330c4ae12`。
- 初始化下载了 SDK 必需的 Dart 和 Flutter 命令行工具依赖，Pub Cache 指向项目 `.tools/pub-cache`。
- 固定标签检出属于 detached HEAD，命令显示 channel 为 `[user-branch]`，不意味着使用开发分支；以后通过明确版本升级，不执行隐式 `flutter upgrade`。
- 已补充 Android 引擎缓存、shared_preferences 2.5.5 及其传递依赖。iOS 与桌面发布引擎未预下载。
- 实际构建确认缺少 NDK 28.2.13676358；校验官方 ZIP 后安装到本项目 `.tools/android-sdk/ndk/28.2.13676358`，没有重装既有 SDK 平台或 Build Tools，也未下载不需要的 cmdline-tools。

## 项目 SDK 视图与构建入口

`tools/Build-Android.ps1` 建立本地 `.tools/android-sdk/` 视图：`platforms`、`build-tools` 的 junction 指向共享 SDK，`platform-tools` 指向独立 ADB 目录；NDK 单独位于此视图内。`android/local.properties` 和 Pub Cache 只指向本项目忽略目录。不要递归删除指向共享工具的 junction 目标。

```powershell
. .\tools\Build-Android.ps1 -PrepareOnly
& .\.tools\flutter\bin\flutter.bat analyze --no-pub
& .\.tools\flutter\bin\flutter.bat test --no-pub
& .\tools\Build-Android.ps1
```

最后一条默认执行离线 `:app:lintDebug :app:testDebugUnitTest :app:assembleDebug`，直接使用已安装 Gradle 8.13。任务明确指向应用，以免 Gradle 的裸任务选择器同时运行发布插件的开发测试；具体 Windows 插件测试限制见验证记录。仅在日志报告缺项后加 `-Online`。

本机 Google Maven 主地址超时，Google 官方备用端点 `https://dl-ssl.google.com/android/maven2/` 已实测可访问。脚本通过 `Google-Maven.init.gradle` 应用于主工程及 Flutter included build，版本不变。在线构建读取 Windows 现有无凭据 HTTP 代理，或使用 `-NetworkProxy`；离线构建不设置网络代理。无本地 Maven relay、无 `MINIMAL_SLEEP_MAVEN_PROXY`。

Flutter 的 included build 和 shared_preferences 的 Android 插件声明自己的构建 classpath（例如 AGP 8.11.1 / 8.13.1、Kotlin 1.8.0 / 2.3.0）。这些缺失 Maven 工件由依赖解析补齐，应用仍使用 AGP 8.13.2 与 Kotlin 2.3.21。模板已从旧 kotlinOptions 迁移到 compilerOptions，Java / Kotlin 目标均为 17。

核验源码：[3.41.5 版本校验](https://github.com/flutter/flutter/blob/3.41.5/packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt)、[3.47.5 版本校验](https://github.com/flutter/flutter/blob/3.47.5/packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt)。

## 后续构建规则

1. 仅在 HypnoLoop 内建立源码和构建输出，保留 minimal-sleep 的源码和共享工具缓存。
2. 先核验并固定 Flutter 稳定版，以及它的 Dart、Android SDK、NDK 和 Java 要求。
3. Flutter SDK、Pub Cache 和本项目临时产物可放在 HypnoLoop 的 `.tools/` 等忽略目录；避免写入其他项目的源码目录。
4. 尝试使用 AGP 8.13.2、Kotlin Android 2.3.21、Gradle 8.13、Java 17、compileSdk 36、Build Tools 35.0.0。若 Flutter 插件验证或真实构建报告冲突，再针对冲突处理。
5. 先做离线依赖解析和离线构建；只有日志明确缺少的 Pub/Maven/SDK 组件才联网补充，再恢复离线验证。
6. 不设置 `MINIMAL_SLEEP_MAVEN_PROXY`。
7. 使用已安装的 Gradle，避免 Wrapper 重复下载；仍在 Git 中保存正确的 Wrapper 版本声明。
8. Flutter Android 项目通常从 `android/` 目录调用 Gradle；Dart 编译由 Flutter 工具参与。原生 Android 的 `testDebugUnitTest` 不能代替 `flutter test`。
9. 工具、缓存、local.properties、签名文件和 APK 保持在 Git 之外。共享目录若受沙箱写入限制，应申请该具体操作的访问权限，不能把权限失败当作组件缺失。

后续命令沿用以下会话环境，不改系统级环境变量：

```powershell
$env:JAVA_HOME = 'E:\develop\github\minimal-sleep\.tools\jdk\jdk17.0.20_10'
$env:ANDROID_HOME = 'E:\develop\github\minimal-sleep\.tools\android-sdk-ready'
$env:GRADLE_USER_HOME = 'E:\develop\github\minimal-sleep\.tools\gradle-home'
$env:Path = "$env:JAVA_HOME\bin;D:\soft\platform-tools;$env:Path"
```

iOS 是下一阶段；本机 Windows 可继续开发共享 Dart 代码，实际 iOS 构建和签名需要 macOS 与 Xcode。[Flutter 官方说明](https://docs.flutter.dev/deployment/ios)。
