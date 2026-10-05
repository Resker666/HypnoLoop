# 0.1.4 大按钮与简洁设置验证记录

验证日期：2026-10-05（Asia/Shanghai）。用户选择「大按钮优先＋简洁列表」，确认作者为 Resker666；沿用此前对连接的小米手机安装和测试的授权。

## 实现

- 竖屏主页的播放／暂停按钮最小高度为 76 逻辑像素，带图标和文字；独立保留进入全屏与调整按钮。速度与爱心扩散间隔显示为可点击摘要，主页不放滑杆。
- 调整面板分为参数与配色。参数页提供速度，爱心模式提供扩散间隔；实时更新和保存继续使用原有设置控制器。配色页只显示配色控制。
- 齿轮打开完整的简洁设置页：桌面图标、作者 Resker666、项目地址 github.com/Resker666/HypnoLoop、实际安装版本。版本从 Android 包信息查询，避免硬编码后过期。
- 项目地址通过系统外部链接处理程序打开。没有可用处理程序或平台通道时，复制完整 HTTPS 地址并显示反馈。
- 矮横屏或大字体横屏将模式与播放按钮并排，播放按钮最小高度 56；保留独立全屏与调整入口。
- 四款图标、绘制、时钟、保存格式、全屏返回和后台播放状态继续沿用。没有新增依赖或下载工具。

主要实现：`lib/features/player/preview_controls.dart`、`adjustment_panel.dart`、`player_page.dart`；新增 `lib/features/app_settings/app_settings_page.dart`、`lib/platform/project_info.dart`；Android `MainActivity.kt` 增加项目链接与安装版本通道。

## 自动检查与审查

| 检查 | 结果 |
| --- | --- |
| Flutter analyze | No issues found |
| Flutter 全部测试 | 39 项全部通过 |
| Android lintDebug | 0 错误，5 警告：4 个已有 IconLauncherShape、1 个 Uri.parse 的 UseKtx 建议 |
| Android testDebugUnitTest | NO-SOURCE，无原生测试源文件 |
| Android assembleDebug | 离线 BUILD SUCCESSFUL，59 秒 |
| APK 签名 | apksigner verify 通过，v2 debug 签名 |
| 独立只读代码审查 | 通过，无需要修复的功能问题 |

测试在真实 App 和设置控制器上验证参数更新与持久化、主按钮暂停／恢复和全屏状态、图标操作与失败重试。平台调用仅在测试边界替换；新设置测试覆盖项目打开成功、失败复制地址、两倍字号与返回首页。沿用小屏、横屏、两倍字号和安全区域布局检查。

先运行修改后的测试，确认旧首页没有所需主按钮、设置入口和新的参数位置；实现后再次检查。发现 640×320、两倍字号及上下各 24 像素安全区域时控制栏超高 21 像素，改为横屏模式与播放并排后通过全部相关场景，包括 480×320 两倍字号。

日志在忽略目录 `.tools/`：`baseline-playback-settings.log`（原 36 项通过）、`red-playback-settings.log`、`landscape-layout.log`、`tests-playback-settings.log`（最终 39 项通过）、`build-playback-settings.log`。沙箱首次无法加载共享 Gradle 原生库，确认库已存在后调整构建访问权限重试成功；未将访问问题当成组件缺失。

## 真机

Xiaomi 23127PN0CC，Android 16 / API 36，ADB 设备 e2f1a08，1200×2670。

通过 `tools/Run-Android.ps1 -DeviceId e2f1a08 -SkipBuild` 覆盖安装，安装返回 Success，启动 Status: ok。检查了：

- 大主按钮和独立全屏、调整入口均在竖屏主页可见；主按钮实际高度 228 物理像素，对应 76 逻辑像素。
- 简洁设置显示作者、完整仓库路径和实际版本 0.1.4；点击项目地址成功向系统浏览器发送相应 HTTPS 链接。
- 桌面图标面板保留 A／B／C／D，系统原来的 C 仍为当前选中；未切换用户图标。
- 参数页同时显示速度与爱心扩散间隔，配色页只显示颜色；未改动用户参数。
- 暂停后进入全屏仍保持暂停，控制栏显示继续、设置与退出；系统返回能回到主页。
- 覆盖安装和操作检查后，读取 DataStore 中保存的 12 个字段，与安装前快照逐项比较全部一致。
- 手机安装的 base.apk SHA-256 与本地已核验产物一致。

截图在 `.tools/previews/playback-settings-home.png`、`playback-settings-settings.png`、`playback-settings-parameters.png`、`playback-settings-color.png`。参数快照位于 `.tools/validation/playback-settings-before.json` 和 `playback-settings-after.json`。手机结束时停留主页并暂停，方便用户自行查看。

## 产物

- 版本：0.1.4 / versionCode 5。
- 包名：com.hypnoloop.app。
- APK：`build/app/outputs/flutter-apk/app-debug.apk`。
- 大小：155,910,128 字节，约 149 MiB。
- SHA-256：`2CDE394D5999BE3B72AB3BB568C3517A706F3A797AFEF5A894D22E9B713A5477`。

本轮在 `codex/playback-settings` 分支实施，基于已经合并沉浸面板的 main 提交 548f7c6。2026-10-05 用户确认「验证通过」并授权推送该分支。iOS 与桌面仍属于后续阶段。
