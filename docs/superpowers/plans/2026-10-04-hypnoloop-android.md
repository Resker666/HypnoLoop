# HypnoLoop Android Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 交付可安装的 Android 螺旋／爱心全屏工具，并保留以后适配 iOS 和电脑的共享绘制、界面及设置代码。

**Architecture:** Flutter Canvas 自绘两种动画，以单调时间驱动播放。界面、参数与设置存储使用 Dart；Android 全屏和常亮通过一个平台通道实现。先实现 Android，不将未构建的平台宣称为已适配。

**Tech Stack:** Flutter 3.41.5（`2c9eb20739dfec95e2c74bd3dfa4601b0a8a36aa`）、SDK 自带 Dart、shared_preferences 2.5.5、AGP 8.13.2、Kotlin Android 2.3.21、Gradle 8.13、Java 17、compileSdk / targetSdk 36、Build Tools 35.0.0、minSdk 24。

**Spec:** [首版设计](../specs/2026-10-04-hypnoloop-design.md)。环境路径与核验依据见 [开发环境](../../development-setup.md)。用户选择 Flutter 并授权当前对话依次实施。Tasks 1–4 已完成，Task 5 的离线构建已通过，独立审查进行中；手机安装测试等待授权。

## Global Constraints

- 第一阶段在 Android 手机上使用，之后适配 iOS 手机，最后适配电脑。首版是纯螺旋／爱心的全屏工具。
- 速度 0.1–2.0 倍，默认 0.5 倍；螺旋条纹数 2–8、默认 4；疏密 1–5、默认 3；顺时针默认开启。
- 1 倍时螺旋每 12 秒旋转一周，爱心从中心扩散到覆盖画布对角线半径用 4 秒；扩散间隔 0.4–2.0 秒、默认 1.0 秒，按动画时间计。
- 中心爱心默认关闭，开启时大小为短边 10%，可调范围 5%–20%。三个配色为黑白螺旋、紫黑螺旋、粉紫爱心。
- 全屏单击显示工具栏，三秒无操作隐藏；打开设置时不自动隐藏。返回顺序为关闭设置、退出全屏、正常应用返回。
- 后台停止动画，不把后台时间计入动画时钟；暂停、后台和离开播放器时解除屏幕常亮。
- 首版只保存最后参数；无账号、后端、图片、文字、音频、导入导出、角色或剧情。
- 仅下载实际缺少的组件，不修改 minimal-sleep 源码；工具、缓存、local.properties、签名文件和 APK 保持在 Git 之外。
- 固定 Flutter 3.41.5 与上述 Android 版本，保留 Wrapper 8.13 声明，实际构建直接调用已有 Gradle；不设置 MINIMAL_SLEEP_MAVEN_PROXY。
- 不降低 targetSdk 掩盖系统栏问题，平台功能须按 Android 设备实际验证。借鉴源码时保留原 MIT 许可证及 `Copyright (c) 2026 Stand404`。

## Review Focus

1. 配置中的 NaN、无限值、错误类型或未知格式版本，应恢复合法默认配置而非导致启动失败；归属 Task 1 / 4。
2. 旋转及尺寸变更发生在设置面板打开时，应重算画布并保持控件可访问；归属 Task 2 / 3。
3. 暂停后切后台再回来，或播放时恢复前台，应保持用户选择且无时间跳变；归属 Task 1 / 3。
4. 持久化写入延迟或失败，旧请求不能覆盖较新的设置，动画继续工作并报告失败；归属 Task 4。
5. Android API 36 的系统手势／焦点切换，以及平台通道调用失败，不得使退出按钮失效或遗留常亮；归属 Task 3 / 5。

## File Structure

所有下列路径均相对项目根目录；`.tools/` 为不提交的工具目录。

- `lib/main.dart`、`lib/app.dart`：应用启动、存储加载与主题；`pubspec.yaml` / `pubspec.lock`：最小依赖与锁定版本。
- `lib/features/player/settings.dart`：不可变参数、合法默认值、配色、版本化 JSON。
- `lib/features/player/playback_clock.dart`：时间推进、速度、用户播放状态与前后台状态。
- `lib/features/player/geometry.dart`：螺旋与爱心的形状、覆盖范围和扩散层计算。
- `lib/features/player/painters.dart`：CustomPainter、缓存几何、接收时钟重绘。
- `lib/features/player/player_page.dart`、`settings_panel.dart`：预览、播放、工具栏与滑块。
- `lib/features/player/settings_store.dart`、`settings_controller.dart`：Preferences 适配、防抖及顺序保存。
- `lib/platform/display_controller.dart`：平台通道与失败回退。
- `android/app/src/main/kotlin/com/hypnoloop/app/MainActivity.kt`：Android 系统栏、焦点恢复和常亮适配。
- `tools/Build-Android.ps1`：会话环境、已有 Gradle 与离线构建入口。
- `test/features/player/`、`test/platform/`：时间、参数、几何、存储和主要用户操作验证。
- `README.md`、`docs/validation.md`、`THIRD_PARTY_NOTICES.md`：运行说明、实际验证证据及来源声明。

## Task 1: 可测试的参数与播放时钟

**Files:** 创建 Flutter 工程文件、`settings.dart`、`playback_clock.dart`、`test/features/player/settings_test.dart`、`playback_clock_test.dart`、`.gitignore`、`tools/Build-Android.ps1`；更新环境文档。

**Interfaces:**
- 产生 `enum AnimationKind { spiral, hearts }`；`AppSettings.defaults()`、`AppSettings.fromJson(Map<String, dynamic>)`、`Map<String, dynamic> toJson()`。字段类型：`AnimationKind kind`；`double speed` / `density` / `heartIntervalSeconds` / `centerHeartFraction`；`int backgroundArgb` / `foregroundArgb` / `heartArgb` / `stripes`；`bool clockwise` / `showCenterHeart`。`AppSettings copyWith` 接受以上所有字段对应的 nullable 命名参数，未提供字段保持原值。
- 产生 `PlaybackClock extends ChangeNotifier`；`double get animationSeconds`、`bool get isPlaying`、`bool get isAdvancing`、`void advance(Duration delta)`、`void setPlaying(bool value)`、`void setForeground(bool value)`、`void setSpeed(double value)`。`isPlaying` 是用户选择，`isAdvancing` 还考虑前台状态。
- 构建脚本接受 `-Online` 开关，默认离线；工具路径默认使用已核验路径，可用参数替换，系统级环境变量不改动。

- [ ] 在实施开始时使用 worktree 技能检查当前目录；此处没有现成 Git 仓库，先以当前新项目目录初始化 Git 并忽略 `.tools/`、构建产物、local.properties、签名及 APK，不把 Flutter SDK 内的 Git 仓库加入项目。
- [ ] 使用固定 SDK 创建仅 Android 的 Flutter 工程，名称 `hypnoloop`，组织名 `com.hypnoloop`，`--no-pub`；保留现有 docs。设置 Android 版本及 Java 17，debug 使用标准调试签名，Wrapper 记录 8.13 分发 URL 和 SHA-256 `20f1b1176237254a6fc204d8434196fa11a4cfb387567519c61556e8710aed78`。
- [ ] 工具初始化只补 Flutter 必需的宿主测试和 Android 缓存；不预下载 iOS 或桌面发布组件。Pub 解析先离线，日志明确缺项后再联网补足。
- [ ] 若 Flutter 找不到独立 ADB，在项目 `.tools/android-sdk/` 建立 SDK 视图：`platforms`、`build-tools` junction 指向已有 SDK，`platform-tools` junction 指向 `D:/soft/platform-tools`；不复制或重下已有工具。只有实际构建需要时在该视图补 cmdline-tools、licenses 或 NDK，并记录实际目标路径。
- [ ] 先写失败测试：默认参数等于设计值；上下界被限制；非法值使用字段默认值；非当前 JSON 版本恢复整体默认值。测试包括错误 enum、非数字、NaN、无限值、非法颜色及损坏根结构。
- [ ] 先写失败时间测试，核心断言如下：

```dart
clock.advance(const Duration(seconds: 12));
expect(clock.animationSeconds, 6.0); // 默认 0.5 倍
clock.setPlaying(false);
clock.advance(const Duration(seconds: 30));
expect(clock.animationSeconds, 6.0);
clock.setForeground(false);
clock.setPlaying(true);
clock.advance(const Duration(seconds: 30));
expect(clock.animationSeconds, 6.0);
clock.setForeground(true);
clock.setSpeed(2.0);
clock.advance(const Duration(seconds: 1));
expect(clock.animationSeconds, 8.0);
```

- [ ] 运行 `flutter test test/features/player/settings_test.dart test/features/player/playback_clock_test.dart`，确认因模型／时钟未实现而失败；实现接口及验证逻辑。
- [ ] 补足 60Hz / 120Hz 等时长推进结果近似相等的测试，运行同一命令通过；以微秒误差容差比较累计时间，不要求浮点精确相等。
- [ ] 记录此时真实 Flutter／Dart 版本和工具补充项，提交本任务的源码、测试、构建配置与文档。

## Task 2: 两种自绘动画

**Files:** 创建 `geometry.dart`、`painters.dart`、`test/features/player/geometry_test.dart`、`painters_test.dart`、`THIRD_PARTY_NOTICES.md`。

**Interfaces:**
- 消费 Task 1 的设置和时钟。
- 产生 `double coverageRadius(Size size)`、`List<Path> buildSpiralPaths(Size size, int stripes, double density)`、`Path buildUnitHeartPath()`、`List<HeartLayer> heartLayers(double animationSeconds, double intervalSeconds)`；`HeartLayer` 包含 `double scale` 和 `int colorIndex`。
- 产生 `SpiralPainter({required AppSettings settings, required PlaybackClock clock})` 和 `HeartsPainter(...)`，由 `CustomPainter(repaint: clock)` 重绘，不让整个页面在每帧重建。

- [ ] 写失败几何测试：`coverageRadius(Size(300, 400)) >= 250`；条纹数 2 和 8、疏密 1 和 5 均产生有限且有覆盖范围的形状；零尺寸不异常；横竖屏交换后覆盖范围正确；心形路径闭合、左右对称且宽高非零。
- [ ] 写扩散时间测试：同一动画时间与间隔产生相同层；所有层的比例为有限非负值；4 秒基准扩散周期与 0.4–2.0 秒间隔不会无限生成层。
- [ ] 运行 `flutter test test/features/player/geometry_test.dart` 确認缺失实现导致失败，实现以上接口。以半对角线和边界余量计算覆盖范围，尺寸／形状参数改变时重建几何缓存；按从外到内顺序绘制爱心层。
- [ ] 写并运行 painter widget 测试，在固定时间绘制两种效果，验证无渲染异常、两种颜色出现及 resize 后画布铺满；人工查看固定帧 PNG，不能只依据 `shouldRepaint` 测试宣称视觉正确。
- [ ] 给螺旋应用顺／逆时针与 12 秒一周的相位，中心爱心按短边比例绘制；用最新设置重新创建 painter，沿用时钟相位。
- [ ] 两个测试文件通过后，保留实际借鉴的 MIT 来源声明并提交。

## Task 3: 播放操作与安卓显示适配

**Files:** 创建 `player_page.dart`、`settings_panel.dart`、`display_controller.dart`、`test/features/player/player_page_test.dart`、`test/platform/display_controller_test.dart`；实现 `main.dart` / `app.dart`、Android `MainActivity.kt` 和 Manifest 的应用名／权限配置。

**Interfaces:**
- 消费 Task 1 / 2；`PlayerPage({required AppSettings settings, required ValueChanged<AppSettings> onSettingsChanged, required Future<void> Function() onCommitSettings, required PlaybackClock clock, required DisplayController display})`。本任务由应用层的 ValueNotifier 保存内存设置，onCommitSettings 使用已完成 Future，Task 4 接入持久化，不提前依赖尚未存在的 SettingsController。
- 产生 `DisplayController`：`Future<void> apply({required bool fullscreen, required bool keepAwake})`、`Future<void> restore()`。通道为 `hypnoloop/display`，方法 `apply` 参数为 `fullscreen` / `keepAwake`；`restore` 恢复正常显示。
- `SettingsPanel` 消费 `AppSettings settings`、`ValueChanged<AppSettings> onChanged`、`VoidCallback onChangeEnd`，不拥有播放时钟。

- [ ] 写失败界面测试：切换两种动画、开始全屏、单击呼出控件、3 秒隐藏、设置打开时不隐藏、暂停／恢复，以及返回先关闭设置再退出全屏。
- [ ] 写 resize / 生命周期测试：面板打开时横竖尺寸改变没有溢出；暂停后后台再前台仍暂停；播放时后台不推进，恢复后按新时间差推进，不计入后台时长。
- [ ] 写平台通道测试，断言全屏播放为 `{fullscreen: true, keepAwake: true}`；暂停保留 fullscreen 并关闭常亮；离开播放器调用 restore；模拟 PlatformException 后仍能退出并显示简短失败提示。
- [ ] 运行 `flutter test test/features/player/player_page_test.dart test/platform/display_controller_test.dart` 确认失败，实现简体中文界面、可滚动设置面板及 Ticker 时间差适配。
- [ ] Android 使用 API 30+ 的 WindowInsetsController，API 24–29 使用兼容的窗口标志；常亮使用 FLAG_KEEP_SCREEN_ON。方法只接受合法布尔参数；onWindowFocusChanged 按当前请求恢复全屏，离开／暂停清除常亮。不引入 AndroidX 以外的新显示依赖。
- [ ] 默认进入预览，内置三种配色；颜色调节使用 Flutter 自带控件实现 RGB 滑块，不增加颜色选择器插件。保持暂停、退出按钮在 SafeArea 内。
- [ ] 上述测试通过后提交；真正隐藏系统栏及返回手势的效果由 Task 5 真机验证，mock 通道测试不能替代。

## Task 4: 最后参数的保存与恢复

**Files:** 创建 `settings_store.dart`、`settings_controller.dart`、`test/features/player/settings_controller_test.dart`；更新 `pubspec.yaml`、lockfile 和应用启动连接。

**Interfaces:**
- `abstract interface class SettingsStore { Future<String?> read(); Future<void> write(String value); }`；`PreferencesSettingsStore` 使用 `SharedPreferencesAsync`，唯一键为 `hypnoloop.settings.v1`。
- `SettingsController extends ChangeNotifier`：构造函数接收 `SettingsStore store`；`AppSettings get settings`、`bool get saveFailed`、`Future<void> load()`、`void update(AppSettings next, {bool commit = false})`、`Future<void> flush()`。实现 `dispose()` 清理定时器，页面关闭／后台事件先调用 flush。
- 序列化 JSON 包含 `schemaVersion: 1` 和所有 Task 1 字段；数值颜色为 32 位 ARGB。flush 顺序串行写入，200 毫秒防抖；新请求在旧写入期间到达时仍保证最终值是最新设置。

- [ ] 固定 `shared_preferences: 2.5.5`，先执行 `flutter pub get --offline`；确实缺项时获取缺失依赖后恢复离线解析，提交 lockfile。
- [ ] 写失败测试：load 缺值／损坏值使用默认值；字段合法配置完整往返；快速连续修改只保存最终配置；结束拖动立即 flush；延迟写入时最终存储为较新值。
- [ ] 写失败存储异常测试：read 抛错不阻止启动；write 抛错设置 saveFailed 且内存参数仍更新；下次保存成功清除错误；dispose 后定时器不继续通知。
- [ ] 运行 `flutter test test/features/player/settings_controller_test.dart` 确认失败，实现控制器。应用层监听控制器，把 settings、update 回调和 flush 回调传入 Task 3 的 PlayerPage；保存失败在应用层显示“设置未能保存”，不停止动画。加载结束前显示短暂加载状态，避免默认设置覆盖旧数据。
- [ ] 全部存储测试及 Task 3 界面测试通过，实际关闭再打开应用验证最后参数恢复，提交。

## Task 5: 离线构建、真机验证与交付

**Files:** 更新 `tools/Build-Android.ps1`、`README.md`、`docs/development-setup.md`、`docs/validation.md`；构建产物保留在忽略目录。

**Interfaces:** 消费完整应用；产生源码、debug APK 的本机路径／SHA-256 和实际验证记录，无发布、推送或自动安装要求。

- [ ] 执行 `dart format --output=none --set-exit-if-changed lib test`、`flutter analyze --no-pub`、`flutter test --no-pub`，全部输出通过。
- [ ] 从项目 `android/` 调用已安装 Gradle，以用户给定环境执行 `--offline --no-daemon --console plain '-Pkotlin.compiler.execution.strategy=in-process' lintDebug testDebugUnitTest assembleDebug`；明确记录 testDebugUnitTest 是否有测试，不用 NO-SOURCE 冒充测试通过。
- [ ] 若日志报告 Maven 或 SDK 缺项，只补实际缺少的组件，保留共享缓存，重新运行同一离线命令。不要通过跳过校验或降低版本来消除失败。
- [ ] 用已安装 ADB 只读查看连接状态；无真机时记录限制，有可用测试设备并获安装授权后验证：两种动画、旋转、调参、后台恢复、暂停常亮、全屏系统栏／返回手势，重点在 API 36 行为。未获得安装授权时先交付 APK 供用户安装。
- [ ] 如有性能测试设备，使用 profile / release 模式测试帧耗时并保存证据；没有设备时不宣称达到稳定 60fps。验证已安装 APK 的离线运行与设置恢复。
- [ ] 计算 APK SHA-256，确认 Git 中无 SDK、缓存、local.properties、签名或 APK。README 写明本机运行入口、固定版本和三平台适配现状。
- [ ] 完成一次独立代码审查并处理有效问题；按用户选定的执行方式使用对应技能，不自动创建其他聊天。最终报告实际检查结果、APK 路径、未验证项及后续平台工作。

## Execution Handoff

建议在当前对话由主代理依次实施以上五项，末尾做一次独立代码审查。它们共享参数、时钟与界面接口，范围小，逐项委派的上下文和交接成本高于收益。另一种可选方式是逐项子代理实施和审查。用户审阅本计划并选择执行方式后开始应用实现。
