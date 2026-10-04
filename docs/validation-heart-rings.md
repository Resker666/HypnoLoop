# A 版爱心验证记录（0.1.1）

2026-10-04，用户查看 A/B/C/D 循环 GIF 后选择 A。本次沿用 Flutter 与现有 Android 工具版本，仅更新绘制、粉白预设、旧预设颜色兼容和应用版本；没有下载新的组件。

## 实现与画面比对

中央心形保持固定；沿心形曲线的外法线生成等距轮廓，逐圈填充粉色与背景色形成环带。曲线位置和法线在尺寸变化时重算并缓存，底部圆角连接，顶部凹口裁去偏移曲线交叉产生的内环。按屏幕短边计算心形、间距及线宽，中央位置为宽度 50%、高度 45.5%，与获选预览一致。每帧只由时钟驱动绘制。

粉白预设采用白色背景、`#F400DA` 移动环及中央描边，周期 1.5 个动画秒；默认 0.5 倍速度下每三秒循环。RGB 的背景控制画布与中央填充，主色控制移动环，爱心色控制固定描边。旧粉紫预设的精确颜色组合会在加载时升级，其他参数与自定义颜色保留。

获选 A 版的独立参考帧保存在 `test/fixtures/heart-a.png`（320×640，周期相位 0.24），来源是用户查看的 GIF 预览。最终 Flutter 渲染同一相位后，平均 RGB 绝对差异为 1.213/255，像素平均差异超过 64 的占比为 0.0078%。比较允许抗锯齿差异，没有用待测绘制器生成参考值。轮廓采用固定数量的曲线采样点，这些结果不代表所有画布尺寸都具有相同误差。

## 自动验证

四个新增测试先观察失败，再实现并通过：

- `heart preset selects the approved pink rings on white`
- `legacy heart preset upgrades without replacing custom colors`
- `heart rings reproduce approved A contours and spacing`
- `heart ring loop repeats with a stable white center`

旧实心层删除后，首次完整测试暴露了旧几何测试对已移除 API 的引用；更新为新轮廓环的边界验证。旧四秒层消失测试由实际像素的周期重复测试替代。

最终 `tools/Verify.ps1` 通过：21 个 Dart 文件格式无变化，analysis 无问题，Flutter 测试 28/28；应用离线构建 `BUILD SUCCESSFUL in 17s`，111 tasks（16 executed / 95 up-to-date），Lint XML 无 issue。`:app:testDebugUnitTest` 为 NO-SOURCE，未计入测试数量。

独立代码复核未发现 Critical 或 Important 问题。初次复核提出循环边界附近的覆盖不足，已补充 1.499 秒与 1.501 秒实际像素差异小于 1/255 的测试并通过。填充轮廓替换描边后的复核检查了曲线连接、凹口闭合、有限坐标与不同宽高比的外圈覆盖；没有发现新的重大问题。

## 真机性能

最初的超宽描边实现虽然通过画面比对，但在手机的 Impeller / Vulkan 渲染器上明显卡顿。改为填充轮廓后重新运行同一 profile 场景：粉白预设、0.5 倍速度、1.5 动画秒周期、竖屏全屏、120 Hz。先预热四秒，再记录约八秒的 Dart / Embedder timeline。

| 实现 | 记录时长 | Raster 帧数 | 每秒绘制帧数 | Raster 中位 / P95 / 最大耗时 |
| --- | --- | --- | --- | --- |
| 超宽描边 | 8.084481 秒 | 33 | 4.08 | 234.128 / 241.267 / 243.571 ms |
| 填充轮廓 | 8.023759 秒 | 943 | 117.53 | 2.904 / 6.063 / 7.884 ms |

填充轮廓的 UI 帧耗时中位 / P95 / 最大值为 2.858 / 5.959 / 8.434 ms。性能断言要求每秒至少 50 个绘制帧、Raster P95 小于 16.667 ms；旧实现失败，新实现通过。该采样证明本机短时场景的卡顿已修复，不覆盖长时间温升或其他设备，也不能推断每帧都满足 120 Hz 预算。

原始采样分别保存在忽略目录 `.tools/previews/device-hearts-a-profile-timeline.json` 和 `.tools/previews/device-hearts-a-filled-profile-timeline.json`。

## 产物与真机

APK：`build/app/outputs/flutter-apk/app-debug.apk`，161561479 字节（约 154 MiB）。SHA-256：`2E31958F112E35827C1AEA695DAD824BE02B0BE4830E64FC2CEFA92C3AECBF32`。`apksigner verify` 验证 v2 签名通过，使用本机标准 Android Debug 证书。

包名 `com.hypnoloop.app`，versionName 0.1.1、versionCode 2，minSdk 24、targetSdk 36。构建脚本从 pubspec 读取版本，避免直接使用已有 Gradle 时残留旧版本号。

已授权的 Xiaomi 23127PN0CC（Android 16 / API 36）安装返回 Success。首次安装时手机锁屏，应用焦点保护阻止了 UI 输入；用户解锁后完成测试。已有的自定义紫黑配色被保留，随后选择粉白预设进行 A 版验证。

实际检查了竖屏与横屏全屏画面、播放时常亮及暂停后释放常亮、退出全屏、设置恢复。横屏测试后将用户原有的旋转设置恢复。最终换回上面列出的调试 APK，手机上安装文件的 SHA-256 与本地产物一致；启动后恢复 0.5 倍速度与 1.5 秒周期。应用自身日志没有发现 Exception、FATAL、Error 或 overflow。手机最终停在粉白爱心的暂停预览页，截图为 `.tools/previews/device-hearts-a-final-debug-preview.png`。

构建与 RED/GREEN 日志位于忽略目录 `.tools/validation/heart-rings-*.log`；Flutter 固定帧位于 `.tools/previews/heart-rings-*.png`。SDK、缓存和 APK 仍在 Git 之外。
