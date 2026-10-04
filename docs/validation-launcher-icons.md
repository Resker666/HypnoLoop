# 0.1.2 桌面图标切换验证

日期：2026-10-04。用户确认四款内置图标选择、当前标记与恢复默认；Android 优先，iOS 备用图标留到后续适配。

## 实现与素材

- 设置底部提供 A 粉白爱心环、B 渐变爱心旋涡、C 黑白螺旋爱心、D 紫粉双环爱心。默认和「恢复默认」均为 B。
- Android 通过四个稳定的 `activity-alias` 切换入口，MainActivity 始终启用。选择从 PackageManager 的实际状态读取，不另存到动画设置 JSON。切换期间禁用重复操作，失败后重新读取实际入口。
- API 33 及以上批量修改入口；API 24–32 先启用目标，再关闭其他入口，失败时尝试恢复之前的选择。API 26 及以上使用自适应图标，24／25 使用位图回退。
- `assets/launcher_icons/a.png` 至 `d.png` 是通过内置 `image_gen.imagegen` 生成的 1254×1254 不透明原图，复制到项目后未修改。完整提示词见 [launcher-icon-prompts.json](assets/launcher-icon-prompts.json)。Flutter 直接预览原图；Gradle 的 Sync 任务从同一来源生成 Android 资源，输出位于忽略的 build 目录。

## 自动检查与代码审查

`tools/Verify.ps1` 使用已有工具和缓存离线完成：24 个 Dart 文件格式检查、Dart 分析无问题、32 项 Flutter 测试全部通过。新增四项实际 App 界面测试覆盖读取原生当前图标、切换与恢复默认、重新打开读取、操作期间禁用、失败后回读、未知状态与无障碍点击动作；只模拟外部平台通道。

新增测试先验证缺少图标选择功能时失败，再验证实现通过。无障碍动作测试也曾捕获只有标签而没有点击动作的问题，修复后全套通过。初次全套测试的 SemanticsHandle 清理问题已修正，最终结果为 32／32。

最终 Android 资源调整后重新离线执行 Lint、单元测试任务和 APK 构建：`BUILD SUCCESSFUL in 31s`，112 个任务，其中 34 个执行、78 个复用结果。Android 单元测试任务为 `NO-SOURCE`，没有将其计作原生测试。Lint 为 **0 errors、4 warnings**；四项 `IconLauncherShape` 提示来自不透明的旧版位图回退资源。API 36 真机上的自适应裁切已查看，未隐藏这些告警。

代码审查发现 Flutter 3.41.5 的常规 APK 启动流程可能选择默认 B 入口，而切换后该入口会被禁用。已加入 `tools/Run-Android.ps1`，通过始终启用的 MainActivity 安装启动，再按需 `flutter attach`。C 图标启用时，覆盖安装、冷启动与实际 Flutter 调试连接均通过，随后正常 detach。PowerShell 脚本语法检查通过。

## 真机验证

设备为 Xiaomi 23127PN0CC，Android 16／API 36，ADB 序列号 `e2f1a08`。用户已授权安装和测试。

1. 四款图标逐一选择，PackageManager 每次均只返回一个启用的桌面入口。
2. 返回小米桌面，逐一查看 A／B／C／D 图标，并通过对应桌面图标点击打开 HypnoLoop，全部成功。
3. C 图标下强制停止后冷启动，系统选择和应用内当前标记均保留。
4. C 图标下覆盖安装相同版本 APK，仍保留 C；通过调试脚本启动并连接 Flutter VM 成功。
5. 点击「恢复默认」后系统与界面均为 B，再选择 C，系统与界面均恢复 C。最终手机保留 C 图标。
6. 安装后应用进程日志未匹配到 `FATAL EXCEPTION`、`Unhandled Exception`、`E/flutter` 或 `RenderFlex overflow`。这只是本次进程日志检查，不代表所有设备或所有故障路径均已验证。

没有重置用户的动画参数。屏幕截图、UI 树和构建日志保存在忽略的 `.tools/previews` 与 `.tools/validation`，未提交手机桌面内容。

## APK 与验证边界

最终产物：`build/app/outputs/flutter-apk/app-debug.apk`，包名 `com.hypnoloop.app`，版本 **0.1.2+3**，170,484,768 字节（约 163 MiB）。最低 API 24，目标 API 36，包含 arm64-v8a、armeabi-v7a、x86_64。`apksigner` 验证 debug 签名通过。

SHA-256：`B28B316D1B043ABFB9CB990B51F0FCD3F20E56B80FE6D9D17ADF736057542CB7`。已安装的 base.apk 与本地产物哈希相同。

本次未下载新组件或增加插件依赖。工具、依赖缓存、生成资源与 APK 保持在 Git 之外。

API 24–32 顺序切换分支、原生异常回滚、其他厂商桌面和手机系统重启没有实机验证；没有运行 iOS 或桌面构建。当前功能只提供四款内置桌面图标选择，不包括从相册导入任意图片。
