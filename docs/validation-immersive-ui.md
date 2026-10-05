# 0.1.3 沉浸面板验证记录

验证日期：2026-10-05（Asia/Shanghai）。用户选定方案 2「沉浸面板」，并授权安装到测试手机。

## 交互与实现

- 首页为深色界面、大幅预览和浮动控制面板，仅保留模式、速度、暂停／继续、开始全屏与调整入口，不再放置长参数列表。
- 「调整」按形状、配色分组；保留即时更新、参数保存、预设与 RGB 调色。全屏中的调整面板仍提供播放速度。
- 右上角齿轮打开外观设置，沿用四款桌面图标、当前选中状态和恢复默认。
- 横屏将控制面板放到预览右侧；可用高度较少或字号较大时，模式与速度并排，面板宽度受实际可用宽度约束。
- 保持原有动画、设置格式、全屏返回顺序、控制栏自动隐藏和后台暂停逻辑。没有新增依赖。

主要文件为 `lib/app.dart`、`lib/features/player/player_page.dart`、`mode_selector.dart`、`preview_controls.dart`、`adjustment_panel.dart`、`settings_panel.dart`。

## 自动检查

在项目根目录执行 `tools/Verify.ps1`，复用现有 Flutter、JDK、SDK、Gradle 与缓存，全程离线。最终日志位于忽略目录 `.tools/validation/immersive-ui-verification.log`。

| 检查 | 结果 |
| --- | --- |
| Dart 格式 | 28 个文件，0 个待格式化 |
| Flutter analyze | No issues found |
| Flutter 测试 | 36 项全部通过 |
| Android lintDebug | 0 错误，4 个已有 IconLauncherShape 警告 |
| Android testDebugUnitTest | NO-SOURCE，没有原生单元测试源文件 |
| Android assembleDebug | BUILD SUCCESSFUL |

新增界面测试使用实际 App、实际本地设置控制器和内存存储，仅替换外部显示服务。覆盖：

- 首页在 320×640、390×844、844×390 中无滚动，主要按钮和速度可操作。
- 形状／配色切换、当前模式的参数修改和保存；旧全屏设置即时更新回归测试保留。
- 390×844、两倍字号时首页操作和形状设置可到达。
- 含顶部／底部各 24 像素安全区域的横屏：640×320 下 1、1.4、2 倍字号，640×360 下 1.4 倍，480×320 下 2 倍。操作按钮、滑杆及模式文字均在可见范围内。
- 图标切换、恢复默认、重开读取、失败重试和无障碍操作，沿用已有测试并更新入口。

先运行了旧界面的失败测试，再实现新入口。独立代码审查发现矮横屏控制栏可能溢出；补测复现了 640×320 下普通字号 24 像素、两倍字号 99 像素的纵向溢出，最终通过并排布局和宽高约束修正。相关失败与通过日志保留在 `.tools/validation/immersive-ui-*-red.log` 和 `immersive-ui-landscape-green.log`；最终完整验收日志为上述 `immersive-ui-verification.log`。

## 真机与数据

设备：Xiaomi 23127PN0CC，Android 16 / API 36，ADB 设备 `e2f1a08`，屏幕 1200×2670。

通过 `tools/Run-Android.ps1 -DeviceId e2f1a08 -SkipBuild` 覆盖安装并启动，最终安装返回 Success / Status: ok。实际验证了：

- 竖屏首页所有常用控制可见，形状、配色、RGB 调色和四款图标的入口可操作。
- 模式切换后的形状面板随之更新；全屏画面无系统栏，轻点后打开设置，全屏速度可见，关闭面板后返回首页。
- 横屏控制面板位于右侧，恢复竖屏后仍可操作。临时旋转设置已恢复为原来的 `lock 0`。
- 安装前保存的全部视觉参数与最终覆盖安装后保存值完全一致；验证中未改动用户配色、速度和形状。测试期间切换模式后已恢复原模式。
- 原先实际启用的 C 图标继续启用，外观面板读到 C 的当前标记。

本地截图位于忽略目录 `.tools/previews/immersive-ui-home.png`、`immersive-ui-landscape.png`、`immersive-ui-shape.png`、`immersive-ui-color.png`、`immersive-ui-rgb.png`、`immersive-ui-icons.png`、`immersive-ui-fullscreen.png`、`immersive-ui-fullscreen-settings.png`。测试结束时手机停留在首页，动画暂停，点击继续即可播放。

参数核对证据为 `.tools/validation/immersive-ui-settings-preserved.txt`；产物核对证据为 `immersive-ui-artifact.txt`。

## 最终 APK

| 项目 | 值 |
| --- | --- |
| 版本 | 0.1.3 / versionCode 4 |
| 包名 | com.hypnoloop.app |
| 文件 | build/app/outputs/flutter-apk/app-debug.apk |
| 大小 | 170,505,237 字节，约 163 MiB |
| SHA-256 | CCF0A277A7D7412B19FF7E4301866BE8ACFE8CE4D201014451B6D5C4744443DF |
| 签名 | 本机 debug 签名，apksigner verify 通过，v2 |

手机已安装的 base.apk SHA-256 与上表完全一致。APK、截图、工具与缓存保持在 Git 忽略目录中。

本次为 Android 界面改版；iOS、电脑平台和正式发布签名仍按后续阶段处理。此记录为开发验收，用户对新版外观的最终确认另行记录。
